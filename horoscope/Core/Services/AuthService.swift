import SwiftUI
import Observation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

// MARK: - Auth State
enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case authenticated
    case onboarding  // authenticated but no birth data
}

// MARK: - Auth Service
/// Firebase Auth wrapper handling user authentication and session state.
@Observable
class AuthService {
    var currentUser: AppUser?
    var authState: AuthState = .unknown
    var errorMessage: String?
    var isLoading: Bool = false

    init() {
        // Only check local session initially to show UI quickly
        checkLocalAuthState()
        
        // Listen to real Firebase Auth state changes
        setupFirebaseAuthListener()
    }

    // MARK: - Auth Methods

    private let appleSignInHelper = AppleSignInHelper()

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Trigger native Apple Sign-In sheet
            let appleCredential = try await appleSignInHelper.signIn()

            // 2. Extract identity token
            guard let identityToken = appleCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                throw AppleSignInError.missingIdentityToken
            }

            // 3. Get the raw nonce used for this request
            guard let nonce = appleSignInHelper.currentNonce else {
                throw AppleSignInError.tokenSerializationError
            }

            // 4. Create Firebase OAuthProvider credential
            let credential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: tokenString,
                rawNonce: nonce
            )

            // 5. Sign in to Firebase
            let result = try await Auth.auth().signIn(with: credential)
            let fbUser = result.user

            // 6. Extract display name from Apple credential (only provided on FIRST sign-in)
            let fullName = appleCredential.fullName
            let givenName = fullName?.givenName ?? ""
            let familyName = fullName?.familyName ?? ""
            let appleDisplayName = [givenName, familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            // 7. Check if user document exists in Firestore
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(fbUser.uid)
            let doc = try? await docRef.getDocument()

            var displayName: String
            var hasCompletedOnboarding = false
            var birthData: BirthData? = nil
            var isPremium = false
            var createdAt = Date()

            if let data = doc?.data(), doc?.exists == true {
                // Existing user — read stored data
                displayName = data["displayName"] as? String ?? appleDisplayName
                hasCompletedOnboarding = data["hasCompletedOnboarding"] as? Bool ?? false
                isPremium = data["isPremium"] as? Bool ?? false
                createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                // Extract birthData if available
                if let bdMap = data["birthData"] as? [String: Any],
                   let date = (bdMap["date"] as? Timestamp)?.dateValue(),
                   let city = bdMap["city"] as? String,
                   let lat = bdMap["latitude"] as? Double,
                   let lon = bdMap["longitude"] as? Double,
                   let tz = bdMap["timeZone"] as? String {
                    let time = (bdMap["time"] as? Timestamp)?.dateValue()
                    birthData = BirthData(birthDate: date, birthTime: time, birthPlace: city, latitude: lat, longitude: lon, timeZoneIdentifier: tz)
                }
            } else {
                // New user — create Firestore document
                displayName = appleDisplayName.isEmpty ? "Kullanıcı" : appleDisplayName
                let userData: [String: Any] = [
                    "id": fbUser.uid,
                    "email": fbUser.email ?? appleCredential.email ?? "",
                    "displayName": displayName,
                    "isPremium": false,
                    "hasCompletedOnboarding": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                try await docRef.setData(userData)
            }

            let appUser = AppUser(
                id: fbUser.uid,
                displayName: displayName,
                email: fbUser.email ?? appleCredential.email ?? "",
                birthData: birthData,
                isPremium: isPremium,
                createdAt: createdAt
            )

            await MainActor.run {
                self.currentUser = appUser
                self.authState = hasCompletedOnboarding ? .authenticated : .onboarding
                self.saveSession(appUser)
                self.isLoading = false
            }
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User cancelled — don't show error
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email ve şifre gerekli"
            isLoading = false
            return
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let fbUser = result.user
            
            // Check if user document exists in Firestore to get displayName
            let db = Firestore.firestore()
            let doc = try? await db.collection("users").document(fbUser.uid).getDocument()
            
            let displayName = doc?.data()?["displayName"] as? String ?? email.components(separatedBy: "@").first ?? "Kullanıcı"
            let hasCompletedOnboarding = doc?.data()?["hasCompletedOnboarding"] as? Bool ?? false
            
            // Extract birthData if available
            var birthData: BirthData? = nil
            if let bdMap = doc?.data()?["birthData"] as? [String: Any],
               let date = (bdMap["date"] as? Timestamp)?.dateValue(),
               let city = bdMap["city"] as? String,
               let lat = bdMap["latitude"] as? Double,
               let lon = bdMap["longitude"] as? Double,
               let tz = bdMap["timeZone"] as? String {
                let time = (bdMap["time"] as? Timestamp)?.dateValue()
                birthData = BirthData(birthDate: date, birthTime: time, birthPlace: city, latitude: lat, longitude: lon, timeZoneIdentifier: tz)
            }
            
            let appUser = AppUser(
                id: fbUser.uid,
                displayName: displayName,
                email: email,
                birthData: birthData,
                isPremium: doc?.data()?["isPremium"] as? Bool ?? false,
                createdAt: (doc?.data()?["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )

            await MainActor.run {
                self.currentUser = appUser
                self.authState = hasCompletedOnboarding ? .authenticated : .onboarding
                self.saveSession(appUser)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Tüm alanları doldurun"
            isLoading = false
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı"
            isLoading = false
            return
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let fbUser = result.user
            let finalName = displayName.isEmpty ? "Kullanıcı" : displayName
            
            // Create user document in Firestore
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "id": fbUser.uid,
                "email": email,
                "displayName": finalName,
                "isPremium": false,
                "hasCompletedOnboarding": false,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(fbUser.uid).setData(userData)
            
            let appUser = AppUser(
                id: fbUser.uid,
                displayName: finalName,
                email: email,
                isPremium: false,
                createdAt: Date()
            )

            await MainActor.run {
                self.currentUser = appUser
                self.authState = .onboarding
                self.saveSession(appUser)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func signOut() {
        // Clean up local data for the current user
        if let userId = currentUser?.id {
            ChatService.shared.clearAllSessions(for: userId)
            DreamService.shared.clearAllEntries(for: userId)
        }

        do {
            try Auth.auth().signOut()
            currentUser = nil
            authState = .unauthenticated
            clearSession()
        } catch {
            self.errorMessage = "Çıkış yapılırken bir hata oluştu"
        }
    }

    func completeOnboarding(with birthData: BirthData) {
        // Update local state
        currentUser?.birthData = birthData
        authState = .authenticated
        if let user = currentUser {
            saveSession(user)
            syncBirthDataToFirestore(userId: user.id, birthData: birthData, setOnboarding: true)
        }
    }

    /// Updates birth data after initial onboarding (e.g., from profile edit).
    func updateBirthData(_ birthData: BirthData) {
        currentUser?.birthData = birthData
        if let user = currentUser {
            saveSession(user)
            syncBirthDataToFirestore(userId: user.id, birthData: birthData, setOnboarding: false)
        }
    }

    private func syncBirthDataToFirestore(userId: String, birthData: BirthData, setOnboarding: Bool) {
        let db = Firestore.firestore()
        var bdMap: [String: Any] = [
            "date": Timestamp(date: birthData.birthDate),
            "city": birthData.birthPlace,
            "latitude": birthData.latitude,
            "longitude": birthData.longitude,
            "timeZone": birthData.timeZoneIdentifier
        ]
        if let time = birthData.birthTime {
            bdMap["time"] = Timestamp(date: time)
        }

        var updateData: [String: Any] = ["birthData": bdMap]
        if setOnboarding {
            updateData["hasCompletedOnboarding"] = true
        }

        db.collection("users").document(userId).updateData(updateData) { error in
            if let error = error {
                print("Error updating birth data in Firestore: \(error)")
            }
        }
    }

    // MARK: - Session Persistence (UserDefaults — replace with Keychain for production)

    private func setupFirebaseAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            
            if user == nil {
                // User is signed out from Firebase
                self.currentUser = nil
                self.authState = .unauthenticated
                self.clearSession()
            }
        }
    }

    private func checkLocalAuthState() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(AppUser.self, from: data) {
            currentUser = user
            authState = user.hasCompletedOnboarding ? .authenticated : .onboarding
        } else {
            authState = .unauthenticated
        }
    }

    private func saveSession(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}
