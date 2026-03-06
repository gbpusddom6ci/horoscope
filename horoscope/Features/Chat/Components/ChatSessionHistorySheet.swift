import SwiftUI

struct ChatSessionHistorySheet: View {
    let sessions: [ChatSession]
    let onSelect: (ChatSession) -> Void
    let onDelete: (ChatSession) -> Void

    var body: some View {
        ZStack {
            AuroraBackdrop(style: .oracleMist)

            VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                Text("chat.session.history")
                    .font(AuroraTypography.title(24))
                    .foregroundColor(AuroraColors.textPrimary)

                if sessions.isEmpty {
                    VStack(spacing: AuroraSpacing.md) {
                        Spacer().frame(height: 40)
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(AuroraColors.textMuted)
                        Text("chat.session.no_history")
                            .font(AuroraTypography.body(15))
                            .foregroundColor(AuroraColors.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("chat.session.empty")
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: AuroraSpacing.sm) {
                            ForEach(sessions) { session in
                                Button {
                                    onSelect(session)
                                } label: {
                                    LumenCard(accent: contextColor(session.context)) {
                                        VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                                            HStack {
                                                Image(systemName: contextIcon(session.context))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(contextColor(session.context))
                                                Text(session.title)
                                                    .font(AuroraTypography.bodyStrong(15))
                                                    .foregroundColor(AuroraColors.textPrimary)
                                                    .lineLimit(1)
                                                Spacer()
                                                Text(session.updatedAt.relativeFormatted)
                                                    .font(AuroraTypography.mono(11))
                                                    .foregroundColor(AuroraColors.textMuted)
                                            }

                                            Text(session.lastMessagePreview)
                                                .font(AuroraTypography.body(13))
                                                .foregroundColor(AuroraColors.textSecondary)
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
            .padding(AuroraSpacing.md)
        }
    }

    private func contextColor(_ context: ChatContext) -> Color {
        switch context {
        case .general: return AuroraColors.auroraViolet
        case .natal: return AuroraColors.auroraCyan
        case .transit: return AuroraColors.auroraMint
        case .dream: return AuroraColors.auroraRose
        case .palmReading: return AuroraColors.auroraViolet
        case .tarot: return AuroraColors.auroraMint
        case .coffee: return AuroraColors.polarWhite
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
