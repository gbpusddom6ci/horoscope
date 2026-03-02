import SwiftUI

struct ChatSessionHistorySheet: View {
    let sessions: [ChatSession]
    let onSelect: (ChatSession) -> Void
    let onDelete: (ChatSession) -> Void

    var body: some View {
        ZStack {
            MysticColors.voidBlack.ignoresSafeArea()
            StarField(starCount: 25, mode: .modal)

            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                Text("chat.session.history")
                    .font(MysticFonts.heading(20))
                    .foregroundColor(MysticColors.textPrimary)

                if sessions.isEmpty {
                    VStack(spacing: MysticSpacing.md) {
                        Spacer().frame(height: 40)
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(MysticColors.textMuted)
                        Text("chat.session.no_history")
                            .font(MysticFonts.body(15))
                            .foregroundColor(MysticColors.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("chat.session.empty")
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: MysticSpacing.sm) {
                            ForEach(sessions) { session in
                                Button {
                                    onSelect(session)
                                } label: {
                                    MysticCard(glowColor: contextColor(session.context)) {
                                        VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                                            HStack {
                                                Image(systemName: contextIcon(session.context))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(contextColor(session.context))
                                                Text(session.title)
                                                    .font(MysticFonts.body(15))
                                                    .foregroundColor(MysticColors.textPrimary)
                                                    .lineLimit(1)
                                                Spacer()
                                                Text(session.updatedAt.relativeFormatted)
                                                    .font(MysticFonts.caption(11))
                                                    .foregroundColor(MysticColors.textMuted)
                                            }

                                            Text(session.lastMessagePreview)
                                                .font(MysticFonts.caption(13))
                                                .foregroundColor(MysticColors.textSecondary)
                                                .lineLimit(2)
                                        }
                                        .frame(minHeight: MysticAccessibility.minimumTapTarget)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(session.title))
                                .accessibilityHint(Text(String(localized: "chat.context.select.hint")))
                                .accessibilityIdentifier("chat.session.\(session.id)")
                                .contextMenu {
                                    Button(role: .destructive) {
                                        onDelete(session)
                                    } label: {
                                        Label(String(localized: "common.delete"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(MysticSpacing.md)
        }
    }

    private func contextColor(_ context: ChatContext) -> Color {
        switch context {
        case .general: return MysticColors.neonLavender
        case .natal: return MysticColors.mysticGold
        case .transit: return MysticColors.auroraGreen
        case .dream: return MysticColors.celestialPink
        case .palmReading: return MysticColors.neonLavender
        case .tarot: return MysticColors.mysticGold
        case .coffee: return MysticColors.mysticGold
        }
    }

    private func contextIcon(_ context: ChatContext) -> String {
        switch context {
        case .general: return "sparkles"
        case .natal: return "moon.stars"
        case .transit: return "arrow.triangle.2.circlepath"
        case .dream: return "moon.zzz"
        case .palmReading: return "hand.raised"
        case .tarot: return "suit.diamond"
        case .coffee: return "cup.and.saucer"
        }
    }
}
