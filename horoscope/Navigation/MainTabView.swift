import SwiftUI
import Foundation
import UIKit

struct MainTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(UsageLimitService.self) private var usageLimitService
    @AppStorage("selected_main_tab_v1") private var selectedTabRawValue = AppTab.home.rawValue
    @State private var selectedTab: AppTab = .home
    @State private var showQuickActions = false
    @State private var isKeyboardVisible = false

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        GeometryReader { proxy in
            let bottomSafeArea = proxy.safeAreaInsets.bottom
            let tabBarHeight = MysticLayout.tabBarHeight(bottomSafeArea: bottomSafeArea)
            let chromeMetrics = MainChromeMetrics(
                tabBarVisible: !isKeyboardVisible,
                tabBarHeight: !isKeyboardVisible ? tabBarHeight : 0,
                floatingQuickActionSize: !isKeyboardVisible ? MysticLayout.floatingQuickActionSize : 0,
                bottomSafeAreaInset: bottomSafeArea
            )

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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !isKeyboardVisible {
                    customTabBar(bottomSafeArea: bottomSafeArea)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottom) {
                if !isKeyboardVisible {
                    floatingChatButton
                        .padding(.bottom, tabBarHeight - MysticLayout.floatingQuickActionLift)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .environment(\.mainChromeMetrics, chromeMetrics)
            .onAppear {
                let restoredTab = AppTab(rawValue: selectedTabRawValue) ?? .home
                selectedTab = restoredTab
                if selectedTabRawValue != restoredTab.rawValue {
                    selectedTabRawValue = restoredTab.rawValue
                }
            }
            .onChange(of: selectedTabRawValue) { _, newRawValue in
                let restoredTab = AppTab(rawValue: newRawValue) ?? .home
                if selectedTab != restoredTab {
                    selectedTab = restoredTab
                }
                if newRawValue != restoredTab.rawValue {
                    selectedTabRawValue = restoredTab.rawValue
                }
            }
            .onChange(of: selectedTab) { _, newValue in
                selectedTabRawValue = newValue.rawValue
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToMainTab)) { notification in
                guard let tab = notification.object as? AppTab else { return }
                switchToTab(tab)
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
            .sheet(isPresented: Bindable(usageLimitService).showPaywall) {
                PaywallView()
            }
        }
    }

    private func customTabBar(bottomSafeArea: CGFloat) -> some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.chart)

            Spacer(minLength: MysticLayout.floatingQuickActionSize + (MysticSpacing.md * 2))

            tabButton(.dream)
            tabButton(.profile)
        }
        .padding(.horizontal, MysticLayout.screenHorizontalPadding)
        .padding(.top, MysticLayout.tabBarVisualTopPadding)
        .padding(.bottom, MysticLayout.tabBarBottomPadding(bottomSafeArea: bottomSafeArea))
        .background(
            ZStack {
                Rectangle()
                    .fill(MysticColors.voidBlack.opacity(0.85))

                Rectangle()
                    .fill(MysticGradients.cardGlass)

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
            .ignoresSafeArea(.container, edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("main.tab_bar")
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            if selectedTab == tab {
                AppNavigation.scrollToTop(for: tab)
                return
            }

            withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: MysticSpacing.xs) {
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(tab.color.opacity(0.15))
                            .frame(width: MysticLayout.tabBarIconFrame, height: MysticLayout.tabBarIconFrame)

                        Circle()
                            .stroke(tab.color.opacity(0.3), lineWidth: 1)
                            .frame(width: MysticLayout.tabBarIconFrame, height: MysticLayout.tabBarIconFrame)
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
                .frame(height: MysticLayout.tabBarIconFrame)

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(tab.title))
        .accessibilityHint(Text(String(localized: "tab.switch.hint")))
        .accessibilityValue(Text(selectedTab == tab ? String(localized: "common.accessibility.selected") : String(localized: "common.accessibility.unselected")))
        .accessibilityIdentifier("tab.\(tab.rawValue)")
    }

    private var floatingChatButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            if selectedTab == .chat {
                AppNavigation.scrollToTop(for: .chat)
                return
            }

            withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                selectedTab = .chat
            }
        } label: {
            ZStack {
                Circle()
                    .fill(selectedTab == .chat ? MysticGradients.auroraShift : MysticGradients.goldShimmer)
                    .frame(width: MysticLayout.floatingQuickActionSize, height: MysticLayout.floatingQuickActionSize)

                Circle()
                    .stroke(
                        selectedTab == .chat
                            ? MysticColors.auroraGreen.opacity(0.6)
                            : MysticColors.mysticGold.opacity(0.55),
                        lineWidth: 1.2
                    )
                    .frame(width: MysticLayout.floatingQuickActionSize, height: MysticLayout.floatingQuickActionSize)

                Image(systemName: selectedTab == .chat ? "bubble.left.and.bubble.right.fill" : "bolt.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(MysticColors.voidBlack)
            }
            .shadow(
                color: selectedTab == .chat
                    ? MysticColors.auroraGreen.opacity(0.22)
                    : MysticColors.mysticGold.opacity(0.28),
                radius: 12,
                x: 0,
                y: 4
            )
            .frame(
                minWidth: MysticLayout.floatingQuickActionSize,
                minHeight: MysticLayout.floatingQuickActionSize
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    showQuickActions = true
                }
        )
        .accessibilityLabel(Text(String(localized: "tab.chat")))
        .accessibilityHint(Text(String(localized: "tab.chat.fab.hint")))
        .accessibilityValue(Text(selectedTab == .chat ? String(localized: "common.accessibility.selected") : String(localized: "common.accessibility.unselected")))
        .accessibilityIdentifier("quick_actions.button")
    }

    private func switchToTab(_ tab: AppTab) {
        if selectedTab == tab {
            AppNavigation.scrollToTop(for: tab)
            return
        }

        withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
            selectedTab = tab
        }
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
    static let scrollToTop = Notification.Name("scrollToTop")
}

