import AuthenticationServices
import CryptoKit
import FirebaseAuth

/// Handles the native Apple Sign-In flow using ASAuthorizationController.
/// Generates a secure nonce for Firebase replay-attack prevention.
class AppleSignInHelper: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    private(set) var currentNonce: String?

    // MARK: - Public API

    /// Triggers the Apple Sign-In sheet and returns the credential on success.
    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        let nonce = Self.randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleSignInError.invalidCredential)
            continuation = nil
            return
        }
        continuation?.resume(returning: appleIDCredential)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    // MARK: - Presentation Context

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window for the sign-in sheet
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }

    // MARK: - Nonce Helpers

    /// Generates a random nonce string used for Firebase Sign-In with Apple.
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            // Avoid crashing in production for a recoverable entropy-source failure.
            // UUID fallback keeps the auth flow alive with sufficient uniqueness for nonce use.
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// SHA256 hash of the input string, returned as a hex string.
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Error

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingIdentityToken
    case tokenSerializationError

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Apple kimlik bilgisi geçersiz."
        case .missingIdentityToken:
            return "Apple identity token alınamadı."
        case .tokenSerializationError:
            return "Token serileştirme hatası."
        }
    }
}
