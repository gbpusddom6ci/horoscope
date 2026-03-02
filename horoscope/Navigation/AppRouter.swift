import SwiftUI

struct AppRouter: View {
    @State private var authService = AuthService()
    @State private var premiumService = PremiumService.shared
    @State private var notificationService = NotificationService.shared
    @State private var usageLimitService = UsageLimitService.shared
    @State private var networkMonitor = NetworkMonitor.shared
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
            
            // Global No Internet Banner
            if !networkMonitor.isConnected {
                VStack {
                    HStack(spacing: MysticSpacing.sm) {
                        Image(systemName: "wifi.slash")
                        Text(String(localized: "common.error.no_internet", defaultValue: "No Internet Connection"))
                            .font(MysticFonts.body(14))
                    }
                    .foregroundColor(MysticColors.starWhite)
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.vertical, 12)
                    .background(MysticColors.celestialPink.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: MysticColors.celestialPink.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: networkMonitor.isConnected)
                .zIndex(999)
            }
        }
        .environment(authService)
        .environment(premiumService)
        .environment(notificationService)
        .environment(usageLimitService)
        .environment(networkMonitor)
        .environment(\.locale, Locale(identifier: resolvedLanguage))
        .preferredColorScheme(.dark)
        .onAppear {
            usageLimitService.authService = authService
            usageLimitService.refreshForCurrentUser()
            sanitizeLanguageSelection()
        }
        .onChange(of: authService.currentUser?.id) { _, _ in
            usageLimitService.refreshForCurrentUser()
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
        SplashView()
    }
}

#Preview {
    AppRouter()
}
