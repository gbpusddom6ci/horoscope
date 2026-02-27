import SwiftUI
import Observation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import os

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

    private let firestoreService = FirestoreService.shared
    private let legacyMigrationService = LegacyDataMigrationService.shared
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private var fcmTokenObserver: NSObjectProtocol?
    private let logger = Logger(subsystem: "rk.horoscope", category: "AuthService")
    private let sessionStorageKey = "currentUserSession"
    private let pendingFCMTokenKey = "pending_fcm_token"
    private let isUITestAuthenticated = ProcessInfo.processInfo.arguments.contains("UITEST_AUTHENTICATED")

    init() {
        if isUITestAuthenticated {
            configureUITestSession()
            return
        }

        // Only check local session initially to show UI quickly
        checkLocalAuthState()
        
        // Listen to real Firebase Auth state changes
        setupFirebaseAuthListener()
        setupFCMTokenListener()
    }

    deinit {
        if let authListenerHandle {
            Auth.auth().removeStateDidChangeListener(authListenerHandle)
        }
        if let fcmTokenObserver {
            NotificationCenter.default.removeObserver(fcmTokenObserver)
        }
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
            let doc = try? await firestoreService.fetchUserDocument(userId: fbUser.uid)

            var displayName: String
            var hasCompletedOnboarding = false
            var birthData: BirthData? = nil
            var isPremium = false
            var createdAt = Date()

            if let data = doc?.data(), doc?.exists == true {
                // Existing user — read stored data
                displayName = data["displayName"] as? String
                    ?? (appleDisplayName.isEmpty ? String(localized: "common.user") : appleDisplayName)
                hasCompletedOnboarding = data["hasCompletedOnboarding"] as? Bool ?? false
                isPremium = data["isPremium"] as? Bool ?? false
                createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                birthData = extractBirthData(from: data)
            } else {
                // New user — create Firestore document
                displayName = appleDisplayName.isEmpty ? String(localized: "common.user") : appleDisplayName
                let userData: [String: Any] = [
                    "id": fbUser.uid,
                    "email": fbUser.email ?? appleCredential.email ?? "",
                    "displayName": displayName,
                    "isPremium": false,
                    "hasCompletedOnboarding": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                try await firestoreService.setUserDocument(userId: fbUser.uid, data: userData, merge: true)
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
                self.applyPendingFCMTokenIfNeeded()
                Task { await self.runLegacyMigrationIfNeeded(for: appUser.id) }
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
            errorMessage = String(localized: "auth.error.email_password_required")
            isLoading = false
            return
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let fbUser = result.user
            
            // Check if user document exists in Firestore to get user metadata
            let doc = try? await firestoreService.fetchUserDocument(userId: fbUser.uid)
            let data = doc?.data()

            let displayName = data?["displayName"] as? String ?? email.components(separatedBy: "@").first ?? String(localized: "common.user")
            let birthData = extractBirthData(from: data)
            let hasCompletedOnboarding = (data?["hasCompletedOnboarding"] as? Bool) ?? (birthData != nil)
            
            let appUser = AppUser(
                id: fbUser.uid,
                displayName: displayName,
                email: email,
                birthData: birthData,
                isPremium: data?["isPremium"] as? Bool ?? false,
                createdAt: (data?["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )

            await MainActor.run {
                self.currentUser = appUser
                self.authState = hasCompletedOnboarding ? .authenticated : .onboarding
                self.saveSession(appUser)
                self.applyPendingFCMTokenIfNeeded()
                Task { await self.runLegacyMigrationIfNeeded(for: appUser.id) }
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
            errorMessage = String(localized: "auth.error.fill_all_fields")
            isLoading = false
            return
        }

        guard password.count >= 6 else {
            errorMessage = String(localized: "auth.error.password_min")
            isLoading = false
            return
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let fbUser = result.user
            let finalName = displayName.isEmpty ? String(localized: "common.user") : displayName
            
            // Create user document in Firestore
            let userData: [String: Any] = [
                "id": fbUser.uid,
                "email": email,
                "displayName": finalName,
                "isPremium": false,
                "hasCompletedOnboarding": false,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await firestoreService.setUserDocument(userId: fbUser.uid, data: userData, merge: false)
            
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
                self.applyPendingFCMTokenIfNeeded()
                Task { await self.runLegacyMigrationIfNeeded(for: appUser.id) }
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
        do {
            try Auth.auth().signOut()
            currentUser = nil
            authState = .unauthenticated
            clearSession()
        } catch {
            self.errorMessage = String(localized: "auth.error.signout_failed")
        }
    }

    @MainActor
    func completeOnboarding(with birthData: BirthData) async throws {
        guard var user = currentUser else {
            throw AuthServiceError.notAuthenticated
        }

        let previousUser = user
        user.birthData = birthData
        currentUser = user
        authState = .authenticated
        saveSession(user)

        do {
            try await syncBirthDataToFirestore(userId: user.id, birthData: birthData, setOnboarding: true)
            errorMessage = nil
        } catch {
            // Revert local state if backend sync fails.
            currentUser = previousUser
            authState = previousUser.hasCompletedOnboarding ? .authenticated : .onboarding
            saveSession(previousUser)
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Updates birth data after initial onboarding (e.g., from profile edit).
    func updateBirthData(_ birthData: BirthData) async throws {
        currentUser?.birthData = birthData
        guard let user = currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        saveSession(user)
        try await syncBirthDataToFirestore(userId: user.id, birthData: birthData, setOnboarding: false)
    }

    /// Syncs premium state from StoreKit purchases to local session + Firestore.
    func updatePremiumStatus(_ isPremium: Bool) {
        currentUser?.isPremium = isPremium
        guard let user = currentUser else { return }

        saveSession(user)
        Task {
            do {
                try await firestoreService.updateUserDocument(
                    userId: user.id,
                    data: ["isPremium": isPremium]
                )
            } catch {
                logger.error("Failed to update premium state in Firestore: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func setupFCMTokenListener() {
        fcmTokenObserver = NotificationCenter.default.addObserver(
            forName: .didReceiveFCMToken,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let token = notification.object as? String else { return }
            self?.handleIncomingFCMToken(token)
        }
    }

    private func handleIncomingFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: pendingFCMTokenKey)
        applyPendingFCMTokenIfNeeded()
    }

    private func applyPendingFCMTokenIfNeeded() {
        guard let token = UserDefaults.standard.string(forKey: pendingFCMTokenKey),
              !token.isEmpty else { return }

        guard var user = currentUser else { return }
        if user.fcmToken == token {
            return
        }

        user.fcmToken = token
        currentUser = user
        saveSession(user)

        Task {
            do {
                try await firestoreService.updateUserDocument(
                    userId: user.id,
                    data: ["fcmToken": token]
                )
            } catch {
                logger.error("Failed to sync fcmToken to Firestore: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func syncBirthDataToFirestore(userId: String, birthData: BirthData, setOnboarding: Bool) async throws {
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
        try await firestoreService.updateUserDocument(userId: userId, data: updateData)
    }

    // MARK: - Session Persistence (Keychain)

    private func setupFirebaseAuthListener() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            if let firebaseUser = user {
                Task {
                    await self.restoreSessionFromFirebaseIfNeeded(firebaseUser)
                }
            } else {
                // User is signed out from Firebase
                self.currentUser = nil
                self.authState = .unauthenticated
                self.clearSession()
            }
        }
    }

    private func restoreSessionFromFirebaseIfNeeded(_ firebaseUser: User) async {
        if let current = currentUser, current.id == firebaseUser.uid {
            return
        }

        let doc = try? await firestoreService.fetchUserDocument(userId: firebaseUser.uid)
        let data = doc?.data()
        let birthData = extractBirthData(from: data)
        let hasCompletedOnboarding = (data?["hasCompletedOnboarding"] as? Bool) ?? (birthData != nil)

        let fallbackName = firebaseUser.displayName
            ?? firebaseUser.email?.components(separatedBy: "@").first
            ?? String(localized: "common.user")

        let appUser = AppUser(
            id: firebaseUser.uid,
            displayName: data?["displayName"] as? String ?? fallbackName,
            email: firebaseUser.email,
            birthData: birthData,
            isPremium: data?["isPremium"] as? Bool ?? false,
            createdAt: (data?["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            fcmToken: data?["fcmToken"] as? String
        )

        await MainActor.run {
            self.currentUser = appUser
            self.authState = hasCompletedOnboarding ? .authenticated : .onboarding
            self.saveSession(appUser)
            self.applyPendingFCMTokenIfNeeded()
        }

        await runLegacyMigrationIfNeeded(for: appUser.id)
    }

    private func extractBirthData(from data: [String: Any]?) -> BirthData? {
        guard let bdMap = data?["birthData"] as? [String: Any],
              let date = (bdMap["date"] as? Timestamp)?.dateValue(),
              let city = bdMap["city"] as? String,
              let lat = bdMap["latitude"] as? Double,
              let lon = bdMap["longitude"] as? Double,
              let tz = bdMap["timeZone"] as? String else {
            return nil
        }

        let time = (bdMap["time"] as? Timestamp)?.dateValue()
        return BirthData(
            birthDate: date,
            birthTime: time,
            birthPlace: city,
            latitude: lat,
            longitude: lon,
            timeZoneIdentifier: tz
        )
    }

    private func checkLocalAuthState() {
        if let data = KeychainService.get(for: sessionStorageKey),
           let user = try? JSONDecoder().decode(AppUser.self, from: data) {
            currentUser = user
            authState = user.hasCompletedOnboarding ? .authenticated : .onboarding
        } else if let legacyUser = legacyMigrationService.loadLegacySessionFromUserDefaults() {
            currentUser = legacyUser
            authState = legacyUser.hasCompletedOnboarding ? .authenticated : .onboarding
        } else {
            authState = .unauthenticated
        }
    }

    private func configureUITestSession() {
        let calendar = Calendar(identifier: .gregorian)
        let birthDate = calendar.date(from: DateComponents(year: 1993, month: 9, day: 14)) ?? Date()
        let birthTime = calendar.date(from: DateComponents(year: 1993, month: 9, day: 14, hour: 8, minute: 30))

        let birthData = BirthData(
            birthDate: birthDate,
            birthTime: birthTime,
            birthPlace: "Istanbul, Turkey",
            latitude: 41.0082,
            longitude: 28.9784,
            timeZoneIdentifier: "Europe/Istanbul"
        )

        let user = AppUser(
            id: "ui-test-user",
            displayName: "UI Tester",
            email: "ui@test.local",
            birthData: birthData,
            isPremium: true,
            createdAt: Date()
        )

        currentUser = user
        authState = .authenticated
        saveSession(user)
    }

    private func saveSession(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            if !KeychainService.set(data, for: sessionStorageKey) {
                logger.error("Failed to persist session to keychain")
            }
        }
    }

    private func clearSession() {
        KeychainService.remove(for: sessionStorageKey)
    }

    private func runLegacyMigrationIfNeeded(for userId: String) async {
        await legacyMigrationService.migrateUserDataIfNeeded(for: userId)
    }
}

enum AuthServiceError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return String(localized: "auth.error.session_missing")
        }
    }
}
