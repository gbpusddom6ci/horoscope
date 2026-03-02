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
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg, style: .continuous))
            .overlay(borderOverlay)
            .shadow(
                color: glowColor.opacity(glowAnimation ? 0.4 : 0.12),
                radius: glowAnimation ? MysticEffects.buttonGlowRadiusActive : MysticEffects.buttonGlowRadiusRest
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

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            MysticGradients.goldShimmer
        case .secondary:
            MysticColors.neonLavender.opacity(0.15)
        case .ghost:
            Color.clear
        case .danger:
            MysticColors.celestialPink.opacity(0.2)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: MysticRadius.lg, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [MysticColors.mysticGold.opacity(0.6), MysticColors.mysticGold.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        case .secondary:
            RoundedRectangle(cornerRadius: MysticRadius.lg, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [MysticColors.neonLavender.opacity(0.5), MysticColors.neonLavender.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        case .ghost:
            RoundedRectangle(cornerRadius: MysticRadius.lg, style: .continuous)
                .stroke(MysticColors.cardBorder, lineWidth: 0.8)
        case .danger:
            RoundedRectangle(cornerRadius: MysticRadius.lg, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [MysticColors.celestialPink.opacity(0.5), MysticColors.celestialPink.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return MysticColors.voidBlack
        case .secondary:
            return MysticColors.neonLavender
        case .ghost:
            return MysticColors.textPrimary
        case .danger:
            return MysticColors.celestialPink
        }
    }

    private var glowColor: Color {
        switch style {
        case .primary:
            return MysticColors.mysticGold
        case .secondary:
            return MysticColors.neonLavender
        case .ghost:
            return Color.clear
        case .danger:
            return MysticColors.celestialPink
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
                    .font(MysticFonts.body(16))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MysticButtonSize.regular.height)
            .background(
                ZStack {
                    Color.white.opacity(0.08)
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MysticRadius.lg, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.white.opacity(0.06), radius: 10, y: 4)
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
