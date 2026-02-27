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
