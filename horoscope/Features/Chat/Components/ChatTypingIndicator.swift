import SwiftUI

struct ChatTypingIndicator: View {
    let isLoading: Bool
    let shouldShowSlowResponseNotice: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.xs) {
            HStack {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(MysticColors.neonLavender)
                            .frame(width: 6, height: 6)
                            .offset(y: isLoading ? -4 : 0)
                            .animation(
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                                value: isLoading
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(MysticColors.cardBackground)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: MysticRadius.lg,
                        bottomLeadingRadius: 4,
                        bottomTrailingRadius: MysticRadius.lg,
                        topTrailingRadius: MysticRadius.lg
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: MysticRadius.lg,
                        bottomLeadingRadius: 4,
                        bottomTrailingRadius: MysticRadius.lg,
                        topTrailingRadius: MysticRadius.lg
                    )
                    .stroke(MysticColors.cardBorder.opacity(0.5), lineWidth: 1)
                )

                Spacer()
            }

            if shouldShowSlowResponseNotice {
                Text("chat.loading.slow")
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.textMuted)
                    .padding(.leading, MysticSpacing.xs)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(localized: "chat.loading.reply")))
        .accessibilityIdentifier("chat.loading.reply")
    }
}
