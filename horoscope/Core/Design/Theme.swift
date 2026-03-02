import SwiftUI

// MARK: - Color Palette
enum MysticColors {
    // Primary
    static let deepPurple = Color(hex: "0F0728")
    static let cosmicBlue = Color(hex: "0A1A3A")
    static let midnightTeal = Color(hex: "071428")
    static let voidBlack = Color(hex: "050312")

    // Accent
    static let mysticGold = Color(hex: "D4A843")
    static let neonLavender = Color(hex: "A78BFA")
    static let auroraGreen = Color(hex: "34D399")
    static let celestialPink = Color(hex: "F472B6")
    static let starWhite = Color(hex: "E2DFEF")
    static let nebulaBlue = Color(hex: "60A5FA")
    static let stardust = Color(hex: "C4B5FD")
    static let transitOrange = Color(hex: "FF9800")

    // Surface
    static let cardBackground = Color(hex: "130D30").opacity(0.65)
    static let cardBorder = Color(hex: "A78BFA").opacity(0.15)
    static let inputBackground = Color(hex: "0A0620").opacity(0.85)
    static let elevatedSurface = Color(hex: "1A1245").opacity(0.5)

    // Text
    static let textPrimary = Color(hex: "F0ECFF")
    static let textSecondary = Color(hex: "A89EC8")
    static let textMuted = Color(hex: "635A80")
}

// MARK: - Gradients
enum MysticGradients {
    static let cosmicBackground = LinearGradient(
        colors: [
            MysticColors.voidBlack,
            Color(hex: "0B0522"),
            MysticColors.deepPurple,
            Color(hex: "0D1535"),
            MysticColors.cosmicBlue,
            MysticColors.midnightTeal
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldShimmer = LinearGradient(
        colors: [
            Color(hex: "D4A843"),
            Color(hex: "F0D060"),
            Color(hex: "E8C34A"),
            Color(hex: "D4A843")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let lavenderGlow = LinearGradient(
        colors: [
            MysticColors.neonLavender.opacity(0.7),
            MysticColors.stardust.opacity(0.5),
            MysticColors.celestialPink.opacity(0.5),
            MysticColors.neonLavender.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let auroraShift = LinearGradient(
        colors: [
            MysticColors.neonLavender,
            MysticColors.nebulaBlue,
            MysticColors.auroraGreen,
            MysticColors.celestialPink
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGlass = LinearGradient(
        colors: [
            Color.white.opacity(0.10),
            Color.white.opacity(0.04),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let celestialShimmer = LinearGradient(
        colors: [
            MysticColors.neonLavender,
            MysticColors.nebulaBlue,
            MysticColors.stardust
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cosmicRose = LinearGradient(
        colors: [
            MysticColors.celestialPink,
            Color(hex: "C084FC"),
            MysticColors.neonLavender
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
enum MysticFonts {
    static func title(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func heading(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func mystic(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .light, design: .serif)
    }

    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Spacing
enum MysticSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum MysticRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let full: CGFloat = 100
}

// MARK: - Accessibility
enum MysticAccessibility {
    static let minimumTapTarget: CGFloat = 44
}

// MARK: - Motion
enum MysticMotion {
    static let quickPressDuration: Double = 0.12
    static let buttonGlowDuration: Double = 2.5
    static let textGlowDuration: Double = 3.0
    static let cardHoverDuration: Double = 0.2
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.72
}

// MARK: - Effects
enum MysticEffects {
    static let buttonPressedScale: CGFloat = 0.96
    static let cardPressedScale: CGFloat = 0.975

    static let buttonGlowRadiusRest: CGFloat = 6
    static let buttonGlowRadiusActive: CGFloat = 16

    static let cardShadowRadius: CGFloat = 16
    static let cardShadowYOffset: CGFloat = 6

    static let compactTextLineSpacing: CGFloat = 3

    static let cardBlurRadius: CGFloat = 20
    static let topBarBlurRadius: CGFloat = 24
}
