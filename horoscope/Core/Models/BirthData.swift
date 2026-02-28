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
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
    case northNode = "North Node"
    case chiron = "Chiron"

    var localizedDisplayName: String {
        switch self {
        case .sun: return String(localized: "astro.planet.sun")
        case .moon: return String(localized: "astro.planet.moon")
        case .mercury: return String(localized: "astro.planet.mercury")
        case .venus: return String(localized: "astro.planet.venus")
        case .mars: return String(localized: "astro.planet.mars")
        case .jupiter: return String(localized: "astro.planet.jupiter")
        case .saturn: return String(localized: "astro.planet.saturn")
        case .uranus: return String(localized: "astro.planet.uranus")
        case .neptune: return String(localized: "astro.planet.neptune")
        case .pluto: return String(localized: "astro.planet.pluto")
        case .northNode: return String(localized: "astro.planet.north_node")
        case .chiron: return String(localized: "astro.planet.chiron")
        }
    }

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
        case .first: return String(localized: "astro.house.1")
        case .second: return String(localized: "astro.house.2")
        case .third: return String(localized: "astro.house.3")
        case .fourth: return String(localized: "astro.house.4")
        case .fifth: return String(localized: "astro.house.5")
        case .sixth: return String(localized: "astro.house.6")
        case .seventh: return String(localized: "astro.house.7")
        case .eighth: return String(localized: "astro.house.8")
        case .ninth: return String(localized: "astro.house.9")
        case .tenth: return String(localized: "astro.house.10")
        case .eleventh: return String(localized: "astro.house.11")
        case .twelfth: return String(localized: "astro.house.12")
        }
    }
}

// MARK: - Aspect
enum AspectType: String, Codable {
    case conjunction = "Conjunction"        // 0°
    case opposition = "Opposition"          // 180°
    case trine = "Trine"                // 120°
    case square = "Square"                // 90°
    case sextile = "Sextile"            // 60°
    case quincunx = "Quincunx"          // 150°

    var localizedDisplayName: String {
        switch self {
        case .conjunction: return String(localized: "astro.aspect.conjunction")
        case .opposition: return String(localized: "astro.aspect.opposition")
        case .trine: return String(localized: "astro.aspect.trine")
        case .square: return String(localized: "astro.aspect.square")
        case .sextile: return String(localized: "astro.aspect.sextile")
        case .quincunx: return String(localized: "astro.aspect.quincunx")
        }
    }

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
