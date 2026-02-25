import SwiftUI

// MARK: - Color Palette
enum MysticColors {
    // Primary
    static let deepPurple = Color(hex: "1a0a2e")
    static let cosmicBlue = Color(hex: "16213e")
    static let midnightTeal = Color(hex: "0a1628")
    static let voidBlack = Color(hex: "080510")

    // Accent
    static let mysticGold = Color(hex: "c9a227")
    static let neonLavender = Color(hex: "b388ff")
    static let auroraGreen = Color(hex: "69f0ae")
    static let celestialPink = Color(hex: "ff6eb4")
    static let starWhite = Color(hex: "e8e6f0")

    // Surface
    static let cardBackground = Color(hex: "1a1030").opacity(0.7)
    static let cardBorder = Color(hex: "b388ff").opacity(0.2)
    static let inputBackground = Color(hex: "0d0720").opacity(0.8)

    // Text
    static let textPrimary = Color(hex: "f0ecff")
    static let textSecondary = Color(hex: "a099b8")
    static let textMuted = Color(hex: "6b6180")
}

// MARK: - Gradients
enum MysticGradients {
    static let cosmicBackground = LinearGradient(
        colors: [
            MysticColors.voidBlack,
            MysticColors.deepPurple,
            MysticColors.cosmicBlue,
            MysticColors.midnightTeal
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldShimmer = LinearGradient(
        colors: [
            MysticColors.mysticGold.opacity(0.8),
            Color(hex: "f0d060"),
            MysticColors.mysticGold
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let lavenderGlow = LinearGradient(
        colors: [
            MysticColors.neonLavender.opacity(0.6),
            MysticColors.celestialPink.opacity(0.4),
            MysticColors.neonLavender.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let auroraShift = LinearGradient(
        colors: [
            MysticColors.neonLavender,
            MysticColors.auroraGreen,
            MysticColors.celestialPink
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGlass = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
enum MysticFonts {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func heading(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func mystic(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .light, design: .serif)
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
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 100
}

// MARK: - Color Hex Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
