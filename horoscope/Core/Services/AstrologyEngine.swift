import Foundation
import os
import FirebaseAuth

// MARK: - FreeAstroAPI Response Models
private struct AstroAPIResponse: Codable {
    let planets: [AstroAPIPlanet]?
    let houses: [AstroAPIHouse]?
    let angles: AstroAPIAngles?
    let aspects: [AstroAPIAspect]?
}

private struct AstroAPIPlanet: Codable {
    let id: String
    let name: String
    let sign: String
    let pos: Double       // degree within sign (0-30)
    let abs_pos: Double   // absolute ecliptic longitude (0-360)
    let house: Int
    let retrograde: Bool
}

private struct AstroAPIHouse: Codable {
    let house: Int
    let sign: String
    let sign_id: String?
    let abs_pos: Double
}

private struct AstroAPIAngles: Codable {
    let asc: Double
    let mc: Double
}

private struct AstroAPIAspect: Codable {
    let p1: String
    let p2: String
    let type: String
    let orb: Double
    let is_major: Bool?
}

private struct AstroProxyRequest: Codable {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let city: String
    let latitude: Double
    let longitude: Double
    let timeZone: String
}

// MARK: - Astrology Calculation Engine
/// Uses FreeAstroAPI (Swiss Ephemeris backend) for accurate calculations.
/// Falls back to local PlanetaryCalculator if API is unavailable.
class AstrologyEngine {
    static let shared = AstrologyEngine()
    private let logger = Logger(subsystem: "rk.horoscope", category: "AstrologyEngine")

    private init() {}

    // MARK: - Generate Natal Chart (API-first, local fallback)

    func calculateNatalChart(birthData: BirthData) -> ChartData {
        // Return a placeholder immediately; callers should use the async version.
        // This sync version uses the local fallback.
        return calculateNatalChartLocally(birthData: birthData)
    }

    /// Async version that tries FreeAstroAPI first, falls back to local calculations.
    func calculateNatalChartAsync(birthData: BirthData) async -> ChartData {
        // Try API first with proper error logging
        do {
            let apiChart = try await fetchNatalChartFromAPI(birthData: birthData)
            logger.debug("FreeAstroAPI natal chart loaded successfully")
            return apiChart
        } catch {
            logger.error("FreeAstroAPI failed, using local fallback: \(error.localizedDescription, privacy: .public)")
            return calculateNatalChartLocally(birthData: birthData)
        }
    }

    // MARK: - API Integration

