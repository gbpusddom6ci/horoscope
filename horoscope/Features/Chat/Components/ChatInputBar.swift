import SwiftUI

struct ChatInputBar: View {
    @Binding var inputText: String
    let isLoading: Bool
    let inlineStatusMessage: String?
    let canSend: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 1)
                .accessibilityElement()
                .accessibilityIdentifier("chat.composer")

            Divider()
                .background(MysticColors.cardBorder.opacity(0.5))

            HStack(spacing: MysticSpacing.sm) {
                HStack {
                    TextField(String(localized: "chat.input.placeholder"), text: $inputText, axis: .vertical)
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textPrimary)
                        .lineLimit(1...5)
                        .submitLabel(.send)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .onSubmit {
                            if canSend {
                                onSend()
                            }
                        }
                        .accessibilityIdentifier("chat.input.field")
                }
                .background(MysticSurfaces.inputField)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            isLoading
                                ? MysticColors.neonLavender.opacity(0.5)
                                : (canSend ? MysticColors.mysticGold.opacity(0.4) : MysticColors.cardBorder.opacity(0.25)),
                            lineWidth: 0.8
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: canSend)
                .animation(.easeInOut(duration: 0.15), value: isLoading)

                Button {
                    onSend()
                } label: {
                    ZStack {
                        if isLoading {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [MysticColors.neonLavender.opacity(0.3), MysticColors.neonLavender.opacity(0.08)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 22
                                    )
                                )
                                .frame(width: 42, height: 42)

                            ProgressView()
                                .tint(MysticColors.stardust)
                        } else {
                            Circle()
                                .fill(
                                    canSend
                                        ? AnyShapeStyle(MysticGradients.goldShimmer)
                                        : AnyShapeStyle(MysticColors.textMuted.opacity(0.12))
                                )
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(canSend ? 0.3 : 0.08), lineWidth: 0.8)
                                )

                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(canSend ? MysticColors.voidBlack : MysticColors.textSecondary)
                        }
                    }
                }
                .disabled(!canSend)
                .frame(
                    minWidth: MysticAccessibility.minimumTapTarget,
                    minHeight: MysticAccessibility.minimumTapTarget
                )
                .accessibilityLabel(Text(String(localized: "chat.send")))
                .accessibilityHint(Text(String(localized: "chat.send.hint")))
                .accessibilityIdentifier("chat.send.button")
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, 8)

            if let inlineStatusMessage {
                Text(inlineStatusMessage)
                    .font(MysticTypographyRoles.metadata)
                    .foregroundColor(MysticColors.auroraGreen)
                    .padding(.bottom, 6)
            }
        }
        .background(
            ZStack {
                MysticColors.voidBlack.opacity(0.95)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.04), Color.white.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        )
    }
}
