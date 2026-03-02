import SwiftUI

struct ChatEmptyStateView: View {
    @Binding var inputText: String
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: MysticSpacing.md) {
            Spacer().frame(height: 60)

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(MysticGradients.lavenderGlow)
                .shadow(color: MysticColors.neonLavender.opacity(0.4), radius: 12)
                .shadow(color: MysticColors.neonLavender.opacity(0.15), radius: 24)

            VStack(spacing: MysticSpacing.sm) {
                Text("chat.empty.title")
                    .font(MysticFonts.heading(22))
                    .foregroundColor(MysticColors.textPrimary)

                Text("chat.empty.subtitle")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.xl)
            }

            VStack(spacing: MysticSpacing.sm) {
                quickPrompt(String(localized: "chat.quick.today"), icon: "sparkles")
                quickPrompt(String(localized: "chat.quick.natal"), icon: "moon.stars")
                quickPrompt(String(localized: "chat.quick.love"), icon: "heart.fill")
            }
        }
        .accessibilityIdentifier("chat.empty.state")
    }

    private func quickPrompt(_ text: String, icon: String) -> some View {
        Button {
            inputText = text
            onSend()
        } label: {
            HStack(spacing: MysticSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(MysticColors.mysticGold.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MysticColors.mysticGold)
                }
                Text(text)
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MysticColors.neonLavender.opacity(0.4))
            }
            .padding(.horizontal, MysticSpacing.sm + 2)
            .padding(.vertical, 10)
            .background(MysticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MysticRadius.md, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [MysticColors.mysticGold.opacity(0.2), MysticColors.cardBorder.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(String(localized: "chat.quick.hint")))
    }
}
