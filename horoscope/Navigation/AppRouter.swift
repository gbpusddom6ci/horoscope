import SwiftUI

struct AppRouter: View {
    @State private var authService = AuthService()
    @State private var premiumService = PremiumService.shared
    @State private var notificationService = NotificationService.shared
    @AppStorage("selected_language") private var selectedLanguage = "en"

    private let supportedLanguages: Set<String> = ["en", "tr"]

    private var resolvedLanguage: String {
        Self.resolveLanguageCode(selectedLanguage, supportedLanguages: supportedLanguages)
    }

    var body: some View {
        ZStack {
            // Solid dark background — always visible
            MysticColors.voidBlack
                .ignoresSafeArea()

            // Content based on auth state
            contentView
        }
        .environment(authService)
        .environment(premiumService)
        .environment(notificationService)
        .environment(\.locale, Locale(identifier: resolvedLanguage))
        .preferredColorScheme(.dark)
        .onAppear {
            sanitizeLanguageSelection()
        }
        .onChange(of: selectedLanguage) { _, _ in
            sanitizeLanguageSelection()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch authService.authState {
        case .unknown:
            splashView

        case .unauthenticated:
            AuthView()

        case .onboarding:
            OnboardingView()

        case .authenticated:
            MainTabView()
        }
    }

    private func sanitizeLanguageSelection() {
        let normalized = resolvedLanguage
        if selectedLanguage != normalized {
            selectedLanguage = normalized
        }
    }

    static func resolveLanguageCode(
        _ rawValue: String,
        supportedLanguages: Set<String> = ["en", "tr"],
        fallback: String = "en"
    ) -> String {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()

        guard !normalized.isEmpty else {
            return fallback
        }

        let baseCode = normalized.split(separator: "-").first.map(String.init) ?? normalized
        if supportedLanguages.contains(baseCode) {
            return baseCode
        }

        if supportedLanguages.contains(normalized) {
            return normalized
        }

        return fallback
    }

    // MARK: - Splash View
    private var splashView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))

            Text("Mystic")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))

            ProgressView()
                .tint(Color(red: 0.70, green: 0.53, blue: 1.0))
                .scaleEffect(1.2)
        }
    }
}

#Preview {
    AppRouter()
}
