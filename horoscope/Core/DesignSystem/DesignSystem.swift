import SwiftUI

// MARK: - App Theme (delegates to MysticColors for single source of truth)
public struct AppTheme {
    public static let primary = MysticColors.neonLavender
    public static let accent = MysticColors.auroraGreen
    public static let success = MysticColors.auroraGreen

    // Adaptive backgrounds: aurora tint in light mode, deep space in dark mode
    public static let bgLight = Color(hex: "E8F0FF")
    public static let bgDark = MysticColors.voidBlack

    public static let background = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(bgDark)
            : UIColor(bgLight)
    })
}

// MARK: - Shared Tokens
public struct AppSpacing {
    public static let xs: CGFloat = MysticSpacing.xs
    public static let sm: CGFloat = MysticSpacing.sm
    public static let md: CGFloat = MysticSpacing.md
    public static let lg: CGFloat = MysticSpacing.lg
}

public struct AppRadius {
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
}

public struct AppAccessibility {
    public static let minimumTapTarget: CGFloat = MysticAccessibility.minimumTapTarget
}

public enum AppMotion {
    public static let pressSpring = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
}

// MARK: - Typography
public struct AppTypography {
    public static let titleExtraBold = Font.system(size: 34, weight: .heavy, design: .rounded)
    public static let titleBold = Font.system(size: 30, weight: .bold, design: .rounded)
    public static let headline = Font.system(size: 22, weight: .semibold, design: .rounded)
    public static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    public static let captionMedium = Font.system(size: 13, weight: .medium, design: .rounded)

    public static let bodyLineSpacing: CGFloat = AppSpacing.sm
}

private struct PremiumTextModifier: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    public func premiumText(
        font: Font = AppTypography.body,
        color: Color = .primary,
        lineSpacing: CGFloat = AppTypography.bodyLineSpacing
    ) -> some View {
        modifier(PremiumTextModifier(font: font, color: color, lineSpacing: lineSpacing))
    }
}

// MARK: - GlassCard Component (Liquid Glass)
public struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var content: Content

    public init(cornerRadius: CGFloat = AppRadius.xl, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(AppSpacing.lg)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Button Styles
public struct BigGlowingButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppAccessibility.minimumTapTarget)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .shadow(color: AppTheme.primary.opacity(0.4), radius: configuration.isPressed ? 6 : 16, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppMotion.pressSpring, value: configuration.isPressed)
    }
}

public struct SecondaryPillButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.captionMedium)
            .foregroundColor(.primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(minHeight: AppAccessibility.minimumTapTarget)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppMotion.pressSpring, value: configuration.isPressed)
    }
}
