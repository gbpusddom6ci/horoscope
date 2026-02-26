import SwiftUI
import Foundation

struct MainTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("selected_main_tab_v1") private var selectedTabRawValue = AppTab.home.rawValue
    @State private var selectedTab: AppTab = .home
    @State private var showQuickActions = false
    @State private var isKeyboardVisible = false

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
            if !isKeyboardVisible {
                customTabBar
                    .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            if let restored = AppTab(rawValue: selectedTabRawValue) {
                selectedTab = restored
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            selectedTabRawValue = newValue.rawValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToMainTab)) { notification in
            guard let tab = notification.object as? AppTab else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                selectedTab = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuickActionsSheet)) { _ in
            showQuickActions = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                isKeyboardVisible = false
            }
        }
        .sheet(isPresented: $showQuickActions) {
            QuickActionsSheet { action in
                runQuickAction(action)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.chart)
            quickActionButton
            tabButton(.chat)
            tabButton(.dream)
            tabButton(.profile)
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
            withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
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

                    if reduceMotion {
                        Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? tab.color : MysticColors.textMuted)
                    } else {
                        Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? tab.color : MysticColors.textMuted)
                            .symbolEffect(.bounce, value: selectedTab == tab)
                    }
                }
                .frame(height: 42)

                if selectedTab == tab {
                    Text(tab.title)
                        .font(MysticFonts.caption(10))
                        .foregroundColor(tab.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: MysticAccessibility.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tab.title))
        .accessibilityHint(Text(String(localized: "tab.switch.hint")))
        .accessibilityIdentifier("tab.\(tab.rawValue)")
    }

    private var quickActionButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            showQuickActions = true
        } label: {
            VStack(spacing: MysticSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(MysticGradients.goldShimmer)
                        .frame(width: 44, height: 44)
                    Circle()
                        .stroke(MysticColors.mysticGold.opacity(0.5), lineWidth: 1)
                        .frame(width: 44, height: 44)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MysticColors.voidBlack)
                }
                Text("quick_actions.title")
                    .font(MysticFonts.caption(10))
                    .foregroundColor(MysticColors.mysticGold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: MysticAccessibility.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "quick_actions.title")))
        .accessibilityHint(Text(String(localized: "quick_actions.hint")))
        .accessibilityIdentifier("quick_actions.button")
    }

    private func runQuickAction(_ action: QuickAction) {
        showQuickActions = false

        switch action {
        case .newChat:
            AppNavigation.switchToTab(.chat)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AppNavigation.openChat(context: .general)
            }
        case .newDream:
            AppNavigation.switchToTab(.dream)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AppNavigation.openDreamComposer()
            }
        case .openTarot:
            AppNavigation.switchToTab(.home)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AppNavigation.openTarotQuickAction()
            }
        case .openPalm:
            AppNavigation.switchToTab(.home)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AppNavigation.openPalmQuickAction()
            }
        }
    }
}

extension Notification.Name {
    static let switchToMainTab = Notification.Name("switchToMainTab")
    static let didReceiveFCMToken = Notification.Name("didReceiveFCMToken")
    static let openChatQuickAction = Notification.Name("openChatQuickAction")
    static let openDreamComposer = Notification.Name("openDreamComposer")
    static let openTarotQuickAction = Notification.Name("openTarotQuickAction")
    static let openPalmQuickAction = Notification.Name("openPalmQuickAction")
    static let openQuickActionsSheet = Notification.Name("openQuickActionsSheet")
}

enum AppNavigationPayload {
    static let context = "context"
    static let prompt = "prompt"
}

enum AppNavigation {
    static func switchToTab(_ tab: AppTab) {
        NotificationCenter.default.post(name: .switchToMainTab, object: tab)
    }

    static func openChat(context: ChatContext, prompt: String? = nil) {
        var payload: [String: Any] = [AppNavigationPayload.context: context.rawValue]
        if let prompt {
            payload[AppNavigationPayload.prompt] = prompt
        }
        NotificationCenter.default.post(name: .openChatQuickAction, object: nil, userInfo: payload)
    }

