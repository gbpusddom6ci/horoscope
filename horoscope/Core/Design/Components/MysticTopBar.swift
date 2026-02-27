import SwiftUI

struct MysticTopBar<Trailing: View>: View {
    private let title: Text
    private let trailing: Trailing

    init(_ titleKey: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing) {
        self.title = Text(titleKey)
        self.trailing = trailing()
    }

    init(verbatim title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = Text(verbatim: title)
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: MysticSpacing.sm) {
            title
                .font(MysticFonts.heading(18))
                .foregroundColor(MysticColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: MysticSpacing.sm)

            trailing
                .frame(minWidth: MysticAccessibility.minimumTapTarget, minHeight: MysticAccessibility.minimumTapTarget)
        }
        .padding(.horizontal, MysticLayout.topBarHorizontalPadding)
        .padding(.top, MysticLayout.topBarVerticalPadding)
        .padding(.bottom, MysticLayout.topBarBottomPadding)
        .frame(minHeight: MysticLayout.topBarMinimumHeight, alignment: .center)
    }
}

extension MysticTopBar where Trailing == EmptyView {
    init(_ titleKey: LocalizedStringKey) {
        self.title = Text(titleKey)
        self.trailing = EmptyView()
    }

    init(verbatim title: String) {
        self.title = Text(verbatim: title)
        self.trailing = EmptyView()
    }
}
