import SwiftUI

enum MysticContentBottomInsetStrategy {
    case none
    case fixed(CGFloat)
    case chromeAware(extra: CGFloat = MysticSpacing.md)

    func resolve(using chromeMetrics: MainChromeMetrics) -> CGFloat {
        switch self {
        case .none:
            return 0
        case .fixed(let value):
            return max(0, value)
        case .chromeAware(let extra):
            return chromeMetrics.contentBottomReservedSpace + max(0, extra)
        }
    }
}

struct MysticScreenScaffold<Trailing: View, Content: View>: View {
    @Environment(\.mainChromeMetrics) private var chromeMetrics

    private let showsTopBar: Bool
    private let showsBackground: Bool
    private let starCount: Int
    private let starMode: StarFieldMode
    private let isAnimatedBackground: Bool
    private let titleKey: LocalizedStringKey?
    private let titleText: String?
    private let topBarTrailing: Trailing
    private let usesScrollView: Bool
    private let contentHorizontalPadding: CGFloat
    private let contentBottomInsetStrategy: MysticContentBottomInsetStrategy
    private let content: Content

    init(
        _ titleKey: LocalizedStringKey,
        showsTopBar: Bool = true,
        showsBackground: Bool = true,
        starCount: Int = 40,
        starMode: StarFieldMode = .screen,
        isAnimatedBackground: Bool = true,
        usesScrollView: Bool = false,
        contentHorizontalPadding: CGFloat = 0,
        contentBottomInsetStrategy: MysticContentBottomInsetStrategy = .none,
        @ViewBuilder topBarTrailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.showsTopBar = showsTopBar
        self.showsBackground = showsBackground
        self.starCount = starCount
        self.starMode = starMode
        self.isAnimatedBackground = isAnimatedBackground
        self.titleKey = titleKey
        self.titleText = nil
        self.topBarTrailing = topBarTrailing()
        self.usesScrollView = usesScrollView
        self.contentHorizontalPadding = contentHorizontalPadding
        self.contentBottomInsetStrategy = contentBottomInsetStrategy
        self.content = content()
    }

    init(
        verbatim title: String,
        showsTopBar: Bool = true,
        showsBackground: Bool = true,
        starCount: Int = 40,
        starMode: StarFieldMode = .screen,
        isAnimatedBackground: Bool = true,
        usesScrollView: Bool = false,
        contentHorizontalPadding: CGFloat = 0,
        contentBottomInsetStrategy: MysticContentBottomInsetStrategy = .none,
        @ViewBuilder topBarTrailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.showsTopBar = showsTopBar
        self.showsBackground = showsBackground
        self.starCount = starCount
        self.starMode = starMode
        self.isAnimatedBackground = isAnimatedBackground
        self.titleKey = nil
        self.titleText = title
        self.topBarTrailing = topBarTrailing()
        self.usesScrollView = usesScrollView
        self.contentHorizontalPadding = contentHorizontalPadding
        self.contentBottomInsetStrategy = contentBottomInsetStrategy
        self.content = content()
    }

    var body: some View {
        ZStack {
            if showsBackground {
                StarField(
                    starCount: starCount,
                    mode: starMode,
                    isAnimated: isAnimatedBackground
                )
            }

            VStack(spacing: 0) {
                if showsTopBar {
                    topBar
                }

                if usesScrollView {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            content

                            if bottomInset > 0 {
                                Color.clear
                                    .frame(height: bottomInset)
                            }
                        }
                        .padding(.horizontal, contentHorizontalPadding)
                    }
                } else {
                    content
                        .padding(.horizontal, contentHorizontalPadding)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var topBar: some View {
        if let titleKey {
            MysticTopBar(titleKey) {
                topBarTrailing
            }
        } else if let titleText {
            MysticTopBar(verbatim: titleText) {
                topBarTrailing
            }
        }
    }

    private var bottomInset: CGFloat {
        contentBottomInsetStrategy.resolve(using: chromeMetrics)
    }
}

extension MysticScreenScaffold where Trailing == EmptyView {
    init(
        _ titleKey: LocalizedStringKey,
        showsTopBar: Bool = true,
        showsBackground: Bool = true,
        starCount: Int = 40,
        starMode: StarFieldMode = .screen,
        isAnimatedBackground: Bool = true,
        usesScrollView: Bool = false,
        contentHorizontalPadding: CGFloat = 0,
        contentBottomInsetStrategy: MysticContentBottomInsetStrategy = .none,
        @ViewBuilder content: () -> Content
    ) {
        self.showsTopBar = showsTopBar
        self.showsBackground = showsBackground
        self.starCount = starCount
        self.starMode = starMode
        self.isAnimatedBackground = isAnimatedBackground
        self.titleKey = titleKey
        self.titleText = nil
        self.topBarTrailing = EmptyView()
        self.usesScrollView = usesScrollView
        self.contentHorizontalPadding = contentHorizontalPadding
        self.contentBottomInsetStrategy = contentBottomInsetStrategy
        self.content = content()
    }

    init(
        verbatim title: String,
        showsTopBar: Bool = true,
        showsBackground: Bool = true,
        starCount: Int = 40,
        starMode: StarFieldMode = .screen,
        isAnimatedBackground: Bool = true,
        usesScrollView: Bool = false,
        contentHorizontalPadding: CGFloat = 0,
        contentBottomInsetStrategy: MysticContentBottomInsetStrategy = .none,
        @ViewBuilder content: () -> Content
    ) {
        self.showsTopBar = showsTopBar
        self.showsBackground = showsBackground
        self.starCount = starCount
        self.starMode = starMode
        self.isAnimatedBackground = isAnimatedBackground
        self.titleKey = nil
        self.titleText = title
        self.topBarTrailing = EmptyView()
        self.usesScrollView = usesScrollView
        self.contentHorizontalPadding = contentHorizontalPadding
        self.contentBottomInsetStrategy = contentBottomInsetStrategy
        self.content = content()
    }
}
