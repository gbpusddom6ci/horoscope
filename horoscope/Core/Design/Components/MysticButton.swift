import SwiftUI

// MARK: - Mystic Button Styles
enum MysticButtonStyle {
    case primary      // Gold gradient
    case secondary    // Lavender outline
    case ghost        // Transparent with border
    case danger       // Pink/red
}

struct MysticButton: View {
    let title: String
    let icon: String?
    let style: MysticButtonStyle
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var glowAnimation = false

    init(
        _ title: String,
        icon: String? = nil,
        style: MysticButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isLoading {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: MysticSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(title)
                        .font(MysticFonts.body(16))
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg))
            .overlay(borderOverlay)
            .shadow(color: glowColor.opacity(glowAnimation ? 0.4 : 0.1), radius: glowAnimation ? 12 : 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = false } }
        )
        .onAppear {
            if style == .primary {
                withAnimation(
                    .easeInOut(duration: 2)
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
            RoundedRectangle(cornerRadius: MysticRadius.lg)
                .stroke(MysticColors.mysticGold.opacity(0.5), lineWidth: 1)
        case .secondary:
            RoundedRectangle(cornerRadius: MysticRadius.lg)
                .stroke(MysticColors.neonLavender.opacity(0.4), lineWidth: 1.5)
        case .ghost:
            RoundedRectangle(cornerRadius: MysticRadius.lg)
                .stroke(MysticColors.cardBorder, lineWidth: 1)
        case .danger:
            RoundedRectangle(cornerRadius: MysticRadius.lg)
                .stroke(MysticColors.celestialPink.opacity(0.4), lineWidth: 1)
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
                Text("Apple ile Giriş Yap")
                    .font(MysticFonts.body(16))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MysticRadius.lg)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = false } }
        )
    }
}

#Preview {
    ZStack {
        StarField()
        VStack(spacing: 16) {
            MysticButton("Keşfet", icon: "sparkles", style: .primary) {}
            MysticButton("Devam Et", icon: "arrow.right", style: .secondary) {}
            MysticButton("Atla", style: .ghost) {}
            AppleSignInButton {}
        }
        .padding(24)
    }
}
