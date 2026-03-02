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
                .shadow(color: MysticColors.neonLavender.opacity(0.4), radius: 10)

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
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(MysticColors.mysticGold)
                Text(text)
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MysticColors.neonLavender.opacity(0.5))
            }
            .padding(.horizontal, MysticSpacing.sm)
            .padding(.vertical, 8)
            .background(MysticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MysticRadius.md)
                    .stroke(MysticColors.mysticGold.opacity(0.22), lineWidth: 1)
            )
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(String(localized: "chat.quick.hint")))
    }
}
