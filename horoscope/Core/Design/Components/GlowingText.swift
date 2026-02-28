import SwiftUI

struct GlowingText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let text: String
    let font: Font
    let color: Color
    let glowRadius: CGFloat

    @State private var glowAnimation = false

    init(
        _ text: String,
        font: Font = MysticFonts.title(28),
        color: Color = MysticColors.mysticGold,
        glowRadius: CGFloat = 8
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.glowRadius = glowRadius
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .shadow(color: color.opacity(glowAnimation ? 0.6 : 0.2), radius: glowRadius)
            .shadow(color: color.opacity(glowAnimation ? 0.3 : 0.1), radius: glowRadius * 2)
            .onAppear {
                if reduceMotion {
                    glowAnimation = true
                } else {
                    withAnimation(
                        .easeInOut(duration: MysticMotion.textGlowDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        glowAnimation = true
                    }
                }
            }
    }
}

// MARK: - Zodiac Symbol
struct ZodiacSymbol: View {
    let sign: ZodiacSign
    let size: CGFloat
    let color: Color

    init(_ sign: ZodiacSign, size: CGFloat = 40, color: Color = MysticColors.mysticGold) {
        self.sign = sign
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(sign.symbol)
            .font(.system(size: size))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.4), radius: 4)
    }
}

// MARK: - Zodiac Sign Enum
enum ZodiacSign: String, CaseIterable, Codable {
    case aries = "Koç"
    case taurus = "Boğa"
    case gemini = "İkizler"
    case cancer = "Yengeç"
    case leo = "Aslan"
    case virgo = "Başak"
    case libra = "Terazi"
    case scorpio = "Akrep"
    case sagittarius = "Yay"
    case capricorn = "Oğlak"
    case aquarius = "Kova"
    case pisces = "Balık"

    var localizedDisplayName: String {
        switch self {
        case .aries: return String(localized: "astro.zodiac.aries")
        case .taurus: return String(localized: "astro.zodiac.taurus")
        case .gemini: return String(localized: "astro.zodiac.gemini")
        case .cancer: return String(localized: "astro.zodiac.cancer")
        case .leo: return String(localized: "astro.zodiac.leo")
        case .virgo: return String(localized: "astro.zodiac.virgo")
        case .libra: return String(localized: "astro.zodiac.libra")
        case .scorpio: return String(localized: "astro.zodiac.scorpio")
        case .sagittarius: return String(localized: "astro.zodiac.sagittarius")
        case .capricorn: return String(localized: "astro.zodiac.capricorn")
        case .aquarius: return String(localized: "astro.zodiac.aquarius")
        case .pisces: return String(localized: "astro.zodiac.pisces")
        }
    }

    var localizedElement: String {
        switch self {
        case .aries, .leo, .sagittarius:
            return String(localized: "astro.element.fire")
        case .taurus, .virgo, .capricorn:
            return String(localized: "astro.element.earth")
        case .gemini, .libra, .aquarius:
            return String(localized: "astro.element.air")
        case .cancer, .scorpio, .pisces:
            return String(localized: "astro.element.water")
        }
    }

    var localizedModality: String {
        switch self {
        case .aries, .cancer, .libra, .capricorn:
            return String(localized: "astro.modality.cardinal")
        case .taurus, .leo, .scorpio, .aquarius:
            return String(localized: "astro.modality.fixed")
        case .gemini, .virgo, .sagittarius, .pisces:
            return String(localized: "astro.modality.mutable")
        }
    }

    var symbol: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }

    var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Ateş"
        case .taurus, .virgo, .capricorn: return "Toprak"
        case .gemini, .libra, .aquarius: return "Hava"
        case .cancer, .scorpio, .pisces: return "Su"
        }
    }

    var modality: String {
        switch self {
        case .aries, .cancer, .libra, .capricorn: return "Öncü"
        case .taurus, .leo, .scorpio, .aquarius: return "Sabit"
        case .gemini, .virgo, .sagittarius, .pisces: return "Değişken"
        }
    }

    var elementColor: Color {
        switch self {
        case .aries, .leo, .sagittarius:
            return Color(hex: "ff6b35")
        case .taurus, .virgo, .capricorn:
            return MysticColors.auroraGreen
        case .gemini, .libra, .aquarius:
            return MysticColors.neonLavender
        case .cancer, .scorpio, .pisces:
            return Color(hex: "4fc3f7")
        }
    }

    var planetRuler: String {
        switch self {
        case .aries: return "Mars"
        case .taurus: return "Venüs"
        case .gemini: return "Merkür"
        case .cancer: return "Ay"
        case .leo: return "Güneş"
        case .virgo: return "Merkür"
        case .libra: return "Venüs"
        case .scorpio: return "Plüton"
        case .sagittarius: return "Jüpiter"
        case .capricorn: return "Satürn"
        case .aquarius: return "Uranüs"
        case .pisces: return "Neptün"
        }
    }

    /// Returns the zodiac sign for a given day/month
    static func from(month: Int, day: Int) -> ZodiacSign {
        switch (month, day) {
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...20): return .gemini
        case (6, 21...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...22): return .libra
        case (10, 23...31), (11, 1...21): return .scorpio
        case (11, 22...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        case (2, 19...29), (3, 1...20): return .pisces
        default: return .aries
        }
    }
}

#Preview {
    ZStack {
        StarField()
        VStack(spacing: 20) {
            GlowingText("✨ Mystic Guide", color: MysticColors.mysticGold)
            GlowingText("The Stars Are Speaking", font: MysticFonts.mystic(24), color: MysticColors.neonLavender)

            HStack(spacing: 12) {
                ForEach(ZodiacSign.allCases.prefix(6), id: \.self) { sign in
                    ZodiacSymbol(sign, size: 30, color: sign.elementColor)
                }
            }
        }
    }
}
