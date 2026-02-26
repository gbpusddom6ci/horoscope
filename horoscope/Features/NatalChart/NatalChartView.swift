import SwiftUI

struct NatalChartView: View {
    @Environment(AuthService.self) private var authService
    @State private var chartData: ChartData?
    @State private var interpretation: String?
    @State private var isLoadingInterpretation = false
    @State private var isLoadingChart = false
    @State private var selectedPlanet: PlanetPosition?
    @State private var expandedPlanet: String?
    @State private var selectedTab: ChartTab = .planets

    private let engine = AstrologyEngine.shared
    private let aiService = AIService.shared

    enum ChartTab: String, CaseIterable {
        case planets = "Gezegenler"
        case aspects = "Aspektler"
        case houses = "Evler"
    }

    var body: some View {
        ZStack {
            StarField(starCount: 50)

            VStack(spacing: 0) {
                header
                content
            }
        }
        .onAppear { loadChart() }
    }

    // MARK: - Header
    private var header: some View {
        Text("Natal Harita")
            .font(MysticFonts.heading(18))
            .foregroundColor(MysticColors.textPrimary)
            .padding(.top, 10)
            .padding(.bottom, 10)
    }

    // MARK: - Main Content
    @ViewBuilder
    private var content: some View {
        if isLoadingChart {
            loadingView
        } else if let chart = chartData {
            chartContent(chart: chart)
        } else {
            noBirthDataView
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: MysticSpacing.md) {
            Spacer()
            ProgressView()
                .tint(MysticColors.neonLavender)
                .scaleEffect(1.5)
            Text("Haritanız hesaplanıyor...")
                .font(MysticFonts.caption(14))
                .foregroundColor(MysticColors.textMuted)
            Spacer()
        }
    }