    static func openDreamComposer() {
        NotificationCenter.default.post(name: .openDreamComposer, object: nil)
    }

    static func openTarotQuickAction() {
        NotificationCenter.default.post(name: .openTarotQuickAction, object: nil)
    }

    static func openPalmQuickAction() {
        NotificationCenter.default.post(name: .openPalmQuickAction, object: nil)
    }

    static func openQuickActionsSheet() {
        NotificationCenter.default.post(name: .openQuickActionsSheet, object: nil)
    }
}

// MARK: - Tab Configuration
enum AppTab: String, CaseIterable {
    case home
    case chart
    case chat
    case dream
    case profile

    var title: String {
        switch self {
        case .home: return String(localized: "tab.home")
        case .chart: return String(localized: "tab.chart")
        case .chat: return String(localized: "tab.chat")
        case .dream: return String(localized: "tab.dream")
        case .profile: return String(localized: "tab.profile")
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

private enum QuickAction: CaseIterable {
    case newChat
    case newDream
    case openTarot
    case openPalm

    var title: String {
        switch self {
        case .newChat: return String(localized: "quick_actions.chat")
        case .newDream: return String(localized: "quick_actions.dream")
        case .openTarot: return String(localized: "quick_actions.tarot")
        case .openPalm: return String(localized: "quick_actions.palm")
        }
    }

    var subtitle: String {
        switch self {
        case .newChat: return String(localized: "quick_actions.chat.subtitle")
        case .newDream: return String(localized: "quick_actions.dream.subtitle")
        case .openTarot: return String(localized: "quick_actions.tarot.subtitle")
        case .openPalm: return String(localized: "quick_actions.palm.subtitle")
        }
    }

    var icon: String {
        switch self {
        case .newChat: return "bubble.left.and.bubble.right.fill"
        case .newDream: return "moon.zzz.fill"
        case .openTarot: return "suit.diamond.fill"
        case .openPalm: return "hand.raised.fill"
        }
    }

    var testId: String {
        switch self {
        case .newChat: return "quick_action.new_chat"
        case .newDream: return "quick_action.new_dream"
        case .openTarot: return "quick_action.open_tarot"
        case .openPalm: return "quick_action.open_palm"
        }
    }

    var color: Color {
        switch self {
        case .newChat: return MysticColors.auroraGreen
        case .newDream: return MysticColors.celestialPink
        case .openTarot: return MysticColors.mysticGold
        case .openPalm: return MysticColors.neonLavender
        }
    }
}

private struct QuickActionsSheet: View {
    let onSelect: (QuickAction) -> Void

    var body: some View {
        ZStack {
            MysticColors.voidBlack.ignoresSafeArea()
            StarField(starCount: 25)

            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                Text("quick_actions.title")
                    .font(MysticFonts.heading(20))
                    .foregroundColor(MysticColors.textPrimary)

                Text("quick_actions.subtitle")
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)

                ForEach(QuickAction.allCases, id: \.self) { action in
                    Button {
                        onSelect(action)
                    } label: {
                        MysticCard(glowColor: action.color) {
                            HStack(spacing: MysticSpacing.md) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(action.color)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.title)
                                        .font(MysticFonts.body(15))
                                        .foregroundColor(MysticColors.textPrimary)
                                    Text(action.subtitle)
                                        .font(MysticFonts.caption(12))
                                        .foregroundColor(MysticColors.textMuted)
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(MysticColors.textMuted)
                            }
                            .frame(minHeight: MysticAccessibility.minimumTapTarget)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(action.title))
                    .accessibilityHint(Text(String(localized: "quick_actions.item.hint")))
                    .accessibilityIdentifier(action.testId)
                }

                Spacer(minLength: 0)
            }
            .padding(MysticSpacing.md)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthService())
}
