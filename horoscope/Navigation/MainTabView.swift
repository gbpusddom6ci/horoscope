import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var tabBarVisible = true

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        // Content
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(AppTab.home)
            NatalChartView()
                .tag(AppTab.chart)
            ChatView()
                .tag(AppTab.chat)
            DreamJournalView()
                .tag(AppTab.dream)
            SettingsView()
                .tag(AppTab.profile)
        }
        // Use basic display mode (no page style) to prevent horizontal swiping
        .safeAreaInset(edge: .bottom) {
            // Custom Tab Bar
            if tabBarVisible {
                customTabBar
                    .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, MysticSpacing.sm)
        .padding(.top, MysticSpacing.sm)
        .padding(.bottom, MysticSpacing.lg)
        .background(
            ZStack {
                // Blur background
                Rectangle()
                    .fill(MysticColors.voidBlack.opacity(0.85))

                Rectangle()
                    .fill(MysticGradients.cardGlass)

                // Top border glow
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    MysticColors.neonLavender.opacity(0.3),
                                    MysticColors.mysticGold.opacity(0.1),
                                    MysticColors.neonLavender.opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    Spacer()
                }
            }
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                selectedTab = tab
            }
        } label: {
            VStack(spacing: MysticSpacing.xs) {
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(tab.color.opacity(0.15))
                            .frame(width: 42, height: 42)

                        Circle()
                            .stroke(tab.color.opacity(0.3), lineWidth: 1)
                            .frame(width: 42, height: 42)
                    }

                    Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                        .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(selectedTab == tab ? tab.color : MysticColors.textMuted)
                        .symbolEffect(.bounce, value: selectedTab == tab)
                }
                .frame(height: 42)

                Text(tab.title)
                    .font(MysticFonts.caption(10))
                    .foregroundColor(selectedTab == tab ? tab.color : MysticColors.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Configuration
enum AppTab: CaseIterable {
    case home
    case chart
    case chat
    case dream
    case profile

    var title: String {
        switch self {
        case .home: return "Ana Sayfa"
        case .chart: return "Harita"
        case .chat: return "AI Sohbet"
        case .dream: return "Rüya"
        case .profile: return "Profil"
        }
    }

    var icon: String {
        switch self {
        case .home: return "sparkles"
        case .chart: return "circle.hexagongrid"
        case .chat: return "bubble.left.and.bubble.right"
        case .dream: return "moon.zzz"
        case .profile: return "person.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: return "sparkles"
        case .chart: return "circle.hexagongrid.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .dream: return "moon.zzz.fill"
        case .profile: return "person.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .home: return MysticColors.mysticGold
        case .chart: return MysticColors.neonLavender
        case .chat: return MysticColors.auroraGreen
        case .dream: return MysticColors.celestialPink
        case .profile: return MysticColors.starWhite
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthService())
}
