import SwiftUI

// MARK: - Planetary Dignity Helpers
enum PlanetaryDignity: String {
    case domicile = "Yurt"        // Planet rules this sign
    case exaltation = "Yüceltme"  // Planet is exalted
    case detriment = "Zarar"      // Opposite of domicile
    case fall = "Düşüş"           // Opposite of exaltation
    case peregrine = "Seyyah"     // No special dignity

    var color: Color {
        switch self {
        case .domicile: return MysticColors.auroraGreen
        case .exaltation: return MysticColors.mysticGold
        case .detriment: return .orange
        case .fall: return MysticColors.celestialPink
        case .peregrine: return MysticColors.textMuted
        }
    }

    var icon: String {
        switch self {
        case .domicile: return "house.fill"
        case .exaltation: return "arrow.up.circle.fill"
        case .detriment: return "exclamationmark.triangle.fill"
        case .fall: return "arrow.down.circle.fill"
        case .peregrine: return "circle"
        }
    }
}

func planetaryDignity(planet: Planet, sign: ZodiacSign) -> PlanetaryDignity {
    // Domicile (rulership)
    let domicile: [Planet: [ZodiacSign]] = [
        .sun: [.leo], .moon: [.cancer], .mercury: [.gemini, .virgo],
        .venus: [.taurus, .libra], .mars: [.aries, .scorpio],
        .jupiter: [.sagittarius, .pisces], .saturn: [.capricorn, .aquarius],
        .uranus: [.aquarius], .neptune: [.pisces], .pluto: [.scorpio]
    ]

    // Exaltation
    let exaltation: [Planet: ZodiacSign] = [
        .sun: .aries, .moon: .taurus, .mercury: .virgo,
        .venus: .pisces, .mars: .capricorn, .jupiter: .cancer,
        .saturn: .libra
    ]

    // Detriment
    let detriment: [Planet: [ZodiacSign]] = [
        .sun: [.aquarius], .moon: [.capricorn], .mercury: [.sagittarius, .pisces],
        .venus: [.aries, .scorpio], .mars: [.taurus, .libra],
        .jupiter: [.gemini, .virgo], .saturn: [.cancer, .leo]
    ]

    // Fall
    let fall: [Planet: ZodiacSign] = [
        .sun: .libra, .moon: .scorpio, .mercury: .pisces,
        .venus: .virgo, .mars: .cancer, .jupiter: .capricorn,
        .saturn: .aries
    ]

    if domicile[planet]?.contains(sign) == true { return .domicile }
    if exaltation[planet] == sign { return .exaltation }
    if detriment[planet]?.contains(sign) == true { return .detriment }
    if fall[planet] == sign { return .fall }
    return .peregrine
}

// MARK: - Big 3 Card
struct Big3Card: View {
    let label: String
    let symbol: String
    let sign: ZodiacSign?
    let degree: String?
    let color: Color

