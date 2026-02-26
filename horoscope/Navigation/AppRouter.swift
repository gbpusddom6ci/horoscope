import SwiftUI

struct AppRouter: View {
    @State private var authService = AuthService()
    @State private var premiumService = PremiumService.shared
    @State private var notificationService = NotificationService.shared
    @AppStorage("selected_language") private var selectedLanguage = "tr"

    var body: some View {
        ZStack {
            // Solid dark background — always visible
            Color(red: 0.03, green: 0.02, blue: 0.06)
                .ignoresSafeArea()

            // Content based on auth state
            contentView
        }
        .environment(authService)
        .environment(premiumService)
        .environment(notificationService)
        .environment(\.locale, Locale(identifier: selectedLanguage))
        .preferredColorScheme(.dark)
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
