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
        VStack(spacing: 0) {
            HStack(spacing: MysticSpacing.sm) {
                title
                    .font(AuroraTypography.title(24))
                    .foregroundColor(AuroraColors.textPrimary)
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
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            AuroraColors.obsidian.opacity(0.92),
                            AuroraColors.obsidian.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AuroraColors.surface.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AuroraColors.polarWhite.opacity(0.08),
                                            AuroraColors.auroraViolet.opacity(0.12),
                                            AuroraColors.auroraMint.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .padding(.horizontal, 8)
                }
            )

            Capsule(style: .continuous)
                .fill(AuroraGradients.auroraSpectrum)
                .frame(width: 88, height: 2)
                .opacity(0.45)
        }
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
