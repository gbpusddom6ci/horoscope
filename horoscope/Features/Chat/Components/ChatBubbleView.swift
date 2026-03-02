import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: MysticSpacing.xs) {
                if !isUser {
                    HStack(spacing: MysticSpacing.xs) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MysticColors.mysticGold)
                        Text("chat.assistant.name")
                            .font(MysticFonts.caption(11))
                            .foregroundColor(MysticColors.mysticGold)
                    }
                }

                Text(message.content)
                    .font(MysticFonts.body(15))
                    .foregroundColor(isUser ? MysticColors.voidBlack : MysticColors.textPrimary)
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? AnyShapeStyle(MysticGradients.goldShimmer)
                            : AnyShapeStyle(MysticColors.cardBackground)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: MysticRadius.lg,
                            bottomLeadingRadius: isUser ? MysticRadius.lg : 4,
                            bottomTrailingRadius: isUser ? 4 : MysticRadius.lg,
                            topTrailingRadius: MysticRadius.lg
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: MysticRadius.lg,
                            bottomLeadingRadius: isUser ? MysticRadius.lg : 4,
                            bottomTrailingRadius: isUser ? 4 : MysticRadius.lg,
                            topTrailingRadius: MysticRadius.lg
                        )
                        .stroke(
                            isUser
                                ? MysticColors.mysticGold.opacity(0.2)
                                : MysticColors.cardBorder.opacity(0.5),
                            lineWidth: 1
                        )
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label(String(localized: "chat.bubble.copy"), systemImage: "doc.on.doc")
                        }

                        ShareLink(item: message.content) {
                            Label(String(localized: "chat.bubble.share"), systemImage: "square.and.arrow.up")
                        }
                    }

                Text(message.timestamp.formatted(as: "HH:mm"))
                    .font(MysticFonts.caption(10))
                    .foregroundColor(MysticColors.textMuted)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}
