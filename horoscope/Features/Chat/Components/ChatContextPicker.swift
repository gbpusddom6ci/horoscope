import SwiftUI

struct ChatContextPicker: View {
    @Binding var chatContext: ChatContext
    @Binding var showMoreContexts: Bool

    private var primaryContexts: [ChatContext] {
        [.general, .natal, .transit]
    }

    private var additionalContexts: [ChatContext] {
        [.dream, .palmReading, .tarot]
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MysticSpacing.sm) {
                ForEach(primaryContexts, id: \.self) { context in
                    contextChip(context)
                }
                moreContextsButton
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, MysticSpacing.sm)
        }
        .frame(minHeight: 58)
        .background(
            LinearGradient(
                colors: [
                    MysticColors.neonLavender.opacity(0.06),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showMoreContexts) {
            moreContextsSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func contextChip(_ context: ChatContext) -> some View {
        let title = titleForContext(context)
        let icon = context.iconName

        return Button {
            chatContext = context
        } label: {
            HStack(spacing: MysticSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(MysticTypographyRoles.metadata)
            }
            .padding(.horizontal, MysticSpacing.sm)
            .padding(.vertical, 8)
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
            .foregroundColor(chatContext == context ? MysticColors.voidBlack : MysticColors.textSecondary)
            .background(
                chatContext == context
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [context.themeColor.opacity(0.85), MysticColors.mysticGold.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(MysticColors.cardBackground.opacity(0.88))
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        chatContext == context
                            ? Color.white.opacity(0.35)
                            : MysticColors.cardBorder,
                        lineWidth: 0.8
                    )
            )
            .shadow(
                color: chatContext == context ? context.themeColor.opacity(0.2) : Color.clear,
                radius: 6, y: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(String(localized: "chat.context.select.hint")))
    }

    private var moreContextsButton: some View {
        let isAdditionalContextSelected = additionalContexts.contains(chatContext)

        return Button {
            showMoreContexts = true
        } label: {
            HStack(spacing: MysticSpacing.xs) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 12))
                Text("chat.context.more")
                    .font(MysticFonts.caption(12))
            }
            .padding(.horizontal, MysticSpacing.sm)
            .padding(.vertical, 8)
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
            .foregroundColor(isAdditionalContextSelected ? MysticColors.voidBlack : MysticColors.textSecondary)
            .background(
                isAdditionalContextSelected
                    ? AnyShapeStyle(MysticGradients.goldShimmer)
                    : AnyShapeStyle(MysticColors.cardBackground)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isAdditionalContextSelected
                            ? MysticColors.mysticGold.opacity(0.4)
                            : MysticColors.cardBorder,
                        lineWidth: 0.8
                    )
            )
            .shadow(
                color: isAdditionalContextSelected ? MysticColors.mysticGold.opacity(0.15) : Color.clear,
                radius: 6, y: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "chat.context.more")))
        .accessibilityHint(Text(String(localized: "chat.context.more.hint")))
        .accessibilityIdentifier("chat.context.more")
    }

    private var moreContextsSheet: some View {
        ZStack {
            MysticColors.voidBlack.ignoresSafeArea()
            StarField(starCount: 25, mode: .modal)

            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                Text("chat.context.sheet.title")
                    .font(MysticFonts.heading(20))
                    .foregroundColor(MysticColors.textPrimary)

                ForEach(additionalContexts, id: \.self) { context in
                    Button {
                        chatContext = context
                        showMoreContexts = false
                    } label: {
                        MysticCard(glowColor: chatContext == context ? MysticColors.mysticGold : MysticColors.neonLavender) {
                            HStack(spacing: MysticSpacing.md) {
                                Image(systemName: iconForContext(context))
                                    .font(.system(size: 16))
                                    .foregroundColor(chatContext == context ? context.themeColor : MysticColors.textSecondary)
                                    .frame(width: 24)

                                Text(titleForContext(context))
                                    .font(MysticTypographyRoles.cardBody)
                                    .foregroundColor(MysticColors.textPrimary)

                                Spacer()

                                if chatContext == context {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(context.themeColor)
                                }
                            }
                            .frame(minHeight: MysticAccessibility.minimumTapTarget)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(titleForContext(context)))
                    .accessibilityHint(Text(String(localized: "chat.context.select.hint")))
                }

                Spacer(minLength: 0)
            }
            .padding(MysticSpacing.md)
        }
    }

    private func titleForContext(_ context: ChatContext) -> String {
        switch context {
        case .general:
            return String(localized: "chat.context.general")
        case .natal:
            return String(localized: "chat.context.natal")
        case .transit:
            return String(localized: "chat.context.transit")
        case .dream:
            return String(localized: "chat.context.dream")
        case .palmReading:
            return String(localized: "chat.context.palm")
        case .tarot:
            return String(localized: "chat.context.tarot")
        case .coffee:
            return String(localized: "chat.context.coffee")
        }
    }

    private func iconForContext(_ context: ChatContext) -> String {
        context.iconName
    }
}
