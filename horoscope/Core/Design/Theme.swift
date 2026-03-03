import SwiftUI

// MARK: - Color Palette
enum MysticColors {
    // Primary
    static let deepPurple = Color(hex: "100825")
    static let cosmicBlue = Color(hex: "111B39")
    static let midnightTeal = Color(hex: "0A1426")
    static let voidBlack = Color(hex: "05030F")

    // Accent
    static let mysticGold = Color(hex: "D4B06A")
    static let neonLavender = Color(hex: "B197FF")
    static let auroraGreen = Color(hex: "6AE1C1")
    static let celestialPink = Color(hex: "E788B4")
    static let starWhite = Color(hex: "ECE7F8")
    static let nebulaBlue = Color(hex: "7BA5E8")
    static let stardust = Color(hex: "D7C9FF")
    static let transitOrange = Color(hex: "FFA94D")

    // Surface
    static let cardBackground = Color(hex: "120B24").opacity(0.78)
    static let cardBorder = Color(hex: "B89EEA").opacity(0.2)
    static let inputBackground = Color(hex: "0D0920").opacity(0.9)
    static let elevatedSurface = Color(hex: "1A1234").opacity(0.72)

    // Text
    static let textPrimary = Color(hex: "F4F0FF")
    static let textSecondary = Color(hex: "BCB2D6")
    static let textMuted = Color(hex: "7A6F97")
}

// MARK: - Arcane Editorial Tokens
enum MysticSurfaces {
    static let canvas = MysticColors.voidBlack
    static let cardBase = Color(hex: "110A22").opacity(0.84)
    static let cardGlassOverlay = Color.white.opacity(0.05)
    static let cardTintOverlay = Color(hex: "A88FF3").opacity(0.1)
    static let topBarBase = Color(hex: "0A0618").opacity(0.9)
    static let tabBarBase = Color(hex: "090514").opacity(0.93)
    static let tabBarHighlight = Color.white.opacity(0.06)
    static let separator = Color.white.opacity(0.1)
    static let inputField = Color(hex: "0D081C").opacity(0.94)
}

enum MysticTypographyRoles {
    static let hero = MysticFonts.title(34)
    static let section = MysticFonts.heading(20)
    static let cardTitle = MysticFonts.heading(17)
    static let cardBody = MysticFonts.body(14)
    static let metadata = MysticFonts.caption(12)
}

enum MysticElevation {
    static let cardShadowRadius: CGFloat = 18
    static let cardShadowYOffset: CGFloat = 8
    static let buttonShadowRadius: CGFloat = 14
    static let buttonShadowYOffset: CGFloat = 6
    static let floatingShadowRadius: CGFloat = 20
    static let floatingShadowYOffset: CGFloat = 8
}

// MARK: - Gradients
enum MysticGradients {
    static let cosmicBackground = LinearGradient(
        colors: [
            MysticColors.voidBlack,
            Color(hex: "100722"),
            Color(hex: "190F34"),
            Color(hex: "142248"),
            MysticColors.cosmicBlue,
            MysticColors.midnightTeal
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldShimmer = LinearGradient(
        colors: [
            Color(hex: "B98E4D"),
            Color(hex: "E5C17C"),
            Color(hex: "F2D89A"),
            Color(hex: "C39A5B")
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
            Color.white.opacity(0.09),
            Color.white.opacity(0.03),
            Color.white.opacity(0.01)
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
            Color(hex: "BE95F5"),
            MysticColors.neonLavender
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
enum MysticFonts {
    static func title(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func heading(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
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
