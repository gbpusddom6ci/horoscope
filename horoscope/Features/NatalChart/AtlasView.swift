import SwiftUI

struct AtlasView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var chartData: ChartData?
    @State private var transits: [TransitEvent] = []
    @State private var interpretation: String?
    @State private var interpretationError: String?
    @State private var isLoadingChart = false
    @State private var isLoadingInterpretation = false
    @State private var selectedSection: AtlasSection = .chart
    @State private var expandedPlanet: String?
    @State private var selectedPlanet: PlanetPosition?
    @State private var scrollProxy: ScrollViewProxy?

    private let engine = AstrologyEngine.shared
    private let aiService = AIService.shared
    private let insightService = InsightService.shared

    var body: some View {
        AuroraScreen(
            backdropStyle: .atlasGrid,
            eyebrow: String(localized: "atlas.eyebrow"),
            title: String(localized: "atlas.title"),
            subtitle: String(localized: "atlas.subtitle")
        ) {
            HStack(spacing: 10) {
                Button {
                    loadChart(forceRefresh: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AuroraColors.textPrimary)
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AuroraColors.textPrimary)
                }
                .buttonStyle(.plain)
            }
        } content: {
            if isLoadingChart {
                atlasLoadingState
            } else if let chartData {
                atlasContent(chartData)
            } else {
                noDataState
            }
        }
        .onAppear {
            loadChart()
        }
    }

    private var atlasLoadingState: some View {
        VStack(spacing: AuroraSpacing.md) {
            ProgressView()
                .tint(AuroraColors.auroraCyan)
                .scaleEffect(1.3)
            Text("atlas.loading")
                .font(AuroraTypography.body(14))
                .foregroundColor(AuroraColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private func atlasContent(_ chart: ChartData) -> some View {
        ScrollViewReader { proxy in
            VStack(spacing: AuroraSpacing.md) {
                Color.clear
                    .frame(height: 0)
                    .id("atlas-top")

                snapshotHero(chart)

                ChartWheelView(chartData: chart, selectedPlanet: $selectedPlanet)
                    .frame(height: 320)

                atlasSectionPicker

                sectionContent(for: chart)

                interpretationCard(chart)

                Color.clear
                    .frame(height: max(72, chromeMetrics.contentBottomReservedSpace))
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    private func snapshotHero(_ chart: ChartData) -> some View {
        let dominantPlanet = chart.planetPositions.first?.planet.localizedDisplayName ?? String(localized: "home.natal.sun")

        return LumenCard(accent: AuroraColors.auroraCyan) {
            VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                ConstellationHeader(
                    eyebrow: String(localized: "atlas.snapshot.eyebrow"),
                    title: authService.currentUser?.birthData?.sunSign.localizedDisplayName ?? String(localized: "atlas.snapshot.title_fallback"),
                    subtitle: String(format: String(localized: "atlas.snapshot.subtitle_format"), dominantPlanet)
                )

                HStack(spacing: AuroraSpacing.sm) {
                    PrismChip(String(localized: "atlas.snapshot.chart"), icon: "circle.hexagongrid.fill", accent: AuroraColors.auroraCyan, isSelected: true)
                    PrismChip(String(format: String(localized: "atlas.snapshot.transits"), transits.count), icon: "waveform.path.ecg", accent: AuroraColors.auroraMint, isSelected: true)
                    PrismChip(String(format: String(localized: "atlas.snapshot.aspects"), chart.aspects.count), icon: "triangle", accent: AuroraColors.auroraViolet, isSelected: true)
                }
            }
        }
    }

    private var atlasSectionPicker: some View {
        HStack(spacing: AuroraSpacing.sm) {
            ForEach(AtlasSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(reduceMotion ? nil : AuroraMotion.transition) {
                        selectedSection = section
                    }
                } label: {
                    PrismChip(
                        section.title,
                        icon: section.icon,
                        accent: section.accent,
                        isSelected: selectedSection == section
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func sectionContent(for chart: ChartData) -> some View {
        switch selectedSection {
        case .chart:
            chartSection(chart)
        case .transits:
            transitSection
        case .patterns:
            DominantPlanetCard(chart: chart)
            ElementModalityBreakdown(positions: chart.planetPositions)
            ChartPatternCard(chart: chart)
        }
    }

    private func chartSection(_ chart: ChartData) -> some View {
        VStack(spacing: AuroraSpacing.sm) {
            NatalBig3Section(chart: chart)

            ForEach(chart.planetPositions) { position in
                PlanetDetailCard(
                    position: position,
                    isExpanded: expandedPlanet == position.id
                ) {
                    withAnimation(reduceMotion ? nil : AuroraMotion.spring) {
                        expandedPlanet = expandedPlanet == position.id ? nil : position.id
                    }
                }
            }
        }
    }

    private var transitSection: some View {
        VStack(spacing: AuroraSpacing.sm) {
            if transits.isEmpty {
                LumenCard(accent: AuroraColors.auroraMint) {
                    Text("atlas.transits.empty")
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                }
            } else {
                ForEach(transits.prefix(5)) { transit in
                    LumenCard(accent: AuroraColors.auroraMint) {
                        VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                            HStack {
                                Text("\(transit.transitPlanet.localizedDisplayName) \(transit.aspectType.symbol) \(transit.natalPlanet.localizedDisplayName)")
                                    .font(AuroraTypography.bodyStrong(15))
                                    .foregroundColor(AuroraColors.textPrimary)
                                Spacer()
                                Text(transit.severity.localizedDisplayName)
                                    .font(AuroraTypography.mono(11))
                                    .foregroundColor(AuroraColors.auroraMint)
                            }

                            Text(transit.description)
                                .font(AuroraTypography.body(14))
                                .foregroundColor(AuroraColors.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                }
            }
        }
    }

    private func interpretationCard(_ chart: ChartData) -> some View {
        LumenCard(accent: AuroraColors.auroraViolet) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                HStack {
                    Text("atlas.interpretation.title")
                        .font(AuroraTypography.section(18))
                        .foregroundColor(AuroraColors.textPrimary)
                    Spacer()
                    if interpretation == nil || interpretationError != nil {
                        HaloButton(isLoadingInterpretation ? String(localized: "atlas.interpretation.loading_button") : String(localized: "atlas.interpretation.generate"), icon: "sparkles", style: .secondary) {
                            requestInterpretation(chart)
                        }
                        .frame(maxWidth: 140)
                    } else if interpretation != nil {
                        HaloButton(String(localized: "atlas.interpretation.save"), icon: "bookmark.fill", style: .ghost) {
                            saveInterpretationInsight()
                        }
                        .frame(maxWidth: 140)
                    }
                }

                if let interpretation {
                    Text(interpretation)
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineSpacing(4)
                } else if let interpretationError {
                    Text(interpretationError)
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.auroraRose)
                } else {
                    Text("atlas.interpretation.empty")
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                }
            }
        }
    }

    private var noDataState: some View {
        LumenCard(accent: AuroraColors.auroraRose) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                Text("atlas.no_data.title")
                    .font(AuroraTypography.section(18))
                    .foregroundColor(AuroraColors.textPrimary)
                Text("atlas.no_data.subtitle")
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private func loadChart(forceRefresh: Bool = false) {
        guard let user = authService.currentUser, let birthData = user.birthData else {
            chartData = nil
            transits = []
            interpretation = nil
            isLoadingChart = false
            return
        }

        guard !isLoadingChart else { return }

        isLoadingChart = true
        interpretation = nil
        interpretationError = nil

        Task {
            if !forceRefresh, let cached = try? await FirestoreService.shared.getChartData(userId: user.id, type: .natal) {
                await MainActor.run {
                    chartData = cached
                    transits = engine.calculateCurrentTransits(natalChart: cached)
                    isLoadingChart = false
                }
                return
            }

            let calculated = await engine.calculateNatalChartAsync(birthData: birthData)
            try? await FirestoreService.shared.saveChartData(calculated, userId: user.id)

            await MainActor.run {
                chartData = calculated
                transits = engine.calculateCurrentTransits(natalChart: calculated)
                isLoadingChart = false
            }
        }
    }

    private func requestInterpretation(_ chart: ChartData) {
        guard !isLoadingInterpretation, let birthData = authService.currentUser?.birthData else { return }
        guard UsageLimitService.shared.canPerformAction(.natalInterpretation) else { return }

        isLoadingInterpretation = true
        interpretationError = nil

        Task {
            do {
                let result = try await aiService.interpretNatalChart(chartData: chart, birthData: birthData)
                await MainActor.run {
                    interpretation = result
                    isLoadingInterpretation = false
                    UsageLimitService.shared.recordAction(.natalInterpretation)
                }
            } catch {
                await MainActor.run {
                    interpretation = nil
                    interpretationError = String(localized: "atlas.interpretation.error")
                    isLoadingInterpretation = false
                }
            }
        }
    }

    private func saveInterpretationInsight() {
        guard let interpretation, let userId = authService.currentUser?.id else { return }
        insightService.saveInsight(
            SavedInsight(
                userId: userId,
                sourceType: .chart,
                sourceRefId: chartData?.id ?? UUID().uuidString,
                title: String(localized: "atlas.insight.title"),
                summary: String(interpretation.prefix(220)),
                accentKey: "atlas"
            )
        )
    }

}

private enum AtlasSection: CaseIterable {
    case chart
    case transits
    case patterns

    var title: String {
        switch self {
        case .chart:
            return String(localized: "atlas.section.chart")
        case .transits:
            return String(localized: "atlas.section.transits")
        case .patterns:
            return String(localized: "atlas.section.patterns")
        }
    }

    var icon: String {
        switch self {
        case .chart:
            return "circle.hexagongrid.fill"
        case .transits:
            return "waveform.path.ecg"
        case .patterns:
            return "sparkles"
        }
    }

    var accent: Color {
        switch self {
        case .chart:
            return AuroraColors.auroraCyan
        case .transits:
            return AuroraColors.auroraMint
        case .patterns:
            return AuroraColors.auroraViolet
        }
    }
}