    // MARK: - Chart Content
    private func chartContent(chart: ChartData) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MysticSpacing.lg) {
                // Chart Wheel
                ChartWheelView(chartData: chart, selectedPlanet: $selectedPlanet)
                    .frame(height: 330)
                    .fadeInOnAppear(delay: 0)

                // Big 3 Summary
                big3Section(chart: chart)
                    .fadeInOnAppear(delay: 0.05)

                // Dominant Planet
                DominantPlanetCard(chart: chart)
                    .padding(.horizontal, MysticSpacing.md)
                    .fadeInOnAppear(delay: 0.08)

                // Element & Modality
                ElementModalityBreakdown(positions: chart.planetPositions)
                    .padding(.horizontal, MysticSpacing.md)
                    .fadeInOnAppear(delay: 0.1)

                // Chart Patterns
                ChartPatternCard(chart: chart)
                    .padding(.horizontal, MysticSpacing.md)
                    .fadeInOnAppear(delay: 0.12)

                // Tab Picker + Content
                tabPicker.fadeInOnAppear(delay: 0.15)
                tabContent(chart: chart)

                // AI Interpretation
                interpretationSection
                    .fadeInOnAppear(delay: 0.25)

                Color.clear.frame(height: 100)
            }
        }
    }

    // MARK: - Big 3
    private func big3Section(chart: ChartData) -> some View {
        let sun = chart.planetPositions.first(where: { $0.planet == .sun })
        let moon = chart.planetPositions.first(where: { $0.planet == .moon })
        let ascSign = chart.houseCusps.first(where: { $0.houseNumber == 1 })?.sign
        let ascDeg = chart.houseCusps.first(where: { $0.houseNumber == 1 })?.degree

        return HStack(spacing: MysticSpacing.sm) {
            Big3Card(
                label: "Güneş", symbol: "☉",
                sign: sun?.sign, degree: sun?.formattedDegree,
                color: .orange
            )
            Big3Card(
                label: "Ay", symbol: "☽",
                sign: moon?.sign, degree: moon?.formattedDegree,
                color: MysticColors.celestialPink
            )
            Big3Card(
                label: "Yükselen", symbol: "AC",
                sign: ascSign,
                degree: ascDeg.map { String(format: "%.1f°", $0.truncatingRemainder(dividingBy: 30)) },
                color: MysticColors.neonLavender
            )
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ChartTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .background(MysticColors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
        .padding(.horizontal, MysticSpacing.md)
    }

    private func tabButton(_ tab: ChartTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        } label: {
            Text(tab.rawValue)
                .font(MysticFonts.body(14))
                .fontWeight(selectedTab == tab ? .semibold : .regular)
                .foregroundColor(selectedTab == tab ? MysticColors.textPrimary : MysticColors.textMuted)
                .padding(.vertical, MysticSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(selectedTab == tab ? MysticColors.neonLavender.opacity(0.15) : Color.clear)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(selectedTab == tab ? MysticColors.neonLavender : Color.clear)
                        .frame(height: 2)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content
    @ViewBuilder
    private func tabContent(chart: ChartData) -> some View {
        switch selectedTab {
        case .planets:
            planetsTab(chart: chart)
        case .aspects:
            aspectsTab(chart: chart)
        case .houses:
            housesTab(chart: chart)
        }
    }

    private func planetsTab(chart: ChartData) -> some View {
        VStack(spacing: MysticSpacing.sm) {
            ForEach(chart.planetPositions) { position in
                PlanetDetailCard(
                    position: position,
                    isExpanded: expandedPlanet == position.id
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        expandedPlanet = expandedPlanet == position.id ? nil : position.id
                    }
                }
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    private func aspectsTab(chart: ChartData) -> some View {
        VStack(spacing: MysticSpacing.sm) {
            ForEach(chart.aspects) { aspect in
                AspectCard(aspect: aspect)
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    private func housesTab(chart: ChartData) -> some View {
        VStack(spacing: MysticSpacing.sm) {
            ForEach(chart.houseCusps) { cusp in
                HouseCard(
                    cusp: cusp,
                    planetsInHouse: chart.planetPositions.filter { $0.house == cusp.houseNumber }
                )
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    // MARK: - AI Interpretation
    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            HStack {
                Text("AI Yorumu")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)
                Spacer()
                if interpretation == nil {
                    MysticButton("Yorumla", icon: "sparkles", style: .secondary, isLoading: isLoadingInterpretation) {
                        requestInterpretation()
                    }
                    .frame(width: 140)
                }
            }

            if let interpretation = interpretation {
                MysticCard(glowColor: MysticColors.mysticGold) {
                    Text(interpretation)
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.textSecondary)
                        .lineSpacing(4)
                }
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    // MARK: - No Data View
    private var noBirthDataView: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer().frame(height: 100)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 64))
                .foregroundStyle(MysticGradients.lavenderGlow)
                .opacity(0.5)
            Text("Natal haritanızı görmek için doğum bilgilerinizi girin")
                .font(MysticFonts.body(16))
                .foregroundColor(MysticColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Actions

    private func loadChart() {
        guard let birthData = authService.currentUser?.birthData else { return }
        isLoadingChart = true
        Task {
            chartData = await engine.calculateNatalChartAsync(birthData: birthData)
            isLoadingChart = false
        }
    }

    private func requestInterpretation() {
        guard let chart = chartData,
              let birthData = authService.currentUser?.birthData else { return }

        isLoadingInterpretation = true
        Task {
            do {
                interpretation = try await aiService.interpretNatalChart(
                    chartData: chart,
                    birthData: birthData
                )
            } catch {
                interpretation = "Yorum yüklenirken hata oluştu."
            }
            isLoadingInterpretation = false
        }
    }
}

// MARK: - Chart Wheel View (Professional)
struct ChartWheelView: View {
    let chartData: ChartData
    @Binding var selectedPlanet: PlanetPosition?
    @State private var glowPhase: Double = 0
    @State private var appeared = false

    // Radii ratios
    private let outerRatio: CGFloat = 1.0
    private let zodiacInnerRatio: CGFloat = 0.84
    private let houseOuterRatio: CGFloat = 0.84
    private let houseInnerRatio: CGFloat = 0.42
    private let planetRatio: CGFloat = 0.72

    var body: some View {
        VStack(spacing: MysticSpacing.md) {
            // The wheel
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let r = size / 2 - 8
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

                ZStack {
                    // Layer 1: Zodiac arcs (colored segments)
                    zodiacArcs(center: center, r: r)
                    // Layer 2: Rings
                    rings(r: r)
                    // Layer 3: Degree tick marks
                    tickMarks(center: center, r: r)
                    // Layer 4: Zodiac symbols
                    zodiacSymbols(center: center, r: r)
                    // Layer 5: House cusp lines + labels
                    houseCusps(center: center, r: r)
                    // Layer 6: Aspect lines (only selected planet's or all faded)
                    aspectLines(center: center, r: r)
                    // Layer 7: Center circle
                    centerCircle(r: r)
                }
                .overlay {
                    // Layer 8: Planet dots (overlay for taps)
                    planetDots(center: center, r: r)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)
            }
            .aspectRatio(1, contentMode: .fit)

            // Selected planet info card
            if let selected = selectedPlanet {
                selectedPlanetCard(selected)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glowPhase = 1 }
        }
    }

    // MARK: 1 — Zodiac Arcs
    private func zodiacArcs(center: CGPoint, r: CGFloat) -> some View {
        let outer = r * outerRatio
        let inner = r * zodiacInnerRatio
        let mid = (outer + inner) / 2
        let thickness = outer - inner

        return ForEach(0..<12, id: \.self) { i in
            let sign = ZodiacSign.allCases[i]
            let start = Angle(degrees: Double(i) * 30 - 90)
            let end = Angle(degrees: Double(i + 1) * 30 - 90)

            Path { p in
                p.addArc(center: center, radius: mid, startAngle: start, endAngle: end, clockwise: false)
            }
            .stroke(sign.elementColor.opacity(0.15 + glowPhase * 0.05), lineWidth: thickness)
        }
        .allowsHitTesting(false)
    }

    // MARK: 2 — Rings
    private func rings(r: CGFloat) -> some View {
        let outer = r * outerRatio
        let zodiacInner = r * zodiacInnerRatio
        let houseInner = r * houseInnerRatio

        return ZStack {
            // Outer glow
            Circle()
                .stroke(MysticColors.neonLavender.opacity(0.08 + glowPhase * 0.12), lineWidth: 2)
                .frame(width: outer * 2, height: outer * 2)
                .blur(radius: 4)

            // Main outer ring
            Circle()
                .stroke(MysticColors.neonLavender.opacity(0.35), lineWidth: 1.5)
                .frame(width: outer * 2, height: outer * 2)

            // Zodiac/house boundary
            Circle()
                .stroke(MysticColors.neonLavender.opacity(0.25), lineWidth: 1)
                .frame(width: zodiacInner * 2, height: zodiacInner * 2)

            // Inner house ring
            Circle()
                .stroke(MysticColors.neonLavender.opacity(0.12), lineWidth: 0.8)
                .frame(width: houseInner * 2, height: houseInner * 2)
        }
        .allowsHitTesting(false)
    }

    // MARK: 3 — Tick Marks
    private func tickMarks(center: CGPoint, r: CGFloat) -> some View {
        let outer = r * outerRatio

        return Path { p in
            for deg in stride(from: 0, to: 360, by: 10) {
                let angle = (Double(deg) - 90) * .pi / 180
                let isMajor = deg % 30 == 0
                let tickLen: CGFloat = isMajor ? 6 : 3
                let from = CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer)
                let to = CGPoint(x: center.x + cos(angle) * (outer - tickLen), y: center.y + sin(angle) * (outer - tickLen))
                p.move(to: from)
                p.addLine(to: to)
            }
        }
        .stroke(MysticColors.neonLavender.opacity(0.25), lineWidth: 0.5)
        .allowsHitTesting(false)
    }

    // MARK: 4 — Zodiac Symbols
    private func zodiacSymbols(center: CGPoint, r: CGFloat) -> some View {
        let symR = r * (outerRatio + zodiacInnerRatio) / 2
        return ZStack {
            ForEach(0..<12, id: \.self) { i in
                zodiacSymbol(index: i, center: center, radius: symR)
            }
        }
        .allowsHitTesting(false)
    }

    private func zodiacSymbol(index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let sign = ZodiacSign.allCases[index]
        let angle = (Double(index) * 30 + 15 - 90) * .pi / 180
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius

        return Text(sign.symbol)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(sign.elementColor)
            .position(x: x, y: y)
    }

    // MARK: 5 — House Cusps
    private func houseCusps(center: CGPoint, r: CGFloat) -> some View {
        let outer = r * houseOuterRatio
        let inner = r * houseInnerRatio

        return ZStack {
            ForEach(chartData.houseCusps) { cusp in
                singleHouseCusp(cusp: cusp, center: center, inner: inner, outer: outer)
            }
        }
        .allowsHitTesting(false)
    }

    private func singleHouseCusp(cusp: HouseCusp, center: CGPoint, inner: CGFloat, outer: CGFloat) -> some View {
        let angle = (cusp.degree - 90) * .pi / 180
        let isAngular = [1, 4, 7, 10].contains(cusp.houseNumber)
        let lineWidth: CGFloat = isAngular ? 1.2 : 0.5
        let opacity: Double = isAngular ? 0.4 : 0.15

        let numR = (inner + outer) / 2 * 0.65
        let nextCusp = chartData.houseCusps.first(where: { $0.houseNumber == (cusp.houseNumber % 12) + 1 })
        let midDeg = houseMidDegree(cusp: cusp.degree, next: nextCusp?.degree ?? cusp.degree + 30)
        let midAngle = (midDeg - 90) * .pi / 180

        return ZStack {
            // Cusp line
            Path { p in
                p.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                p.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
            }
            .stroke(MysticColors.neonLavender.opacity(opacity), lineWidth: lineWidth)

            // House number
            Text("\(cusp.houseNumber)")
                .font(.system(size: 9, weight: .light))
                .foregroundColor(MysticColors.textMuted.opacity(0.6))
                .position(
                    x: center.x + cos(midAngle) * numR,
                    y: center.y + sin(midAngle) * numR
                )

            // Angular labels (ASC, MC, DSC, IC)
            if isAngular {
                let labelR = outer + 2
                let label = angularLabel(cusp.houseNumber)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(MysticColors.mysticGold)
                    .position(
                        x: center.x + cos(angle) * labelR,
                        y: center.y + sin(angle) * labelR
                    )
            }
        }
    }

    private func houseMidDegree(cusp: Double, next: Double) -> Double {
        if next > cusp { return (cusp + next) / 2 }
        return (cusp + next + 360) / 2
    }

    private func angularLabel(_ house: Int) -> String {
        switch house {
        case 1: return "ASC"
        case 4: return "IC"
        case 7: return "DSC"
        case 10: return "MC"
        default: return ""
        }
    }

    // MARK: 6 — Aspect Lines
    private func aspectLines(center: CGPoint, r: CGFloat) -> some View {
        let aspectR = r * houseInnerRatio * 0.9

        return ForEach(chartData.aspects) { aspect in
            singleAspectLine(aspect: aspect, center: center, r: aspectR)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func singleAspectLine(aspect: Aspect, center: CGPoint, r: CGFloat) -> some View {
        if let p1 = chartData.planetPositions.first(where: { $0.planet == aspect.planet1 }),
           let p2 = chartData.planetPositions.first(where: { $0.planet == aspect.planet2 }) {
            let a1 = (p1.degree - 90) * .pi / 180
            let a2 = (p2.degree - 90) * .pi / 180
            let isHighlighted = selectedPlanet?.planet == aspect.planet1 || selectedPlanet?.planet == aspect.planet2
            let baseColor: Color = aspect.type.isHarmonious ? MysticColors.auroraGreen : MysticColors.celestialPink
            let opacity: Double = isHighlighted ? 0.6 : (selectedPlanet == nil ? 0.12 : 0.04)
            let width: CGFloat = isHighlighted ? 1.5 : 0.5

            Path { path in
                path.move(to: CGPoint(x: center.x + cos(a1) * r, y: center.y + sin(a1) * r))
                path.addLine(to: CGPoint(x: center.x + cos(a2) * r, y: center.y + sin(a2) * r))
            }
            .stroke(baseColor.opacity(opacity), lineWidth: width)
        }
    }

    // MARK: 7 — Center Circle
    private func centerCircle(r: CGFloat) -> some View {
        let size = r * houseInnerRatio * 0.55

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MysticColors.voidBlack, MysticColors.voidBlack.opacity(0.8)],
                        center: .center, startRadius: 0, endRadius: size
                    )
                )
                .frame(width: size * 2, height: size * 2)

            Circle()
                .stroke(MysticColors.mysticGold.opacity(0.2 + glowPhase * 0.15), lineWidth: 1)
                .frame(width: size * 2, height: size * 2)

            if selectedPlanet == nil {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(MysticColors.mysticGold.opacity(0.3))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: 8 — Planet Dots (overlay)
    private func planetDots(center: CGPoint, r: CGFloat) -> some View {
        let pR = r * planetRatio
        return ForEach(chartData.planetPositions) { pos in
            singlePlanetDot(pos: pos, center: center, pR: pR)
        }
    }

    private func singlePlanetDot(pos: PlanetPosition, center: CGPoint, pR: CGFloat) -> some View {
        let angle = (pos.degree - 90) * .pi / 180
        let x = center.x + cos(angle) * pR
        let y = center.y + sin(angle) * pR
        let isSelected = selectedPlanet?.id == pos.id
        let dotSize: CGFloat = 32

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedPlanet = isSelected ? nil : pos
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                // Outer glow for selected
                if isSelected {
                    Circle()
                        .fill(pos.sign.elementColor.opacity(0.25))
                        .frame(width: dotSize + 10, height: dotSize + 10)
                        .blur(radius: 4)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                pos.sign.elementColor.opacity(isSelected ? 0.7 : 0.3),
                                pos.sign.elementColor.opacity(isSelected ? 0.4 : 0.1)
                            ],
                            center: .center, startRadius: 0, endRadius: dotSize / 2
                        )
                    )
                    .frame(width: dotSize, height: dotSize)

                Circle()
                    .stroke(pos.sign.elementColor.opacity(isSelected ? 1.0 : 0.5), lineWidth: isSelected ? 2 : 1)
                    .frame(width: dotSize, height: dotSize)

                Text(pos.planet.symbol)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : pos.sign.elementColor)
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .frame(width: dotSize + 12, height: dotSize + 12)
        .position(x: x, y: y)
    }

    // MARK: 9 — Selected Planet Card
    private func selectedPlanetCard(_ pos: PlanetPosition) -> some View {
        let dignity = planetaryDignity(planet: pos.planet, sign: pos.sign)

        return MysticCard(glowColor: pos.sign.elementColor.opacity(0.4)) {
            HStack(spacing: MysticSpacing.md) {
                // Planet symbol large
                ZStack {
                    Circle()
                        .fill(pos.sign.elementColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Text(pos.planet.symbol)
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(pos.planet.rawValue)
                            .font(MysticFonts.heading(16))
                            .foregroundColor(MysticColors.textPrimary)
                        if pos.isRetrograde {
                            Text("℞")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(MysticColors.celestialPink)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(MysticColors.celestialPink.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    HStack(spacing: 4) {
                        Text(pos.sign.symbol).font(.system(size: 14))
                        Text(pos.formattedDegree)
                            .font(MysticFonts.caption(12))
                            .foregroundColor(pos.sign.elementColor)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(pos.house). Ev")
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.textSecondary)
                    if dignity != .peregrine {
                        HStack(spacing: 3) {
                            Image(systemName: dignity.icon)
                                .font(.system(size: 10))
                            Text(dignity.rawValue)
                                .font(MysticFonts.caption(10))
                        }
                        .foregroundColor(dignity.color)
                    }
                    Text(pos.sign.element)
                        .font(MysticFonts.caption(10))
                        .foregroundColor(MysticColors.textMuted)
                }
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }
}

#Preview {
    NatalChartView()
        .environment(AuthService())
}