    private func fetchNatalChartFromAPI(birthData: BirthData) async throws -> ChartData {
        if let proxyURL = Secrets.astroProxyBaseURL {
            return try await fetchNatalChartFromProxy(birthData: birthData, proxyURL: proxyURL)
        }

        guard Secrets.allowDirectProviderCalls else {
            throw ConfigurationError.missingSecret("ASTRO_PROXY_BASE_URL")
        }

        let apiKey = Secrets.freeAstroAPIKey
        guard !apiKey.isEmpty else {
            throw ConfigurationError.missingSecret("FREE_ASTRO_API_KEY")
        }

        guard let url = URL(string: "https://api.freeastroapi.com/api/v1/natal/calculate") else {
            throw URLError(.badURL)
        }

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthData.birthDate)
        var hour = 12
        var minute = 0
        if let birthTime = birthData.birthTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTime)
            hour = timeComponents.hour ?? 12
            minute = timeComponents.minute ?? 0
        }

        // Match exact curl format that works
        let body: [String: Any] = [
            "year": dateComponents.year ?? 2000,
            "month": dateComponents.month ?? 1,
            "day": dateComponents.day ?? 1,
            "hour": hour,
            "minute": minute,
            "city": birthData.birthPlace
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.error("AstroAPI request failed with status \(statusCode)")
            throw URLError(.badServerResponse)
        }

        let apiResponse = try JSONDecoder().decode(AstroAPIResponse.self, from: data)
        return convertAPIResponse(apiResponse, birthData: birthData)
    }

    private func fetchNatalChartFromProxy(birthData: BirthData, proxyURL: URL) async throws -> ChartData {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw ConfigurationError.missingSecret("AUTH_SESSION")
        }
        let idToken = try await firebaseUser.getIDToken()

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthData.birthDate)
        var hour = 12
        var minute = 0
        if let birthTime = birthData.birthTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTime)
            hour = timeComponents.hour ?? 12
            minute = timeComponents.minute ?? 0
        }

        let body = AstroProxyRequest(
            year: dateComponents.year ?? 2000,
            month: dateComponents.month ?? 1,
            day: dateComponents.day ?? 1,
            hour: hour,
            minute: minute,
            city: birthData.birthPlace,
            latitude: birthData.latitude,
            longitude: birthData.longitude,
            timeZone: birthData.timeZoneIdentifier
        )

        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.error("Astro proxy request failed with status \(statusCode)")
            throw URLError(.badServerResponse)
        }

        let apiResponse = try JSONDecoder().decode(AstroAPIResponse.self, from: data)
        return convertAPIResponse(apiResponse, birthData: birthData)
    }

    /// Converts FreeAstroAPI JSON response to our ChartData model.
    private func convertAPIResponse(_ response: AstroAPIResponse, birthData: BirthData) -> ChartData {
        // Convert planets
        var positions: [PlanetPosition] = []
        for apiPlanet in response.planets ?? [] {
            guard let planet = mapAPIPlanetId(apiPlanet.id) else { continue }
            let sign = mapAPISign(apiPlanet.sign) ?? birthData.sunSign
            positions.append(PlanetPosition(
                planet: planet,
                sign: sign,
                degree: apiPlanet.abs_pos,
                signDegree: apiPlanet.pos,
                house: apiPlanet.house,
                isRetrograde: apiPlanet.retrograde
            ))
        }

        // Convert house cusps
        var cusps: [HouseCusp] = []
        for apiHouse in response.houses ?? [] {
            let sign = mapAPISign(apiHouse.sign) ?? .aries
            cusps.append(HouseCusp(
                houseNumber: apiHouse.house,
                sign: sign,
                degree: apiHouse.abs_pos
            ))
        }

        // Convert aspects
        var aspects: [Aspect] = []
        for apiAspect in response.aspects ?? [] {
            guard let p1 = mapAPIPlanetName(apiAspect.p1),
                  let p2 = mapAPIPlanetName(apiAspect.p2),
                  let aspectType = mapAPIAspectType(apiAspect.type) else { continue }
            aspects.append(Aspect(
                planet1: p1,
                planet2: p2,
                type: aspectType,
                orb: apiAspect.orb,
                isApplying: false
            ))
        }

        return ChartData(
            type: .natal,
            planetPositions: positions,
            houseCusps: cusps,
            aspects: aspects
        )
    }

    // MARK: - Mapping helpers

    private func mapAPIPlanetId(_ id: String) -> Planet? {
        switch id.lowercased() {
        case "sun": return .sun
        case "moon": return .moon
        case "mercury": return .mercury
        case "venus": return .venus
        case "mars": return .mars
        case "jupiter": return .jupiter
        case "saturn": return .saturn
        case "uranus": return .uranus
        case "neptune": return .neptune
        case "pluto": return .pluto
        case "true_node", "mean_node": return .northNode
        case "chiron": return .chiron
        default: return nil
        }
    }

    private func mapAPIPlanetName(_ name: String) -> Planet? {
        switch name.lowercased() {
        case "sun": return .sun
        case "moon": return .moon
        case "mercury": return .mercury
        case "venus": return .venus
        case "mars": return .mars
        case "jupiter": return .jupiter
        case "saturn": return .saturn
        case "uranus": return .uranus
        case "neptune": return .neptune
        case "pluto": return .pluto
        case "true node", "mean node", "true_node", "mean_node": return .northNode
        case "chiron": return .chiron
        default: return nil
        }
    }

    private func mapAPISign(_ sign: String) -> ZodiacSign? {
        switch sign.lowercased().prefix(3) {
        case "ari": return .aries
        case "tau": return .taurus
        case "gem": return .gemini
        case "can": return .cancer
        case "leo": return .leo
        case "vir": return .virgo
        case "lib": return .libra
        case "sco": return .scorpio
        case "sag": return .sagittarius
        case "cap": return .capricorn
        case "aqu": return .aquarius
        case "pis": return .pisces
        default: return nil
        }
    }

    private func mapAPIAspectType(_ type: String) -> AspectType? {
        switch type.lowercased() {
        case "conjunction": return .conjunction
        case "opposition": return .opposition
        case "trine": return .trine
        case "square": return .square
        case "sextile": return .sextile
        default: return nil
        }
    }

    // MARK: - Local Fallback (PlanetaryCalculator)

    private func calculateNatalChartLocally(birthData: BirthData) -> ChartData {
        let jd = julianDay(from: birthData.birthDate, time: birthData.birthTime)
        let allPlanets = PlanetaryCalculator.allPlanetLongitudes(julianDay: jd)
        let ascendantLon = calculateAscendant(jd: jd, lat: birthData.latitude, lon: birthData.longitude)

        // North Node
        let t = (jd - 2451545.0) / 36525.0
        let northNodeLon = normalizeAngle(125.0445 - 1934.1363 * t)

        // House cusps (Equal House)
        var cusps: [HouseCusp] = []
        for i in 0..<12 {
            let cuspLon = normalizeAngle(ascendantLon + Double(i * 30))
            let signIndex = Int(cuspLon / 30) % 12
            cusps.append(HouseCusp(
                houseNumber: i + 1,
                sign: ZodiacSign.allCases[signIndex],
                degree: cuspLon
            ))
        }

        var positions: [PlanetPosition] = []
        for (planet, lon, isRetro) in allPlanets {
            positions.append(createPosition(planet, longitude: lon, ascendant: ascendantLon, isRetrograde: isRetro))
        }
        positions.append(createPosition(.northNode, longitude: northNodeLon, ascendant: ascendantLon, isRetrograde: true))

        let aspects = calculateAspects(positions: positions)

        return ChartData(
            type: .natal,
            planetPositions: positions,
            houseCusps: cusps,
            aspects: aspects
        )
    }

    // MARK: - Current Transits

    func calculateCurrentTransits(natalChart: ChartData) -> [TransitEvent] {
        let now = Date()
        let jdNow = julianDay(from: now, time: nil)
        let calendar = Calendar.current
        let currentPositions = PlanetaryCalculator.allPlanetLongitudes(julianDay: jdNow)

        var events: [TransitEvent] = []
        let transitingPlanets: [Planet] = [.mars, .jupiter, .saturn, .uranus, .neptune, .pluto]
        let aspectTypes: [AspectType] = [.conjunction, .opposition, .trine, .square, .sextile]

        for (transitPlanet, transitLon, _) in currentPositions {
            guard transitingPlanets.contains(transitPlanet) else { continue }

            for natalPos in natalChart.planetPositions {
                guard natalPos.planet != .northNode && natalPos.planet != .chiron else { continue }

                let diff = abs(transitLon - natalPos.degree)
                let angle = min(diff, 360 - diff)

                for aspectType in aspectTypes {
                    let orb = abs(angle - aspectType.angleDegrees)
                    let maxOrb = transitOrb(for: transitPlanet)

                    if orb <= maxOrb {
                        let severity = transitSeverity(planet: transitPlanet, aspect: aspectType)
                        let duration = transitDuration(for: transitPlanet)
                        let aspectName = aspectType.localizedDisplayName

                        events.append(TransitEvent(
                            transitPlanet: transitPlanet,
                            natalPlanet: natalPos.planet,
                            aspectType: aspectType,
                            exactDate: calendar.date(byAdding: .day, value: Int(orb), to: now) ?? now,
                            startDate: calendar.date(byAdding: .day, value: -duration / 2, to: now) ?? now,
                            endDate: calendar.date(byAdding: .day, value: duration / 2, to: now) ?? now,
                            severity: severity,
                            description: String(
                                format: String(localized: "transit.description.format"),
                                transitPlanet.localizedDisplayName,
                                natalPos.planet.localizedDisplayName,
                                aspectName
                            )
                        ))
                        break
                    }
                }
            }
        }

        return events.sorted { $0.exactDate < $1.exactDate }
    }

    // MARK: - Helpers

    private func createPosition(_ planet: Planet, longitude lon: Double, ascendant: Double, isRetrograde: Bool) -> PlanetPosition {
        let safeLon = max(0, min(lon, 359.999))
        let signIndex = Int(safeLon / 30) % 12
        let sign = ZodiacSign.allCases[signIndex]
        return PlanetPosition(
            planet: planet,
            sign: sign,
            degree: safeLon,
            signDegree: safeLon.truncatingRemainder(dividingBy: 30),
            house: calculateHouse(degree: safeLon, ascendant: ascendant),
            isRetrograde: isRetrograde
        )
    }

    private func calculateHouse(degree: Double, ascendant: Double) -> Int {
        var diff = degree - ascendant
        if diff < 0 { diff += 360 }
        return Int(diff / 30) % 12 + 1
    }

    private func normalizeAngle(_ angle: Double) -> Double {
        var a = angle.truncatingRemainder(dividingBy: 360)
        if a < 0 { a += 360 }
        return a
    }

    private func julianDay(from date: Date, time: Date?) -> Double {
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: TimeZone(identifier: "UTC") ?? .current, from: date)
        if let time = time {
            let tc = calendar.dateComponents([.hour, .minute], from: time)
            components.hour = tc.hour
            components.minute = tc.minute
        }

        var y = Double(components.year ?? 2000)
        var m = Double(components.month ?? 1)
        let d = Double(components.day ?? 1)
        let h = Double(components.hour ?? 12)
        let min = Double(components.minute ?? 0)

        if m <= 2 { y -= 1; m += 12 }
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + (h + min / 60.0) / 24.0 + b - 1524.5
    }

    private func calculateAscendant(jd: Double, lat: Double, lon: Double) -> Double {
        let d = jd - 2451545.0
        let gmst = normalizeAngle(280.46061837 + 360.98564736629 * d)
        let lst = normalizeAngle(gmst + lon)
        let lstRad = lst * .pi / 180.0
        let latRad = lat * .pi / 180.0
        let eRad = 23.4392911 * .pi / 180.0

        let ascRad = atan2(cos(lstRad), -sin(lstRad) * cos(eRad) - tan(latRad) * sin(eRad))
        var ascDeg = ascRad * 180.0 / .pi
        if ascDeg < 0 { ascDeg += 360 }
        return ascDeg
    }

    private func calculateAspects(positions: [PlanetPosition]) -> [Aspect] {
        var aspects: [Aspect] = []
        for i in 0..<positions.count {
            for j in (i + 1)..<positions.count {
                if positions[i].planet == .chiron || positions[j].planet == .chiron { continue }
                let diff = abs(positions[i].degree - positions[j].degree)
                let angle = min(diff, 360 - diff)
                for aspectType in [AspectType.conjunction, .opposition, .trine, .square, .sextile] {
                    let orb = abs(angle - aspectType.angleDegrees)
                    if orb <= aspectType.orbDegrees {
                        aspects.append(Aspect(planet1: positions[i].planet, planet2: positions[j].planet, type: aspectType, orb: orb, isApplying: angle < aspectType.angleDegrees))
                        break
                    }
                }
            }
        }
        return aspects
    }

    private func transitOrb(for planet: Planet) -> Double {
        switch planet {
        case .pluto, .neptune: return 3.0
        case .uranus: return 3.5
        case .saturn: return 4.0
        case .jupiter: return 5.0
        default: return 4.0
        }
    }

    private func transitDuration(for planet: Planet) -> Int {
        switch planet {
        case .pluto: return 730
        case .neptune: return 540
        case .uranus: return 365
        case .saturn: return 90
        case .jupiter: return 30
        default: return 7
        }
    }

    private func transitSeverity(planet: Planet, aspect: AspectType) -> TransitSeverity {
        let hard = (aspect == .conjunction || aspect == .opposition || aspect == .square)
        switch planet {
        case .pluto: return hard ? .critical : .high
        case .neptune, .uranus: return hard ? .high : .medium
        case .saturn: return hard ? .high : .medium
        case .jupiter: return hard ? .medium : .low
        default: return .low
        }
    }
}
