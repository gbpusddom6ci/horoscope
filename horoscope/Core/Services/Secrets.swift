import Foundation

/// Defines keys and secrets for the application.
/// IMPORTANT: Never hardcode secrets in source code.
/// Secrets should be provided via Info.plist keys or environment variables.
enum Secrets {
    static var openRouterAPIKey: String {
        value(for: "OPENROUTER_API_KEY")
    }

    static var freeAstroAPIKey: String {
        value(for: "FREE_ASTRO_API_KEY")
    }

    static var aiProxyBaseURL: URL? {
        urlValue(for: "AI_PROXY_BASE_URL")
    }

    static var astroProxyBaseURL: URL? {
        urlValue(for: "ASTRO_PROXY_BASE_URL")
    }

    static var termsOfUseURL: URL? {
        urlValue(for: "TERMS_OF_USE_URL")
    }

    static var privacyPolicyURL: URL? {
        urlValue(for: "PRIVACY_POLICY_URL")
    }

    static var openRouterModel: String {
        let configured = value(for: "OPENROUTER_MODEL")
        if !configured.isEmpty {
            return configured
        }
        return "google/gemini-2.0-flash-001"
    }

    static var allowDirectProviderCalls: Bool {
        boolValue(for: "ALLOW_DIRECT_PROVIDER_CALLS", defaultValue: defaultAllowDirectProviderCalls)
    }

    private static var defaultAllowDirectProviderCalls: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static func value(for key: String) -> String {
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plistValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        if let envValue = ProcessInfo.processInfo.environment[key] {
            let trimmed = envValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return ""
    }

    private static func urlValue(for key: String) -> URL? {
        let raw = value(for: key)
        guard !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    private static func boolValue(for key: String, defaultValue: Bool) -> Bool {
        if let plistBool = Bundle.main.object(forInfoDictionaryKey: key) as? Bool {
            return plistBool
        }

        let raw = value(for: key).lowercased()
        if ["1", "true", "yes", "y"].contains(raw) {
            return true
        }
        if ["0", "false", "no", "n"].contains(raw) {
            return false
        }

        return defaultValue
    }
}

enum ConfigurationError: LocalizedError {
    case missingSecret(String)

    var errorDescription: String? {
        switch self {
        case .missingSecret(let key):
            return String(
                format: String(localized: "config.error.missing_secret"),
                key
            )
        }
    }
}
