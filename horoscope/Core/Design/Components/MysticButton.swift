import SwiftUI

// MARK: - Mystic Button Styles
enum MysticButtonStyle {
    case primary      // Gold gradient
    case secondary    // Lavender outline
    case ghost        // Transparent with border
    case danger       // Pink/red
}

enum MysticButtonSize {
    case regular
    case compact

    var height: CGFloat {
        switch self {
        case .regular:
            return 54
        case .compact:
            return MysticAccessibility.minimumTapTarget
        }
    }

    var font: Font {
        switch self {
        case .regular:
            return MysticFonts.body(16)
        case .compact:
            return MysticFonts.body(14)
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .regular:
            return 18
        case .compact:
            return 15
        }
    }
}

struct MysticButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let icon: String?
    let style: MysticButtonStyle
    let size: MysticButtonSize
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var glowAnimation = false

    init(
        _ title: String,
        icon: String? = nil,
        style: MysticButtonStyle = .primary,
        size: MysticButtonSize = .regular,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    private var canInteract: Bool {
        isEnabled && !isLoading
    }

    private var cornerRadius: CGFloat {
        size == .regular ? 24 : 20
    }

    var body: some View {
        Button(action: {
            guard canInteract else { return }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: MysticSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(buttonSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .shadow(
                color: glowColor.opacity(glowAnimation ? 0.24 : 0.12),
                radius: glowAnimation ? MysticEffects.buttonGlowRadiusActive : 12,
                y: 10
            )
            .scaleEffect((isPressed && !reduceMotion && canInteract) ? MysticEffects.buttonPressedScale : 1.0)
            .opacity(canInteract ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!canInteract)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard canInteract else { return }
                    if reduceMotion {
                        isPressed = true
                    } else {
                        withAnimation(.spring(response: MysticMotion.springResponse, dampingFraction: MysticMotion.springDamping)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    guard canInteract else { return }
                    if reduceMotion {
                        isPressed = false
                    } else {
                        withAnimation(.spring(response: MysticMotion.springResponse, dampingFraction: MysticMotion.springDamping)) { isPressed = false }
                    }
                }
        )
        .onAppear {
            if style == .primary && !reduceMotion {
                withAnimation(
                    .easeInOut(duration: MysticMotion.buttonGlowDuration)
                    .repeatForever(autoreverses: true)
                ) {
                    glowAnimation = true
                }
            }
        }
    }

    // MARK: - Style Computed Properties

    private var buttonSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fillStyle)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AuroraGradients.silkHighlight)
                .opacity(style == .ghost ? 0.35 : 0.85)

            if style != .ghost {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AuroraGradients.cardWash(accent: glowColor))
                    .opacity(style == .primary ? 0.22 : 0.16)
            }
        }
    }

    private var fillStyle: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(AuroraGradients.primaryCTA)
        case .secondary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AuroraColors.surfaceElevated.opacity(0.98),
                        AuroraColors.cardBase.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .ghost:
            return AnyShapeStyle(AuroraColors.surface.opacity(0.38))
        case .danger:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AuroraColors.surfaceElevated.opacity(0.94),
                        AuroraColors.auroraRose.opacity(0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(borderGradient, lineWidth: style == .ghost ? 0.9 : 1)
    }

    private var borderGradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [Color.white.opacity(0.4), AuroraColors.auroraMint.opacity(0.26)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [Color.white.opacity(0.18), AuroraColors.auroraViolet.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ghost:
            return LinearGradient(
                colors: [AuroraColors.stroke, Color.white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .danger:
            return LinearGradient(
                colors: [AuroraColors.auroraRose.opacity(0.52), AuroraColors.auroraRose.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return AuroraColors.obsidian
        case .secondary:
            return AuroraColors.textPrimary
        case .ghost:
            return AuroraColors.textSecondary
        case .danger:
            return AuroraColors.auroraRose
        }
    }

    private var glowColor: Color {
        switch style {
        case .primary:
            return AuroraColors.auroraMint
        case .secondary:
            return AuroraColors.auroraViolet
        case .ghost:
            return AuroraColors.auroraCyan
        case .danger:
            return AuroraColors.auroraRose
        }
    }
}

// MARK: - Apple Sign In Button
struct AppleSignInButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: MysticSpacing.md) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                Text("auth.apple_signin")
                    .font(AuroraTypography.bodyStrong(16))
            }
            .foregroundColor(AuroraColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: MysticButtonSize.regular.height)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AuroraRadius.md, style: .continuous)
                        .fill(AuroraColors.surfaceElevated.opacity(0.94))

                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.015)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AuroraRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuroraRadius.md, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), AuroraColors.stroke],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.28), radius: 14, y: 10)
            .scaleEffect((isPressed && !reduceMotion) ? MysticEffects.buttonPressedScale : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if reduceMotion {
                        isPressed = true
                    } else {
                        withAnimation(.easeInOut(duration: MysticMotion.quickPressDuration)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    if reduceMotion {
                        isPressed = false
                    } else {
                        withAnimation(.easeInOut(duration: MysticMotion.quickPressDuration)) { isPressed = false }
                    }
                }
        )
    }
}

#Preview {
    ZStack {
        StarField()
        VStack(spacing: 16) {
            MysticButton("Explore", icon: "sparkles", style: .primary) {}
            MysticButton("Continue", icon: "arrow.right", style: .secondary) {}
            MysticButton("Skip", style: .ghost, size: .compact) {}
            AppleSignInButton {}
        }
        .padding(24)
    }
}
