import SwiftUI

enum AuroraSurfaceLevel {
    case surface
    case elevated
    case luminous(Color)

    var fillStyle: AnyShapeStyle {
        switch self {
        case .surface:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AuroraColors.surface.opacity(0.92),
                        AuroraColors.secondaryCard.opacity(0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .elevated:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AuroraColors.surfaceElevated.opacity(0.96),
                        AuroraColors.cardBase.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .luminous(let accent):
            return AnyShapeStyle(AuroraGradients.cardWash(accent: accent))
        }
    }

    var borderColor: Color {
        switch self {
        case .surface:
            return AuroraColors.stroke
        case .elevated:
            return AuroraColors.polarWhite.opacity(0.1)
        case .luminous(let accent):
            return accent.opacity(0.36)
        }
    }
}

struct AuroraTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    var accent: Color

    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        accent: Color = AuroraColors.auroraViolet
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.accent = accent
    }

    var body: some View {
        HStack(spacing: AuroraSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AuroraColors.textMuted)
                    .frame(width: 22)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(AuroraTypography.body(15))
            .foregroundColor(AuroraColors.textPrimary)
            .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, AuroraSpacing.md)
        .frame(minHeight: 54)
        .background(
            RoundedRectangle(cornerRadius: AuroraRadius.md, style: .continuous)
                .fill(AuroraSurfaceLevel.elevated.fillStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: AuroraRadius.md, style: .continuous)
                        .fill(AuroraGradients.cardWash(accent: accent))
                        .opacity(0.26)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AuroraRadius.md, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [accent.opacity(0.28), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct AuroraSegmentedPill: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let accent: Color

    init(_ title: String, icon: String? = nil, isSelected: Bool = false, accent: Color = AuroraColors.auroraViolet) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.accent = accent
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(title)
                .font(AuroraTypography.bodyStrong(13))
        }
        .foregroundColor(isSelected ? AuroraColors.obsidian : AuroraColors.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? AnyShapeStyle(AuroraGradients.chipFill(accent: accent)) : AuroraSurfaceLevel.elevated.fillStyle)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.18) : AuroraSurfaceLevel.elevated.borderColor, lineWidth: 1)
        )
        .shadow(color: isSelected ? accent.opacity(0.2) : .clear, radius: 10, x: 0, y: 6)
    }
}

struct AuroraInputBar: View {
    @Binding var inputText: String
    let isLoading: Bool
    let inlineStatusMessage: String?
    let canSend: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AuroraSpacing.sm) {
                HStack {
                    TextField(String(localized: "chat.input.placeholder"), text: $inputText, axis: .vertical)
                        .font(AuroraTypography.body(15))
                        .foregroundColor(AuroraColors.textPrimary)
                        .lineLimit(1...5)
                        .submitLabel(.send)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .onSubmit {
                            if canSend {
                                onSend()
                            }
                        }
                        .accessibilityIdentifier("chat.input.field")
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AuroraSurfaceLevel.elevated.fillStyle)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(AuroraGradients.cardWash(accent: canSend ? AuroraColors.auroraMint : AuroraColors.auroraViolet))
                                .opacity(canSend ? 0.24 : 0.1)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            isLoading
                                ? AuroraColors.auroraViolet.opacity(0.46)
                                : (canSend ? AuroraColors.auroraMint.opacity(0.42) : AuroraColors.stroke),
                            lineWidth: 0.9
                        )
                )

                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(canSend ? AnyShapeStyle(AuroraGradients.primaryCTA) : AnyShapeStyle(AuroraSurfaceLevel.elevated.fillStyle))
                            .frame(width: 46, height: 46)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(canSend ? 0.22 : 0.08), lineWidth: 1)
                            )

                        if isLoading {
                            ProgressView()
                                .tint(AuroraColors.obsidian)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(canSend ? AuroraColors.obsidian : AuroraColors.textMuted)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel(Text(String(localized: "chat.send")))
                .accessibilityHint(Text(String(localized: "chat.send.hint")))
                .accessibilityIdentifier("chat.send.button")
            }
            .padding(.horizontal, AuroraSpacing.md)
            .padding(.top, 10)
            .padding(.bottom, inlineStatusMessage == nil ? 12 : 8)

            if let inlineStatusMessage {
                Text(inlineStatusMessage)
                    .font(AuroraTypography.mono(11))
                    .foregroundColor(AuroraColors.auroraMint)
                    .padding(.horizontal, AuroraSpacing.md)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(
            ZStack {
                AuroraColors.obsidian.opacity(0.9)
                LinearGradient(
                    colors: [Color.white.opacity(0.03), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AuroraColors.hairline)
                .frame(height: 1)
        }
    }
}
