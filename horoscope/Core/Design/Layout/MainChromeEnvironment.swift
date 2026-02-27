import SwiftUI

struct MainChromeMetrics: Equatable {
    var tabBarVisible: Bool
    var tabBarHeight: CGFloat
    var floatingQuickActionSize: CGFloat
    var bottomSafeAreaInset: CGFloat

    var floatingQuickActionClearance: CGFloat {
        guard tabBarVisible else { return 0 }
        return MysticLayout.floatingQuickActionClearance(size: floatingQuickActionSize)
    }

    var contentBottomReservedSpace: CGFloat {
        MysticLayout.contentBottomReservedSpace(
            tabBarVisible: tabBarVisible,
            tabBarHeight: tabBarHeight,
            floatingQuickActionSize: floatingQuickActionSize
        )
    }

    static let hidden = MainChromeMetrics(
        tabBarVisible: false,
        tabBarHeight: 0,
        floatingQuickActionSize: 0,
        bottomSafeAreaInset: 0
    )
}

private struct MainChromeMetricsKey: EnvironmentKey {
    static let defaultValue: MainChromeMetrics = .hidden
}

extension EnvironmentValues {
    var mainChromeMetrics: MainChromeMetrics {
        get { self[MainChromeMetricsKey.self] }
        set { self[MainChromeMetricsKey.self] = newValue }
    }
}
