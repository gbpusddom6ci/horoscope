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
        case .palm:
            PalmReadingView()
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

enum AuroraDockMetrics {
    static let outerHorizontalPadding: CGFloat = AuroraSpacing.md
    static let sideButtonVisualSize: CGFloat = 40
    static let centerButtonSize: CGFloat = 68
    static let orbLift: CGFloat = 14
    static let surfaceHeight: CGFloat = 72
    static let centerSlotWidth: CGFloat = 88

    static func bottomSpacing(bottomSafeArea: CGFloat) -> CGFloat {
        max(4, min(10, bottomSafeArea * 0.18))
    }

    static func height(bottomSafeArea: CGFloat) -> CGFloat {
        surfaceHeight + orbLift + bottomSpacing(bottomSafeArea: bottomSafeArea)
    }

    static func sideSlotWidth(containerWidth: CGFloat) -> CGFloat {
        let usableWidth = max(0, containerWidth - (outerHorizontalPadding * 2) - centerSlotWidth)
        return usableWidth / 4
    }
}

private struct AuroraDock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedDestination: AppDestination
    let bottomSafeArea: CGFloat

    var body: some View {
        let bottomSpacing = AuroraDockMetrics.bottomSpacing(bottomSafeArea: bottomSafeArea)

        ZStack(alignment: .top) {
            dockSurface

            GeometryReader { proxy in
                let sideSlotWidth = AuroraDockMetrics.sideSlotWidth(containerWidth: proxy.size.width)

                HStack(spacing: 0) {
                    dockSlot(for: .tarot, width: sideSlotWidth)
                    dockSlot(for: .dreams, width: sideSlotWidth)
                    Color.clear
                        .frame(width: AuroraDockMetrics.centerSlotWidth, height: AuroraDockMetrics.surfaceHeight)
                    dockSlot(for: .palm, width: sideSlotWidth)
                    dockSlot(for: .profile, width: sideSlotWidth)
                }
            }
            .frame(height: AuroraDockMetrics.surfaceHeight)
            .padding(.horizontal, AuroraDockMetrics.outerHorizontalPadding)

            homeButton
                .offset(y: -AuroraDockMetrics.orbLift)
        }
        .padding(.horizontal, AuroraDockMetrics.outerHorizontalPadding)
        .padding(.top, AuroraDockMetrics.orbLift)
        .padding(.bottom, bottomSpacing)
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    selectedDestination.accent.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.container, edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("main.tab_bar")
    }

    private var dockSurface: some View {
        let shape = RoundedRectangle(cornerRadius: AuroraRadius.xl, style: .continuous)

        return shape
            .fill(
                LinearGradient(
                    colors: [
                        AuroraColors.surfaceElevated.opacity(0.96),
                        AuroraColors.pearl.opacity(0.9),
                        AuroraColors.frost.opacity(0.84)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                shape
                    .fill(AuroraGradients.silkHighlight)
                    .opacity(0.42)
                    .blendMode(.screen)
            }
            .overlay {
                shape
                    .fill(AuroraGradients.cardWash(accent: selectedDestination.accent))
                    .opacity(0.92)
            }
            .overlay {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(AuroraGradients.auroraSpectrum)
                        .frame(width: 210, height: 20)
                        .blur(radius: 18)
                        .offset(x: -54, y: -18)
                        .opacity(0.14)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    selectedDestination.accent.opacity(0.36),
                                    AuroraColors.auroraCyan.opacity(0.2),
                                    AuroraColors.auroraViolet.opacity(0.12)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 164, height: 18)
                        .blur(radius: 16)
                        .offset(x: 68, y: -4)
                        .opacity(0.18)
                }
                .clipShape(shape)
            }
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.52),
                            selectedDestination.accent.opacity(0.4),
                            AuroraColors.auroraCyan.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.05
                )
            }
            .overlay {
                shape.stroke(Color.white.opacity(0.18), lineWidth: 0.7)
            }
            .frame(height: AuroraDockMetrics.surfaceHeight)
            .shadow(color: selectedDestination.accent.opacity(0.14), radius: 18, x: 0, y: 8)
            .shadow(color: AuroraColors.shadow.opacity(0.28), radius: 24, x: 0, y: 14)
    }

    private func dockSlot(for destination: AppDestination, width: CGFloat) -> some View {
        dockButton(for: destination)
            .frame(width: width, height: AuroraDockMetrics.surfaceHeight)
    }

    private func dockButton(for destination: AppDestination) -> some View {
        let isSelected = selectedDestination == destination

        return Button {
            select(destination)
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(destination.accent.opacity(0.12))
                        .frame(width: 50, height: 50)
                        .blur(radius: 10)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [
                                    destination.accent.opacity(0.28),
                                    destination.accent.opacity(0.1)
                                ]
                                : [
                                    AuroraColors.pearl.opacity(0.72),
                                    AuroraColors.frost.opacity(0.56)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: isSelected ? AuroraDockMetrics.sideButtonVisualSize : AuroraDockMetrics.sideButtonVisualSize - 4,
                        height: isSelected ? AuroraDockMetrics.sideButtonVisualSize : AuroraDockMetrics.sideButtonVisualSize - 4
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(isSelected ? 0.16 : 0.08))
                            .blur(radius: isSelected ? 3 : 2)
                    )

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isSelected
                                ? [
                                    destination.accent.opacity(0.72),
                                    Color.white.opacity(0.8)
                                ]
                                : [
                                    AuroraColors.stroke.opacity(0.8),
                                    AuroraColors.hairline.opacity(0.9)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.1 : 0.9
                    )
                    .frame(width: isSelected ? 44 : 40, height: isSelected ? 44 : 40)

                AuroraGlyph(
                    kind: destination.glyphKind,
                    color: isSelected ? destination.accent : AuroraColors.textSecondary.opacity(0.92),
                    lineWidth: isSelected ? 2 : 1.65,
                    layoutStyle: .dock
                )
                .frame(width: 22, height: 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .shadow(
                color: isSelected ? destination.accent.opacity(0.18) : destination.accent.opacity(0.04),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 4
            )
        }
        .buttonStyle(AuroraDockPressStyle())
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
                    .fill(AuroraGradients.auroraSpectrum)
                    .frame(width: AuroraDockMetrics.centerButtonSize + 8, height: AuroraDockMetrics.centerButtonSize + 8)
                    .blur(radius: isSelected ? 16 : 10)
                    .opacity(isSelected ? 0.24 : 0.12)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [
                                    AuroraColors.auroraMint,
                                    AuroraColors.auroraCyan,
                                    AuroraColors.auroraViolet
                                ]
                                : [
                                    AuroraColors.pearl,
                                    AuroraColors.frost,
                                    AuroraColors.auroraCyan.opacity(0.22)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: AuroraDockMetrics.centerButtonSize, height: AuroraDockMetrics.centerButtonSize)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(isSelected ? 0.12 : 0.18))
                            .blur(radius: 4)
                    )

                Circle()
                    .stroke(isSelected ? Color.white.opacity(0.52) : Color.white.opacity(0.38), lineWidth: 1)
                    .frame(width: AuroraDockMetrics.centerButtonSize, height: AuroraDockMetrics.centerButtonSize)

                Circle()
                    .stroke(AuroraColors.auroraCyan.opacity(isSelected ? 0.32 : 0.2), lineWidth: 1)
                    .frame(width: AuroraDockMetrics.centerButtonSize + 14, height: AuroraDockMetrics.centerButtonSize + 14)

                Circle()
                    .stroke(AuroraColors.auroraMint.opacity(isSelected ? 0.3 : 0.16), lineWidth: 1)
                    .frame(
                        width: AuroraDockMetrics.centerButtonSize + (isSelected ? 26 : 18),
                        height: AuroraDockMetrics.centerButtonSize + (isSelected ? 26 : 18)
                    )

                AuroraGlyph(
                    kind: .saturn,
                    color: isSelected ? AuroraColors.obsidian : AuroraColors.textPrimary,
                    lineWidth: isSelected ? 2.2 : 2.0,
                    layoutStyle: .dock
                )
                .frame(width: 28, height: 28)
            }
            .shadow(
                color: isSelected
                    ? AuroraColors.auroraMint.opacity(0.22)
                    : AuroraColors.auroraCyan.opacity(0.1),
                radius: isSelected ? 18 : 10,
                x: 0,
                y: isSelected ? 10 : 7
            )
        }
        .buttonStyle(AuroraDockPressStyle())
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

private struct AuroraDockPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(AuroraMotion.transition, value: configuration.isPressed)
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

        switchToDestination(.home)
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
        switchToDestination(.palm)
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
        switchToDestination(.home)
    }
}

enum AppDestination: String, CaseIterable {
    case tarot
    case palm
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
            return .home
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
        case .palm:
            return String(localized: "tab.aurora.palm")
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
        case .palm:
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
        case .palm:
            return .palm
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
        case .palm:
            return "dock.palm"
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
            return .home
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
