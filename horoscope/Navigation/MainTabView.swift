import SwiftUI
import Foundation
import UIKit

struct MainTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(UsageLimitService.self) private var usageLimitService

    @AppStorage("selected_main_destination_v3") private var selectedDestinationRawValue = AppDestination.home.rawValue
    @State private var selectedDestination: AppDestination = .home
    @State private var isKeyboardVisible = false

    private let legacySelectionKey = "selected_main_destination_v2"
    private let isUITestAuthenticated = ProcessInfo.processInfo.arguments.contains("UITEST_AUTHENTICATED")

    var body: some View {
        GeometryReader { proxy in
            let bottomSafeArea = proxy.safeAreaInsets.bottom
            let dockHeight = AuroraDockMetrics.height(bottomSafeArea: bottomSafeArea)
            let chromeMetrics = MainChromeMetrics(
                tabBarVisible: !isKeyboardVisible,
                tabBarHeight: !isKeyboardVisible ? dockHeight : 0,
                floatingQuickActionSize: 0,
                bottomSafeAreaInset: bottomSafeArea
            )

            ZStack {
                currentDestinationView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !isKeyboardVisible {
                    AuroraDock(
                        selectedDestination: $selectedDestination,
                        bottomSafeArea: bottomSafeArea
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .environment(\.mainChromeMetrics, chromeMetrics)
            .onAppear {
                restoreSelectedDestination()
            }
            .onChange(of: selectedDestination) { _, newValue in
                selectedDestinationRawValue = newValue.rawValue
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToMainTab)) { notification in
                if let destination = notification.object as? AppDestination {
                    switchToDestination(destination)
                } else if let legacyTab = notification.object as? AppTab {
                    handleLegacyTabSwitch(legacyTab)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(reduceMotion ? nil : AuroraMotion.transition) {
                    isKeyboardVisible = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(reduceMotion ? nil : AuroraMotion.transition) {
                    isKeyboardVisible = false
                }
            }
            .sheet(isPresented: Bindable(usageLimitService).showPaywall) {
                PaywallView()
            }
        }
    }

    @ViewBuilder
    private var currentDestinationView: some View {
        switch selectedDestination {
        case .tarot:
            TarotView(showsCloseButton: false)
        case .oracle:
            OracleView()
        case .home:
            SanctumView()
        case .dreams:
            JournalView()
        case .profile:
            ProfileView()
        }
    }

    private func restoreSelectedDestination() {
        if isUITestAuthenticated {
            selectedDestination = .home
            selectedDestinationRawValue = AppDestination.home.rawValue
            return
        }

        if let restored = AppDestination(rawValue: selectedDestinationRawValue) {
            selectedDestination = restored
            return
        }

        let legacyRawValue = UserDefaults.standard.string(forKey: legacySelectionKey)
        let migrated = AppDestination.migrated(fromLegacyRawValue: legacyRawValue) ?? .home
        selectedDestination = migrated
        selectedDestinationRawValue = migrated.rawValue
    }

    private func handleLegacyTabSwitch(_ legacyTab: AppTab) {
        if legacyTab == .chart {
            AppNavigation.openAtlas()
            return
        }

        switchToDestination(legacyTab.destination)
    }

    private func switchToDestination(_ destination: AppDestination) {
        if selectedDestination == destination {
            AppNavigation.scrollToTop(for: destination)
            return
        }

        withAnimation(reduceMotion ? nil : AuroraMotion.spring) {
            selectedDestination = destination
        }
    }
}

private enum AuroraDockMetrics {
    static let sideButtonSize: CGFloat = 52
    static let centerButtonSize: CGFloat = 78
    static let orbLift: CGFloat = 24
    static let surfaceHeight: CGFloat = 88
    static let centerSlotWidth: CGFloat = 98

    static func height(bottomSafeArea: CGFloat) -> CGFloat {
        surfaceHeight + orbLift + max(bottomSafeArea, 10)
    }
}

private struct AuroraDock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedDestination: AppDestination
    let bottomSafeArea: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AuroraColors.surfaceElevated.opacity(0.98),
                            AuroraColors.cardBase.opacity(0.96),
                            AuroraColors.obsidian.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(AuroraGradients.cardWash(accent: selectedDestination.accent))
                        .opacity(0.45)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    selectedDestination.accent.opacity(0.22),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(height: AuroraDockMetrics.surfaceHeight)
                .shadow(color: AuroraColors.dockShadow, radius: 28, x: 0, y: 18)

            HStack(spacing: 0) {
                dockButton(for: .tarot)
                dockButton(for: .oracle)
                Color.clear
                    .frame(width: AuroraDockMetrics.centerSlotWidth)
                dockButton(for: .dreams)
                dockButton(for: .profile)
            }
            .frame(height: AuroraDockMetrics.surfaceHeight)
            .padding(.horizontal, AuroraSpacing.md)

            homeButton
                .offset(y: -AuroraDockMetrics.orbLift)
        }
        .padding(.horizontal, AuroraSpacing.md)
        .padding(.top, AuroraDockMetrics.orbLift)
        .padding(.bottom, max(bottomSafeArea, 10))
        .background(
            LinearGradient(
                colors: [Color.clear, AuroraColors.obsidian.opacity(0.84)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.container, edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("main.tab_bar")
    }

    private func dockButton(for destination: AppDestination) -> some View {
        let isSelected = selectedDestination == destination

        return Button {
            select(destination)
        } label: {
            ZStack {
                Circle()
                    .fill(destination.accent.opacity(isSelected ? 0.18 : 0.03))
                    .frame(width: isSelected ? 42 : 38, height: isSelected ? 42 : 38)

                if isSelected {
                    Circle()
                        .stroke(destination.accent.opacity(0.35), lineWidth: 1)
                        .frame(width: 46, height: 46)
                }

                AuroraGlyph(
                    kind: destination.glyphKind,
                    color: isSelected ? destination.accent : AuroraColors.textMuted.opacity(0.92),
                    lineWidth: isSelected ? 2 : 1.7
                )
                .frame(width: 22, height: 22)
            }
            .frame(width: AuroraDockMetrics.sideButtonSize, height: AuroraDockMetrics.surfaceHeight)
            .shadow(color: isSelected ? destination.accent.opacity(0.2) : .clear, radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(destination.title))
        .accessibilityHint(Text(String(localized: "tab.switch.hint")))
        .accessibilityIdentifier(destination.dockAccessibilityIdentifier)
    }

    private var homeButton: some View {
        let isSelected = selectedDestination == .home

        return Button {
            select(.home)
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? AnyShapeStyle(AuroraGradients.primaryCTA) : AnyShapeStyle(AuroraGradients.auroraVeil))
                    .frame(width: AuroraDockMetrics.centerButtonSize, height: AuroraDockMetrics.centerButtonSize)

                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: AuroraDockMetrics.centerButtonSize, height: AuroraDockMetrics.centerButtonSize)

                Circle()
                    .stroke(AuroraColors.auroraViolet.opacity(0.12), lineWidth: 1)
                    .frame(width: AuroraDockMetrics.centerButtonSize + 16, height: AuroraDockMetrics.centerButtonSize + 16)

                AuroraGlyph(
                    kind: .saturn,
                    color: AuroraColors.obsidian.opacity(0.9),
                    lineWidth: 2.2
                )
                .frame(width: 30, height: 30)
            }
            .shadow(
                color: isSelected
                    ? AuroraColors.auroraMint.opacity(0.28)
                    : AuroraColors.auroraViolet.opacity(0.18),
                radius: 24,
                x: 0,
                y: 16
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(AppDestination.home.title))
        .accessibilityHint(Text(String(localized: "tab.switch.hint")))
        .accessibilityIdentifier(AppDestination.home.dockAccessibilityIdentifier)
    }

    private func select(_ destination: AppDestination) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if selectedDestination == destination {
            AppNavigation.scrollToTop(for: destination)
            return
        }

        withAnimation(reduceMotion ? nil : AuroraMotion.spring) {
            selectedDestination = destination
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
    static let openAtlasExperience = Notification.Name("openAtlasExperience")
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
    private static var pendingAtlasExperience = false

    static func switchToDestination(_ destination: AppDestination) {
        NotificationCenter.default.post(name: .switchToMainTab, object: destination)
    }

    static func switchToTab(_ tab: AppTab) {
        switch tab {
        case .chart:
            openAtlas()
        default:
            switchToDestination(tab.destination)
        }
    }

    static func scrollToTop(for destination: AppDestination) {
        NotificationCenter.default.post(name: .scrollToTop, object: destination)
    }

    static func scrollToTop(for tab: AppTab) {
        scrollToTop(for: tab.destination)
    }

    static func openChat(context: ChatContext, prompt: String? = nil) {
        pendingChatQuickAction = (context: context, prompt: prompt)

        var payload: [String: Any] = [AppNavigationPayload.context: context.rawValue]
        if let prompt {
            payload[AppNavigationPayload.prompt] = prompt
        }

        switchToDestination(.oracle)
        NotificationCenter.default.post(name: .openChatQuickAction, object: nil, userInfo: payload)
    }

    static func consumePendingChatQuickAction() -> (context: ChatContext, prompt: String?)? {
        defer { pendingChatQuickAction = nil }
        return pendingChatQuickAction
    }

    static func openDreamComposer() {
        pendingDreamComposer = true
        switchToDestination(.dreams)
        NotificationCenter.default.post(name: .openDreamComposer, object: nil)
    }

    static func consumePendingDreamComposer() -> Bool {
        defer { pendingDreamComposer = false }
        return pendingDreamComposer
    }

    static func openTarotQuickAction() {
        pendingTarotQuickAction = true
        switchToDestination(.tarot)
        NotificationCenter.default.post(name: .openTarotQuickAction, object: nil)
    }

    static func consumePendingTarotQuickAction() -> Bool {
        defer { pendingTarotQuickAction = false }
        return pendingTarotQuickAction
    }

    static func openPalmQuickAction() {
        pendingPalmQuickAction = true
        switchToDestination(.oracle)
        NotificationCenter.default.post(name: .openPalmQuickAction, object: nil)
    }

    static func consumePendingPalmQuickAction() -> Bool {
        defer { pendingPalmQuickAction = false }
        return pendingPalmQuickAction
    }

    static func openAtlas() {
        pendingAtlasExperience = true
        switchToDestination(.home)
        NotificationCenter.default.post(name: .openAtlasExperience, object: nil)
    }

    static func consumePendingAtlasExperience() -> Bool {
        defer { pendingAtlasExperience = false }
        return pendingAtlasExperience
    }

    static func openQuickActionsSheet() {
        switchToDestination(.oracle)
    }
}

enum AppDestination: String, CaseIterable {
    case tarot
    case oracle
    case home
    case dreams
    case profile

    static func migrated(fromLegacyRawValue rawValue: String?) -> AppDestination? {
        guard let rawValue else { return nil }
        switch rawValue {
        case "sanctum":
            return .home
        case "atlas":
            return .home
        case "oracle":
            return .oracle
        case "journal":
            return .dreams
        case "profile":
            return .profile
        case "tarot":
            return .tarot
        case "home":
            return .home
        case "dreams":
            return .dreams
        default:
            return AppDestination(rawValue: rawValue)
        }
    }

    var title: String {
        switch self {
        case .tarot:
            return String(localized: "tab.aurora.tarot")
        case .oracle:
            return String(localized: "tab.aurora.oracle")
        case .home:
            return String(localized: "tab.aurora.home")
        case .dreams:
            return String(localized: "tab.aurora.dreams")
        case .profile:
            return String(localized: "tab.aurora.profile")
        }
    }

    var shortTitle: String {
        title
    }

    var accent: Color {
        switch self {
        case .tarot:
            return AuroraColors.auroraRose
        case .oracle:
            return AuroraColors.auroraViolet
        case .home:
            return AuroraColors.auroraMint
        case .dreams:
            return AuroraColors.auroraCyan
        case .profile:
            return AuroraColors.polarWhite
        }
    }

    var glyphKind: AuroraGlyphKind {
        switch self {
        case .tarot:
            return .tarot
        case .oracle:
            return .eye
        case .home:
            return .saturn
        case .dreams:
            return .dreamcatcher
        case .profile:
            return .profile
        }
    }

    var dockAccessibilityIdentifier: String {
        switch self {
        case .tarot:
            return "dock.tarot"
        case .oracle:
            return "dock.oracle"
        case .home:
            return "dock.home"
        case .dreams:
            return "dock.dreams"
        case .profile:
            return "dock.profile"
        }
    }
}

enum AppTab: String, CaseIterable {
    case home
    case chart
    case chat
    case dream
    case profile

    var destination: AppDestination {
        switch self {
        case .home:
            return .home
        case .chart:
            return .home
        case .chat:
            return .oracle
        case .dream:
            return .dreams
        case .profile:
            return .profile
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthService())
}
