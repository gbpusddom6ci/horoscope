import Foundation

// MARK: - Birth Data
struct BirthData: Codable, Equatable {
    var birthDate: Date
    var birthTime: Date?            // nil if unknown
    var birthPlace: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String

    /// Whether the birth time is known
    var isBirthTimeKnown: Bool {
        birthTime != nil
    }

    /// Computed sun sign based on birth date
    var sunSign: ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: birthDate)
        let day = calendar.component(.day, from: birthDate)
        return ZodiacSign.from(month: month, day: day)
    }
}

// MARK: - Planet
enum Planet: String, CaseIterable, Codable {
    case sun = "Güneş"
    case moon = "Ay"
    case mercury = "Merkür"
    case venus = "Venüs"
    case mars = "Mars"
    case jupiter = "Jüpiter"
    case saturn = "Satürn"
    case uranus = "Uranüs"
    case neptune = "Neptün"
    case pluto = "Plüton"
    case northNode = "Kuzey Düğüm"
    case chiron = "Chiron"

    var symbol: String {
        switch self {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        case .northNode: return "☊"
        case .chiron: return "⚷"
        }
    }

    var systemIcon: String {
        switch self {
        case .sun: return "sun.max.fill"
        case .moon: return "moon.fill"
        case .mercury: return "circle.fill"
        case .venus: return "heart.fill"
        case .mars: return "flame.fill"
        case .jupiter: return "sparkles"
        case .saturn: return "circle.hexagongrid.fill"
        case .uranus: return "bolt.fill"
        case .neptune: return "drop.fill"
        case .pluto: return "atom"
        case .northNode: return "arrow.up.circle.fill"
        case .chiron: return "cross.circle.fill"
        }
    }
}

// MARK: - House
enum House: Int, CaseIterable, Codable {
    case first = 1, second, third, fourth, fifth, sixth
    case seventh, eighth, ninth, tenth, eleventh, twelfth

    var name: String {
        switch self {
        case .first: return "1. Ev (Benlik)"
        case .second: return "2. Ev (Değerler)"
        case .third: return "3. Ev (İletişim)"
        case .fourth: return "4. Ev (Aile)"
        case .fifth: return "5. Ev (Yaratıcılık)"
        case .sixth: return "6. Ev (Sağlık)"
        case .seventh: return "7. Ev (İlişkiler)"
        case .eighth: return "8. Ev (Dönüşüm)"
        case .ninth: return "9. Ev (Felsefe)"
        case .tenth: return "10. Ev (Kariyer)"
        case .eleventh: return "11. Ev (Topluluk)"
        case .twelfth: return "12. Ev (Bilinçaltı)"
        }
    }
}

// MARK: - Aspect
enum AspectType: String, Codable {
    case conjunction = "Kavuşum"        // 0°
    case opposition = "Karşıt"          // 180°
    case trine = "Üçgen"                // 120°
    case square = "Kare"                // 90°
    case sextile = "Altıgen"            // 60°
    case quincunx = "Quincunx"          // 150°

    var angleDegrees: Double {
        switch self {
        case .conjunction: return 0
        case .opposition: return 180
        case .trine: return 120
        case .square: return 90
        case .sextile: return 60
        case .quincunx: return 150
        }
    }

    var orbDegrees: Double {
        switch self {
        case .conjunction: return 8
        case .opposition: return 8
        case .trine: return 8
        case .square: return 7
        case .sextile: return 6
        case .quincunx: return 3
        }
    }

    var isHarmonious: Bool {
        switch self {
        case .trine, .sextile: return true
        case .conjunction: return true // generally
        case .opposition, .square, .quincunx: return false
        }
    }

    var symbol: String {
        switch self {
        case .conjunction: return "☌"
        case .opposition: return "☍"
        case .trine: return "△"
        case .square: return "□"
        case .sextile: return "✶"
        case .quincunx: return "⚻"
        }
    }
}