    var body: some View {
        MysticCard(glowColor: color.opacity(0.3)) {
            VStack(spacing: 5) {
                Text(symbol)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(label)
                    .font(MysticFonts.caption(10))
                    .foregroundColor(MysticColors.textMuted)

                if let sign = sign {
                    Text(sign.symbol)
                        .font(.system(size: 22))
                    Text(sign.rawValue)
                        .font(MysticFonts.caption(11))
                        .fontWeight(.medium)
                        .foregroundColor(sign.elementColor)
                    if let deg = degree {
                        Text(deg)
                            .font(MysticFonts.caption(9))
                            .foregroundColor(MysticColors.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 110)
        }
    }
}

// MARK: - Planet Detail Card
struct PlanetDetailCard: View {
    let position: PlanetPosition
    let isExpanded: Bool
    let onTap: () -> Void

    private var dignity: PlanetaryDignity {
        planetaryDignity(planet: position.planet, sign: position.sign)
    }

    var body: some View {
        Button(action: onTap) {
            MysticCard(glowColor: position.sign.elementColor.opacity(isExpanded ? 0.5 : 0.2)) {
                VStack(spacing: 0) {
                    mainRow
                    if isExpanded { expandedContent }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var mainRow: some View {
        HStack(spacing: MysticSpacing.md) {
            // Planet icon with dignity ring
            ZStack {
                Circle()
                    .fill(position.sign.elementColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Circle()
                    .stroke(dignity.color.opacity(0.6), lineWidth: 2)
                    .frame(width: 48, height: 48)
                Text(position.planet.symbol)
                    .font(.system(size: 22))

                // Dignity badge
                if dignity != .peregrine {
                    Image(systemName: dignity.icon)
                        .font(.system(size: 10))
                        .foregroundColor(dignity.color)
                        .padding(3)
                        .background(MysticColors.voidBlack)
                        .clipShape(Circle())
                        .offset(x: 18, y: -18)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(position.planet.rawValue)
                        .font(MysticFonts.body(15))
                        .fontWeight(.semibold)
                        .foregroundColor(MysticColors.textPrimary)

                    if position.isRetrograde {
                        Text("℞")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MysticColors.celestialPink)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(MysticColors.celestialPink.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                HStack(spacing: 4) {
                    Text(position.sign.symbol)
                        .font(.system(size: 14))
                    Text(position.formattedDegree)
                        .font(MysticFonts.caption(13))
                        .foregroundColor(position.sign.elementColor)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(position.house). Ev")
                    .font(MysticFonts.body(13))
                    .foregroundColor(MysticColors.textSecondary)

                if dignity != .peregrine {
                    Text(dignity.rawValue)
                        .font(MysticFonts.caption(10))
                        .foregroundColor(dignity.color)
                }
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 11))
                .foregroundColor(MysticColors.textMuted)
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(MysticColors.cardBorder)
                .padding(.vertical, MysticSpacing.sm)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                dignityCell("Element", value: position.sign.element, color: position.sign.elementColor)
                dignityCell("Nitelik", value: position.sign.modality, color: MysticColors.textSecondary)
                dignityCell("Derece", value: String(format: "%.2f°", position.signDegree), color: MysticColors.mysticGold)
                dignityCell("Onur", value: dignity.rawValue, color: dignity.color)
            }

            if position.isRetrograde {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .foregroundColor(MysticColors.celestialPink)
                        .font(.system(size: 14))
                    Text("Bu gezegen retrograd — etkisi içe dönük ve gecikmeli")
                        .font(MysticFonts.caption(11))
                        .foregroundColor(MysticColors.celestialPink.opacity(0.8))
                }
                .padding(.top, 8)
            }
        }
    }

    private func dignityCell(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(MysticFonts.caption(10))
                .foregroundColor(MysticColors.textMuted)
            Text(value)
                .font(MysticFonts.body(13))
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

// MARK: - Aspect Card
struct AspectCard: View {
    let aspect: Aspect

    var body: some View {
        let isHarmonious = aspect.type.isHarmonious
        let accentColor: Color = isHarmonious ? MysticColors.auroraGreen : MysticColors.celestialPink

        MysticCard(glowColor: accentColor.opacity(0.2)) {
            HStack(spacing: 0) {
                // Planet 1
                VStack(spacing: 2) {
                    Text(aspect.planet1.symbol)
                        .font(.system(size: 20))
                    Text(aspect.planet1.rawValue)
                        .font(MysticFonts.caption(9))
                        .foregroundColor(MysticColors.textMuted)
                }
                .frame(width: 55)

                // Connecting line + aspect symbol
                HStack(spacing: 0) {
                    Rectangle().fill(accentColor.opacity(0.3)).frame(height: 1)
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Circle()
                            .stroke(accentColor.opacity(0.4), lineWidth: 1)
                            .frame(width: 36, height: 36)
                        Text(aspect.type.symbol)
                            .font(.system(size: 18))
                            .foregroundColor(accentColor)
                    }
                    Rectangle().fill(accentColor.opacity(0.3)).frame(height: 1)
                }

                // Planet 2
                VStack(spacing: 2) {
                    Text(aspect.planet2.symbol)
                        .font(.system(size: 20))
                    Text(aspect.planet2.rawValue)
                        .font(MysticFonts.caption(9))
                        .foregroundColor(MysticColors.textMuted)
                }
                .frame(width: 55)

                Spacer()

                // Info
                VStack(alignment: .trailing, spacing: 3) {
                    Text(aspect.type.rawValue)
                        .font(MysticFonts.body(12))
                        .foregroundColor(accentColor)
                    Text(String(format: "%.1f° orb", aspect.orb))
                        .font(MysticFonts.caption(10))
                        .foregroundColor(MysticColors.textMuted)
                }
            }
        }
    }
}

// MARK: - Element & Modality Breakdown
struct ElementModalityBreakdown: View {
    let positions: [PlanetPosition]

    private var elements: [(String, String, Int, Color)] {
        let grouped = Dictionary(grouping: positions) { $0.sign.element }
        return [
            ("🔥", "Ateş", grouped["Ateş"]?.count ?? 0, .red),
            ("🌍", "Toprak", grouped["Toprak"]?.count ?? 0, .green),
            ("💨", "Hava", grouped["Hava"]?.count ?? 0, .cyan),
            ("💧", "Su", grouped["Su"]?.count ?? 0, .blue)
        ]
    }

    private var modalities: [(String, Int, Color)] {
        let grouped = Dictionary(grouping: positions) { $0.sign.modality }
        return [
            ("Öncü", grouped["Öncü"]?.count ?? 0, .orange),
            ("Sabit", grouped["Sabit"]?.count ?? 0, MysticColors.neonLavender),
            ("Değişken", grouped["Değişken"]?.count ?? 0, MysticColors.auroraGreen)
        ]
    }

    var body: some View {
        MysticCard {
            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                // Elements
                Text("Element Dağılımı")
                    .font(MysticFonts.heading(14))
                    .foregroundColor(MysticColors.textPrimary)

                HStack(spacing: MysticSpacing.sm) {
                    ForEach(elements, id: \.1) { emoji, name, count, color in
                        elementColumn(emoji: emoji, name: name, count: count, color: color)
                    }
                }

                Divider().background(MysticColors.cardBorder)

                // Modalities
                Text("Nitelik Dağılımı")
                    .font(MysticFonts.heading(14))
                    .foregroundColor(MysticColors.textPrimary)

                HStack(spacing: MysticSpacing.sm) {
                    ForEach(modalities, id: \.0) { name, count, color in
                        modalityColumn(name: name, count: count, color: color)
                    }
                }
            }
        }
    }

    private func elementColumn(emoji: String, name: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(MysticFonts.heading(18))
                .foregroundColor(color)
            progressBar(count: count, color: color)
            Text("\(emoji) \(name)")
                .font(MysticFonts.caption(10))
                .foregroundColor(MysticColors.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func modalityColumn(name: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(MysticFonts.heading(18))
                .foregroundColor(color)
            progressBar(count: count, color: color)
            Text(name)
                .font(MysticFonts.caption(10))
                .foregroundColor(MysticColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func progressBar(count: Int, color: Color) -> some View {
        let total = max(positions.count, 1)
        return GeometryReader { geo in
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.12))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(total))
                }
        }
        .frame(height: 6)
    }
}

// MARK: - House Card
struct HouseCard: View {
    let cusp: HouseCusp
    let planetsInHouse: [PlanetPosition]

    private static let descriptions: [Int: String] = [
        1: "Benlik, kimlik, fiziksel görünüm",
        2: "Değerler, maddi kazanç, özsaygı",
        3: "İletişim, kardeşler, kısa yolculuk",
        4: "Aile, ev, kökler, iç dünya",
        5: "Yaratıcılık, aşk, çocuklar, eğlence",
        6: "Sağlık, günlük iş, hizmet",
        7: "İlişkiler, ortaklık, evlilik",
        8: "Dönüşüm, gizem, miras, cinsellik",
        9: "Felsefe, yüksek öğrenim, uzun yolculuk",
        10: "Kariyer, statü, toplumsal rol",
        11: "Arkadaşlık, topluluk, idealler",
        12: "Bilinçaltı, spiritüellik, yalnızlık"
    ]

    var body: some View {
        MysticCard(glowColor: planetsInHouse.isEmpty ? Color.clear : cusp.sign.elementColor.opacity(0.3)) {
            HStack(spacing: MysticSpacing.md) {
                // House number badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(cusp.sign.elementColor.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Text("\(cusp.houseNumber)")
                        .font(MysticFonts.heading(18))
                        .foregroundColor(cusp.sign.elementColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("\(cusp.houseNumber). Ev")
                            .font(MysticFonts.body(14))
                            .fontWeight(.semibold)
                            .foregroundColor(MysticColors.textPrimary)
                        Text("·")
                            .foregroundColor(MysticColors.textMuted)
                        Text(cusp.sign.symbol)
                            .font(.system(size: 14))
                        Text(cusp.sign.rawValue)
                            .font(MysticFonts.caption(12))
                            .foregroundColor(cusp.sign.elementColor)
                    }
                    Text(Self.descriptions[cusp.houseNumber] ?? "")
                        .font(MysticFonts.caption(11))
                        .foregroundColor(MysticColors.textMuted)
                }

                Spacer()

                // Planets in this house
                if !planetsInHouse.isEmpty {
                    HStack(spacing: -6) {
                        ForEach(planetsInHouse.prefix(4)) { p in
                            Text(p.planet.symbol)
                                .font(.system(size: 13))
                                .frame(width: 26, height: 26)
                                .background(p.sign.elementColor.opacity(0.15))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(MysticColors.cardBorder, lineWidth: 0.5))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Chart Pattern Detection
struct ChartPatternCard: View {
    let chart: ChartData

    var body: some View {
        let patterns = detectPatterns()
        if !patterns.isEmpty {
            MysticCard(glowColor: MysticColors.mysticGold.opacity(0.4)) {
                VStack(alignment: .leading, spacing: MysticSpacing.md) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(MysticColors.mysticGold)
                        Text("Harita Desenleri")
                            .font(MysticFonts.heading(16))
                            .foregroundColor(MysticColors.textPrimary)
                    }

                    ForEach(patterns, id: \.0) { pattern in
                        HStack(alignment: .top, spacing: MysticSpacing.sm) {
                            Text(pattern.2)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.0)
                                    .font(MysticFonts.body(14))
                                    .fontWeight(.semibold)
                                    .foregroundColor(MysticColors.textPrimary)
                                Text(pattern.1)
                                    .font(MysticFonts.caption(12))
                                    .foregroundColor(MysticColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func detectPatterns() -> [(String, String, String)] {
        var patterns: [(String, String, String)] = []
        let trines = chart.aspects.filter { $0.type == .trine }
        let squares = chart.aspects.filter { $0.type == .square }
        let conjunctions = chart.aspects.filter { $0.type == .conjunction }
        let oppositions = chart.aspects.filter { $0.type == .opposition }

        // Check for Grand Trine (3 mutual trines)
        if trines.count >= 3 { patterns.append(("Büyük Üçgen", "Üç gezegen trine ile bağlı — doğal yetenek ve akış", "△")) }
        // Check for T-Square
        if squares.count >= 2 && oppositions.count >= 1 { patterns.append(("T-Kare", "İki kare ve bir karşıtlık — zorluk ile büyüme", "⊤")) }
        // Stellium (3+ planets in same sign)
        let signGroups = Dictionary(grouping: chart.planetPositions) { $0.sign }
        for (sign, planets) in signGroups where planets.count >= 3 {
            let names = planets.map { $0.planet.rawValue }.joined(separator: ", ")
            patterns.append(("Stellium — \(sign.rawValue)", "\(names): yoğun enerji odağı", "⭐"))
        }
        // Many conjunctions
        if conjunctions.count >= 4 { patterns.append(("Yoğun Kavuşum", "\(conjunctions.count) kavuşum — güçlü birleşik enerji", "◉")) }

        return patterns
    }
}

// MARK: - Dominant Planet Card
struct DominantPlanetCard: View {
    let chart: ChartData

    var body: some View {
        let dominant = findDominant()
        if let (planet, score, reason) = dominant {
            MysticCard(glowColor: MysticColors.neonLavender.opacity(0.4)) {
                HStack(spacing: MysticSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(MysticColors.neonLavender.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Circle()
                            .stroke(MysticColors.neonLavender.opacity(0.5), lineWidth: 2)
                            .frame(width: 52, height: 52)
                        Text(planet.symbol)
                            .font(.system(size: 26))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Dominant Gezegen")
                            .font(MysticFonts.caption(11))
                            .foregroundColor(MysticColors.textMuted)
                        Text(planet.rawValue)
                            .font(MysticFonts.heading(18))
                            .foregroundColor(MysticColors.textPrimary)
                        Text(reason)
                            .font(MysticFonts.caption(11))
                            .foregroundColor(MysticColors.textSecondary)
                    }

                    Spacer()

                    VStack {
                        Text("\(score)")
                            .font(MysticFonts.heading(22))
                            .foregroundColor(MysticColors.mysticGold)
                        Text("puan")
                            .font(MysticFonts.caption(10))
                            .foregroundColor(MysticColors.textMuted)
                    }
                }
            }
        }
    }

    private func findDominant() -> (Planet, Int, String)? {
        var scores: [Planet: Int] = [:]
        let mainPlanets: [Planet] = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]

        for pos in chart.planetPositions {
            guard mainPlanets.contains(pos.planet) else { continue }
            var s = 0
            // Personal planet bonus
            if [.sun, .moon, .mercury, .venus, .mars].contains(pos.planet) { s += 2 }
            // Sun/Moon extra
            if pos.planet == .sun || pos.planet == .moon { s += 3 }
            // Angular houses (1,4,7,10)
            if [1, 4, 7, 10].contains(pos.house) { s += 3 }
            // Dignity
            let d = planetaryDignity(planet: pos.planet, sign: pos.sign)
            if d == .domicile { s += 3 } else if d == .exaltation { s += 2 }
            // Count aspects
            let aspectCount = chart.aspects.filter { $0.planet1 == pos.planet || $0.planet2 == pos.planet }.count
            s += aspectCount
            scores[pos.planet] = s
        }

        guard let best = scores.max(by: { $0.value < $1.value }) else { return nil }
        let pos = chart.planetPositions.first(where: { $0.planet == best.key })
        let reason = "\(pos?.sign.rawValue ?? "") \(pos?.house ?? 0). Evde"
        return (best.key, best.value, reason)
    }
}
