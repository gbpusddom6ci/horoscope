import SwiftUI
import os

struct NatalChartView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chartData: ChartData?
    @State private var interpretation: String?
    @State private var interpretationErrorMessage: String?
    @State private var isLoadingInterpretation = false
    @State private var isLoadingChart = false
    @State private var selectedPlanet: PlanetPosition?
    @State private var expandedPlanet: String?
    @State private var selectedTab: ChartTab = .planets
    @State private var scrollProxy: ScrollViewProxy?
    @State private var activeInterpretationRequestID: UUID?
    @State private var showAdvancedSummary = false

    private let engine = AstrologyEngine.shared
    private let aiService = AIService.shared
    private let logger = Logger(subsystem: "rk.horoscope", category: "NatalChart")

    enum ChartTab: CaseIterable {
        case planets
        case aspects
        case houses

        var titleKey: LocalizedStringKey {
            switch self {
            case .planets:
                return "natal.tab.planets"
            case .aspects:
                return "natal.tab.aspects"
            case .houses:
                return "natal.tab.houses"
            }
        }
    }

    var body: some View {
        MysticScreenScaffold(
            "natal.title",
            showsBackground: false
        ) {
            Button {
                loadChart(forceRefresh: true)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17))
                    .foregroundColor(MysticColors.neonLavender)
            }
            .disabled(isLoadingChart || isLoadingInterpretation)
            .accessibilityLabel(Text(String(localized: "natal.refresh")))
            .accessibilityHint(Text(String(localized: "natal.refresh.hint")))
            .accessibilityIdentifier("natal.refresh")
        } content: {
            content
        }
        .onAppear { loadChart() }
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard let tab = notification.object as? AppTab, tab == .chart else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollProxy?.scrollTo("chart_top", anchor: .top)
            }
        }
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
            Text("natal.loading")
                .font(MysticFonts.caption(14))
                .foregroundColor(MysticColors.textMuted)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(localized: "natal.loading")))
        .accessibilityIdentifier("natal.loading.state")
    }

    // MARK: - Chart Content
    private func chartContent(chart: ChartData) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MysticSpacing.lg) {
                    Color.clear
                        .frame(height: 0)
                        .id("chart_top")

                    // Chart Wheel
                    ChartWheelView(chartData: chart, selectedPlanet: $selectedPlanet)
                        .frame(height: 330)
                        .fadeInOnAppear(delay: 0)

                    // Big 3 Summary
                    NatalBig3Section(chart: chart)
                        .padding(.horizontal, MysticSpacing.md)
                        .fadeInOnAppear(delay: 0.05)

                    editorialOverviewToggle

                    // Tab Picker + Content
                    NatalTabPicker(selectedTab: $selectedTab)
                        .padding(.horizontal, MysticSpacing.md)
                        .fadeInOnAppear(delay: 0.15)
                        
                    NatalTabContentView(selectedTab: selectedTab, chart: chart, expandedPlanet: $expandedPlanet)
                        .padding(.horizontal, MysticSpacing.md)

                    if showAdvancedSummary {
                        DominantPlanetCard(chart: chart)
                            .padding(.horizontal, MysticSpacing.md)
                            .transition(.opacity)

                        ElementModalityBreakdown(positions: chart.planetPositions)
                            .padding(.horizontal, MysticSpacing.md)
                            .transition(.opacity)

                        ChartPatternCard(chart: chart)
                            .padding(.horizontal, MysticSpacing.md)
                            .transition(.opacity)
                    }

                    // AI Interpretation
                    interpretationSection
                        .fadeInOnAppear(delay: 0.25)

                    Color.clear.frame(height: max(72, chromeMetrics.contentBottomReservedSpace))
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .disableHorizontalScrollBounce()
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    private var editorialOverviewToggle: some View {
        MysticCard(glowColor: MysticColors.neonLavender.opacity(0.85)) {
            HStack(spacing: MysticSpacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: "Chart Signatures")
                        .font(MysticTypographyRoles.cardTitle)
                        .foregroundColor(MysticColors.textPrimary)
                    Text(verbatim: "Dominant planet, element balance, and pattern analysis.")
                        .font(MysticTypographyRoles.metadata)
                        .foregroundColor(MysticColors.textSecondary)
                }

                Spacer()

                Button(showAdvancedSummary ? "Hide" : "Show") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        showAdvancedSummary.toggle()
                    }
                }
                .buttonStyle(.plain)
                .font(MysticTypographyRoles.metadata.weight(.semibold))
                .foregroundColor(MysticColors.neonLavender)
                .frame(minHeight: MysticAccessibility.minimumTapTarget)
            }
        }
        .padding(.horizontal, MysticSpacing.md)
        .fadeInOnAppear(delay: 0.08)
    }

    // MARK: - AI Interpretation
    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            HStack {
                Text("natal.interpretation.title")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)
                Spacer()
                if interpretation == nil || interpretationErrorMessage != nil {
                    let ctaKey = interpretationErrorMessage == nil
                        ? "natal.interpretation.button"
                        : "natal.interpretation.retry"
                    MysticButton(NSLocalizedString(ctaKey, comment: ""), icon: "sparkles", style: .secondary, isLoading: isLoadingInterpretation) {
                        requestInterpretation()
                    }
                    .frame(width: 140)
                    .accessibilityHint(Text(String(localized: "natal.interpretation.hint")))
                    .accessibilityIdentifier("natal.interpretation.cta")
                }
            }

            if let interpretation = interpretation {
                MysticCard(glowColor: MysticColors.mysticGold) {
                    Text(interpretation)
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.textSecondary)
                        .lineSpacing(4)
                }
            } else if isLoadingInterpretation {
                // Skeleton loading state
                MysticStateCard(
                    variant: .loading(messageKey: "natal.interpretation.loading"),
                    accessibilityIdentifier: "natal.interpretation.loading.state"
                )
                .transition(.opacity)
            } else if let interpretationErrorMessage {
                interpretationErrorCard(message: interpretationErrorMessage)
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    private func interpretationErrorCard(message: String) -> some View {
        MysticCard(glowColor: MysticColors.celestialPink) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                Text(message)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.celestialPink)
                    .lineSpacing(3)

                if Self.shouldShowInterpretationRetry(
                    errorMessage: interpretationErrorMessage,
                    isLoading: isLoadingInterpretation
                ) {
                    Button(String(localized: "natal.interpretation.retry")) {
                        requestInterpretation()
                    }
                    .buttonStyle(.plain)
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.neonLavender)
                    .frame(minHeight: MysticAccessibility.minimumTapTarget, alignment: .leading)
                    .accessibilityHint(Text(String(localized: "natal.interpretation.retry.hint")))
                    .accessibilityIdentifier("natal.interpretation.retry")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("natal.interpretation.error")
    }

    // MARK: - No Data View
    private var noBirthDataView: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer().frame(height: 100)
            MysticStateCard(
                variant: .empty(
                    icon: "moon.stars.fill",
                    titleKey: "natal.empty"
                ),
                accessibilityIdentifier: "natal.empty.state"
            )
            .padding(.horizontal, MysticSpacing.md)
            Spacer()
        }
    }

    // MARK: - Actions

    private func loadChart(forceRefresh: Bool = false) {
        guard let user = authService.currentUser, let birthData = user.birthData else {
            chartData = nil
            interpretation = nil
            interpretationErrorMessage = nil
            activeInterpretationRequestID = nil
            isLoadingInterpretation = false
            isLoadingChart = false
            return
        }

        guard !isLoadingChart else { return }

        isLoadingChart = true
        interpretation = nil
        interpretationErrorMessage = nil
        activeInterpretationRequestID = nil
        isLoadingInterpretation = false
        selectedPlanet = nil
        expandedPlanet = nil

        Task {
            if !forceRefresh {
                if let cached = try? await FirestoreService.shared.getChartData(userId: user.id, type: .natal) {
                    await MainActor.run {
                        chartData = cached
                        isLoadingChart = false
                    }
                    return
                }
            }

            let calculatedChart = await engine.calculateNatalChartAsync(birthData: birthData)
            do {
                try await FirestoreService.shared.saveChartData(calculatedChart, userId: user.id)
            } catch {
                logger.error("Chart save failed: \(error.localizedDescription)")
            }

            await MainActor.run {
                chartData = calculatedChart
                isLoadingChart = false
            }
        }
    }

    private func requestInterpretation() {
        guard !isLoadingInterpretation,
              let chart = chartData,
              let birthData = authService.currentUser?.birthData else { return }

        guard UsageLimitService.shared.canPerformAction(.natalInterpretation) else { return }

        let requestID = UUID()
        activeInterpretationRequestID = requestID
        isLoadingInterpretation = true
        interpretationErrorMessage = nil

        Task {
            do {
                let generatedInterpretation = try await aiService.interpretNatalChart(
                    chartData: chart,
                    birthData: birthData
                )
                await MainActor.run {
                    guard activeInterpretationRequestID == requestID else { return }
                    interpretation = generatedInterpretation
                    interpretationErrorMessage = nil
                    UsageLimitService.shared.recordAction(.natalInterpretation)
                }
            } catch {
                await MainActor.run {
                    guard activeInterpretationRequestID == requestID else { return }
                    interpretation = nil
                    interpretationErrorMessage = String(localized: "natal.interpretation.error")
                }
            }

            await MainActor.run {
                guard activeInterpretationRequestID == requestID else { return }
                activeInterpretationRequestID = nil
                isLoadingInterpretation = false
            }
        }
    }

    nonisolated static func shouldShowInterpretationRetry(errorMessage: String?, isLoading: Bool) -> Bool {
        let hasError = !(errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        return hasError && !isLoading
    }
}

