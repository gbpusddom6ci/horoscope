import SwiftUI

struct MysticScreenScaffold<Trailing: View, Content: View>: View {
    private let starCount: Int
    private let titleKey: LocalizedStringKey?
    private let titleText: String?
    private let trailing: Trailing
    private let content: Content

    init(
        _ titleKey: LocalizedStringKey,
        starCount: Int = 40,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.starCount = starCount
        self.titleKey = titleKey
        self.titleText = nil
        self.trailing = trailing()
        self.content = content()
    }

    init(
        verbatim title: String,
        starCount: Int = 40,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.starCount = starCount
        self.titleKey = nil
        self.titleText = title
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        ZStack {
            StarField(starCount: starCount)

            VStack(spacing: 0) {
                if let titleKey {
                    MysticTopBar(titleKey) {
                        trailing
                    }
                } else if let titleText {
                    MysticTopBar(verbatim: titleText) {
                        trailing
                    }
                }

                content
            }
        }
    }
}

extension MysticScreenScaffold where Trailing == EmptyView {
    init(
        _ titleKey: LocalizedStringKey,
        starCount: Int = 40,
        @ViewBuilder content: () -> Content
    ) {
        self.starCount = starCount
        self.titleKey = titleKey
        self.titleText = nil
        self.trailing = EmptyView()
        self.content = content()
    }

    init(
        verbatim title: String,
        starCount: Int = 40,
        @ViewBuilder content: () -> Content
    ) {
        self.starCount = starCount
        self.titleKey = nil
        self.titleText = title
        self.trailing = EmptyView()
        self.content = content()
    }
}
