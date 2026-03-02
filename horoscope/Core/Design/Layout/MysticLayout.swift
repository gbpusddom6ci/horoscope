import SwiftUI

enum MysticLayout {
    static let screenHorizontalPadding: CGFloat = MysticSpacing.md
    static let topBarHorizontalPadding: CGFloat = MysticSpacing.md
    static let topBarVerticalPadding: CGFloat = 10
    static let topBarBottomPadding: CGFloat = 10
    static let topBarMinimumHeight: CGFloat = 52

    static let tabBarIconFrame: CGFloat = 40
    static let tabBarLabelHeight: CGFloat = 18
    static let tabBarVisualTopPadding: CGFloat = 6
    static let tabBarVisualBottomPadding: CGFloat = 4

    static let floatingQuickActionSize: CGFloat = 56
    static let floatingQuickActionBottomSpacing: CGFloat = 6
    static let floatingQuickActionLift: CGFloat = 48
    static let floatingQuickActionContentClearanceFactor: CGFloat = 0.25

    static let contentBottomExtraSpacing: CGFloat = MysticSpacing.md

    static func tabBarBottomPadding(bottomSafeArea: CGFloat) -> CGFloat {
        // `safeAreaInset(edge: .bottom)` already places the custom tab bar in the
        // safe-area region. Adding `bottomSafeArea` again causes the bar to float
        // too high and breaks UITest bottom-edge assertions.
        _ = bottomSafeArea
        return tabBarVisualBottomPadding
    }

    static func tabBarHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let safeAreaBottom = tabBarBottomPadding(bottomSafeArea: bottomSafeArea)
        return tabBarVisualTopPadding
            + tabBarIconFrame
            + tabBarLabelHeight
            + safeAreaBottom
    }

    static func floatingQuickActionClearance(size: CGFloat) -> CGFloat {
        max(0, size - floatingQuickActionLift)
    }

    static func contentBottomReservedSpace(
        tabBarVisible: Bool,
        tabBarHeight: CGFloat,
        floatingQuickActionSize: CGFloat
    ) -> CGFloat {
        guard tabBarVisible else {
            return contentBottomExtraSpacing
        }

        let quickClearance = floatingQuickActionClearance(size: floatingQuickActionSize) * floatingQuickActionContentClearanceFactor
        return tabBarHeight + contentBottomExtraSpacing + quickClearance
    }
}
