import SwiftUI

// MARK: - Color Palette
enum MysticColors {
    // Primary
    static let deepPurple = AuroraColors.velvet
    static let cosmicBlue = AuroraColors.eclipse
    static let midnightTeal = AuroraColors.lagoon
    static let voidBlack = AuroraColors.obsidian

    // Accent
    static let mysticGold = AuroraColors.auroraMint
    static let neonLavender = AuroraColors.auroraViolet
    static let auroraGreen = AuroraColors.auroraMint
    static let celestialPink = AuroraColors.auroraRose
    static let starWhite = AuroraColors.polarWhite
    static let nebulaBlue = AuroraColors.auroraCyan
    static let stardust = AuroraColors.mist
    static let transitOrange = AuroraColors.auroraCyan

    // Surface
    static let cardBackground = AuroraColors.surfaceElevated.opacity(0.9)
    static let cardBorder = AuroraColors.stroke
    static let inputBackground = AuroraColors.surface.opacity(0.96)
    static let elevatedSurface = AuroraColors.surfaceElevated.opacity(0.84)

    // Text
    static let textPrimary = AuroraColors.textPrimary
    static let textSecondary = AuroraColors.textSecondary
    static let textMuted = AuroraColors.textMuted
}

// MARK: - Arcane Editorial Tokens
enum MysticSurfaces {
    static let canvas = AuroraColors.canvas
    static let cardBase = AuroraColors.surfaceElevated.opacity(0.92)
    static let cardGlassOverlay = Color.white.opacity(0.04)
    static let cardTintOverlay = AuroraColors.auroraViolet.opacity(0.08)
    static let topBarBase = AuroraColors.obsidian.opacity(0.9)
    static let tabBarBase = AuroraColors.surfaceElevated.opacity(0.94)
    static let tabBarHighlight = Color.white.opacity(0.06)
    static let separator = AuroraColors.hairline
    static let inputField = AuroraColors.surface.opacity(0.95)
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
    static let cosmicBackground = AuroraGradients.canvas
    static let goldShimmer = AuroraGradients.primaryCTA
    static let lavenderGlow = AuroraGradients.oracle
    static let auroraShift = AuroraGradients.auroraVeil
    static let cardGlass = AuroraGradients.silkHighlight
    static let celestialShimmer = AuroraGradients.auroraSpectrum
    static let cosmicRose = AuroraGradients.journal
}

// MARK: - Typography
enum MysticFonts {
    static func title(_ size: CGFloat = 30) -> Font {
        AuroraTypography.hero(size)
    }

    static func heading(_ size: CGFloat = 22) -> Font {
        AuroraTypography.section(size)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        AuroraTypography.body(size)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        AuroraTypography.body(size)
    }

    static func mystic(_ size: CGFloat = 20) -> Font {
        AuroraTypography.title(size)
    }

    static func mono(_ size: CGFloat = 14) -> Font {
        AuroraTypography.mono(size)
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
    static let buttonGlowDuration: Double = 1.8
    static let textGlowDuration: Double = 2.4
    static let cardHoverDuration: Double = 0.2
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.72
}

// MARK: - Effects
enum MysticEffects {
    static let buttonPressedScale: CGFloat = 0.96
    static let cardPressedScale: CGFloat = 0.975

    static let buttonGlowRadiusRest: CGFloat = 4
    static let buttonGlowRadiusActive: CGFloat = 12

    static let cardShadowRadius: CGFloat = 18
    static let cardShadowYOffset: CGFloat = 6

    static let compactTextLineSpacing: CGFloat = 3

    static let cardBlurRadius: CGFloat = 12
    static let topBarBlurRadius: CGFloat = 16
}
