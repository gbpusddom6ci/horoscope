import SwiftUI
import UIKit

enum AuroraColors {
    static let obsidian = Color(hex: "040814")
    static let midnight = Color(hex: "0A1020")
    static let eclipse = Color(hex: "11182D")
    static let velvet = Color(hex: "140D28")
    static let nebula = Color(hex: "191334")
    static let lagoon = Color(hex: "0A2231")
    static let auroraMint = Color(hex: "5EF0C3")
    static let auroraCyan = Color(hex: "7BE7FF")
    static let auroraViolet = Color(hex: "9C8CFF")
    static let auroraRose = Color(hex: "FF93D1")
    static let polarWhite = Color(hex: "EAF7FF")
    static let mist = Color(hex: "B7C7F0")
    static let shadow = Color.black.opacity(0.45)

    static let canvas = obsidian
    static let cardBase = nebula.opacity(0.8)
    static let secondaryCard = midnight.opacity(0.78)
    static let surface = eclipse.opacity(0.72)
    static let surfaceElevated = velvet.opacity(0.84)
    static let stroke = polarWhite.opacity(0.13)
    static let hairline = polarWhite.opacity(0.08)
    static let textPrimary = polarWhite
    static let textSecondary = mist
    static let textMuted = mist.opacity(0.55)
    static let success = auroraMint
    static let warning = auroraRose
    static let dockShadow = Color.black.opacity(0.58)
    static let vignette = Color(hex: "01020A").opacity(0.72)
}

enum AuroraGradients {
    static let canvas = LinearGradient(
        colors: [
            AuroraColors.obsidian,
            AuroraColors.midnight,
            AuroraColors.velvet,
            AuroraColors.eclipse,
            AuroraColors.obsidian
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryCTA = LinearGradient(
        colors: [
            AuroraColors.auroraMint,
            AuroraColors.auroraCyan,
            AuroraColors.polarWhite.opacity(0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let oracle = LinearGradient(
        colors: [
            AuroraColors.auroraViolet.opacity(0.96),
            AuroraColors.auroraRose.opacity(0.86),
            AuroraColors.polarWhite.opacity(0.34)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let atlas = LinearGradient(
        colors: [
            AuroraColors.auroraCyan.opacity(0.94),
            AuroraColors.auroraMint.opacity(0.78),
            AuroraColors.polarWhite.opacity(0.28)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let journal = LinearGradient(
        colors: [
            AuroraColors.auroraRose.opacity(0.98),
            AuroraColors.auroraViolet.opacity(0.72),
            AuroraColors.polarWhite.opacity(0.26)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let silkHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.18),
            Color.white.opacity(0.05),
            Color.white.opacity(0.01)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let haloMist = RadialGradient(
        colors: [
            AuroraColors.auroraMint.opacity(0.28),
            AuroraColors.auroraViolet.opacity(0.18),
            AuroraColors.auroraRose.opacity(0.1),
            Color.clear
        ],
        center: .center,
        startRadius: 10,
        endRadius: 320
    )

    static let auroraSpectrum = LinearGradient(
        colors: [
            AuroraColors.auroraMint.opacity(0.96),
            AuroraColors.auroraCyan.opacity(0.96),
            AuroraColors.auroraViolet.opacity(0.94),
            AuroraColors.auroraRose.opacity(0.9)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let auroraVeil = LinearGradient(
        colors: [
            AuroraColors.auroraMint.opacity(0.9),
            AuroraColors.auroraCyan.opacity(0.86),
            AuroraColors.auroraViolet.opacity(0.8),
            AuroraColors.auroraRose.opacity(0.72)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func cardWash(accent: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.24),
                AuroraColors.surfaceElevated.opacity(0.18),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func chipFill(accent: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.92),
                accent.opacity(0.65),
                AuroraColors.polarWhite.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum AuroraSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AuroraRadius {
    static let sm: CGFloat = 14
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let full: CGFloat = 999
}

enum AuroraMotion {
    static let entrance = Animation.easeOut(duration: 0.28)
    static let transition = Animation.easeInOut(duration: 0.2)
    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.82)
    static let ambientDuration: Double = 8
}

enum AuroraTypography {
    static func hero(_ size: CGFloat = 40) -> Font {
        customFont(named: "CormorantGaramond-SemiBold", size: size, fallbackDesign: .serif, weight: .semibold)
    }

    static func title(_ size: CGFloat = 28) -> Font {
        customFont(named: "CormorantGaramond-SemiBold", size: size, fallbackDesign: .serif, weight: .semibold)
    }

    static func section(_ size: CGFloat = 20) -> Font {
        customFont(named: "Manrope-SemiBold", size: size, fallbackDesign: .rounded, weight: .semibold)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        customFont(named: "Manrope-Regular", size: size, fallbackDesign: .rounded, weight: .regular)
    }

    static func bodyStrong(_ size: CGFloat = 16) -> Font {
        customFont(named: "Manrope-SemiBold", size: size, fallbackDesign: .rounded, weight: .semibold)
    }

    static func mono(_ size: CGFloat = 12) -> Font {
        if UIFont(name: "JetBrainsMono-Medium", size: size) != nil {
            return .custom("JetBrainsMono-Medium", size: size)
        }
        return .system(size: size, weight: .medium, design: .monospaced)
    }

    private static func customFont(
        named name: String,
        size: CGFloat,
        fallbackDesign: Font.Design,
        weight: Font.Weight
    ) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: fallbackDesign)
    }
}

extension Color {
    static let auroraCanvas = AuroraColors.canvas
}
