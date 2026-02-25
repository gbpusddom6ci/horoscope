import Foundation

// MARK: - Chart Data (Full natal or transit chart)
struct ChartData: Codable, Identifiable {
    let id: String
    var type: ChartType
    var calculatedAt: Date
    var planetPositions: [PlanetPosition]
    var houseCusps: [HouseCusp]
    var aspects: [Aspect]

    init(
        id: String = UUID().uuidString,
        type: ChartType = .natal,
        calculatedAt: Date = Date(),
        planetPositions: [PlanetPosition] = [],
        houseCusps: [HouseCusp] = [],
        aspects: [Aspect] = []
    ) {
        self.id = id
        self.type = type
        self.calculatedAt = calculatedAt
        self.planetPositions = planetPositions
        self.houseCusps = houseCusps
        self.aspects = aspects
    }
}

enum ChartType: String, Codable {
    case natal = "natal"
    case transit = "transit"
}

// MARK: - Planet Position
struct PlanetPosition: Codable, Identifiable {
    var id: String { planet.rawValue }
    var planet: Planet
    var sign: ZodiacSign
    var degree: Double          // 0-360
    var signDegree: Double      // 0-30 (degree within sign)
    var house: Int              // 1-12
    var isRetrograde: Bool

    var formattedDegree: String {
        let deg = Int(signDegree)
        let min = Int((signDegree - Double(deg)) * 60)
        return "\(deg)°\(min)' \(sign.rawValue)"
    }
}

// MARK: - House Cusp
struct HouseCusp: Codable, Identifiable {
    var id: Int { houseNumber }
    var houseNumber: Int        // 1-12
    var sign: ZodiacSign
    var degree: Double          // 0-360
}

// MARK: - Aspect (between two planets)
struct Aspect: Codable, Identifiable {
    var id: String { "\(planet1.rawValue)-\(planet2.rawValue)" }
    var planet1: Planet
    var planet2: Planet
    var type: AspectType
    var orb: Double             // actual orb in degrees
    var isApplying: Bool        // getting closer or separating

    var description: String {
        "\(planet1.rawValue) \(type.symbol) \(planet2.rawValue) (\(type.rawValue))"
    }
}

// MARK: - Transit Event
struct TransitEvent: Codable, Identifiable {
    let id: String
    var transitPlanet: Planet       // transiting planet
    var natalPlanet: Planet         // natal planet being aspected
    var aspectType: AspectType
    var exactDate: Date             // when exact
    var startDate: Date             // when orb enters
    var endDate: Date               // when orb leaves
    var severity: TransitSeverity
    var description: String
    var interpretation: String?     // AI-generated

    init(
        id: String = UUID().uuidString,
        transitPlanet: Planet,
        natalPlanet: Planet,
        aspectType: AspectType,
        exactDate: Date,
        startDate: Date,
        endDate: Date,
        severity: TransitSeverity = .medium,
        description: String = "",
        interpretation: String? = nil
    ) {
        self.id = id
        self.transitPlanet = transitPlanet
        self.natalPlanet = natalPlanet
        self.aspectType = aspectType
        self.exactDate = exactDate
        self.startDate = startDate
        self.endDate = endDate
        self.severity = severity
        self.description = description
        self.interpretation = interpretation
    }

    /// Duration of the transit in days
    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

enum TransitSeverity: String, Codable {
    case low = "Düşük"
    case medium = "Orta"
    case high = "Yüksek"
    case critical = "Kritik"

    var emoji: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }
}