enum AppNavigationPayload {
    static let context = "context"
    static let prompt = "prompt"
}

enum AppNavigation {
    private static var pendingChatQuickAction: (context: ChatContext, prompt: String?)?
    private static var pendingDreamComposer = false
    private static var pendingTarotQuickAction = false
    private static var pendingPalmQuickAction = false

    static func switchToTab(_ tab: AppTab) {
        NotificationCenter.default.post(name: .switchToMainTab, object: tab)
    }

    static func scrollToTop(for tab: AppTab) {
        NotificationCenter.default.post(name: .scrollToTop, object: tab)
    }

    static func openChat(context: ChatContext, prompt: String? = nil) {
        pendingChatQuickAction = (context: context, prompt: prompt)

        var payload: [String: Any] = [AppNavigationPayload.context: context.rawValue]
        if let prompt {
            payload[AppNavigationPayload.prompt] = prompt
        }
        NotificationCenter.default.post(name: .openChatQuickAction, object: nil, userInfo: payload)
    }

    static func consumePendingChatQuickAction() -> (context: ChatContext, prompt: String?)? {
        defer { pendingChatQuickAction = nil }
        return pendingChatQuickAction
    }

    static func openDreamComposer() {
        pendingDreamComposer = true
        NotificationCenter.default.post(name: .openDreamComposer, object: nil)
    }

    static func consumePendingDreamComposer() -> Bool {
        defer { pendingDreamComposer = false }
        return pendingDreamComposer
    }

    static func openTarotQuickAction() {
        pendingTarotQuickAction = true
        NotificationCenter.default.post(name: .openTarotQuickAction, object: nil)
    }

    static func consumePendingTarotQuickAction() -> Bool {
        defer { pendingTarotQuickAction = false }
        return pendingTarotQuickAction
    }

    static func openPalmQuickAction() {
        pendingPalmQuickAction = true
        NotificationCenter.default.post(name: .openPalmQuickAction, object: nil)
    }

    static func consumePendingPalmQuickAction() -> Bool {
        defer { pendingPalmQuickAction = false }
        return pendingPalmQuickAction
    }

    static func openQuickActionsSheet() {
        NotificationCenter.default.post(name: .openQuickActionsSheet, object: nil)
    }
}

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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    MainTabView()
        .environment(AuthService())
}
