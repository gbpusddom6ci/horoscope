import SwiftUI

struct SanctumView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showDreamComposer = false
    @State private var showPalm = false
    @State private var showAtlas = false
    @State private var transitSpotlight: TransitEvent?
    @State private var chartData: ChartData?
    @State private var scrollProxy: ScrollViewProxy?

    private let chatService = ChatService.shared
    private let dreamService = DreamService.shared
    private let insightService = InsightService.shared
    private let ritualService = RitualService.shared
    private let astrologyEngine = AstrologyEngine.shared

    private var userId: String? {
        authService.currentUser?.id
    }

    private var latestSession: ChatSession? {
        guard let userId else { return nil }
        return chatService.sessionsForUser(userId).first
    }

    private var latestDream: DreamEntry? {
        guard let userId else { return nil }
        return dreamService.entriesForUser(userId).first
    }

    private var latestInsight: SavedInsight? {
        guard let userId else { return nil }
        return insightService.insightsForUser(userId).first
    }

    private var ritualState: DailyRitualState? {
        guard let userId else { return nil }
        return ritualService.state(for: userId)
    }

    private var greetingName: String {
        authService.currentUser?.displayName ?? String(localized: "common.mystic")
    }

    private var guidanceTitle: String {
        authService.currentUser?.guidanceIntent?.title ?? String(localized: "guidance.intent.clarity.title")
    }

    private var ritualProgress: Double {
        guard let ritualState else { return 0 }
        let completed = [
            ritualState.morningCheckInCompleted,
            ritualState.eveningReflectionCompleted,
            ritualState.dreamCaptured
        ]
        .filter { $0 }
        return Double(completed.count) / 3
    }

    private var sunSignName: String {
        authService.currentUser?.birthData?.sunSign.localizedDisplayName ?? String(localized: "home.sun_sign_fallback")
    }

    private var ascendantName: String {
        chartData?.houseCusps.first?.sign.localizedDisplayName ?? String(localized: "common.unknown")
    }

    private var moonSignName: String {
        chartData?.planetPositions.first(where: { $0.planet == .moon })?.sign.localizedDisplayName ?? String(localized: "common.unknown")
    }

    private var dailyAuraText: String {
        switch authService.currentUser?.guidanceIntent ?? .clarity {
        case .clarity:
            return String(localized: "home.daily_aura.clarity")
        case .love:
            return String(localized: "home.daily_aura.love")
        case .career:
            return String(localized: "home.daily_aura.career")
        case .healing:
            return String(localized: "home.daily_aura.healing")
        }
    }

    var body: some View {
        ZStack {
            AuroraBackdrop(style: .sanctumGlow)

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                        Color.clear
                            .frame(height: 0)
                            .id("home-top")

                        homeHeader
                        cosmicDashboardCard
                        quickActionGrid
                        natalSnapshotCard

                        if let transitSpotlight {
                            transitPulseCard(transitSpotlight)
                        }

                        reflectionCards

                        Color.clear
                            .frame(height: max(92, chromeMetrics.contentBottomReservedSpace))
                    }
                    .padding(.horizontal, AuroraSpacing.md)
                    .padding(.top, AuroraSpacing.md)
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }
        }
        .accessibilityIdentifier("home.screen")
        .task(id: userId) {
            await loadState()
            presentPendingFlowsIfNeeded()
        }
        .onAppear {
            presentPendingFlowsIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPalmQuickAction)) { _ in
            _ = AppNavigation.consumePendingPalmQuickAction()
            showPalm = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAtlasExperience)) { _ in
            _ = AppNavigation.consumePendingAtlasExperience()
            showAtlas = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard targetDestination(from: notification) == .home else { return }
            withAnimation(reduceMotion ? nil : AuroraMotion.transition) {
                scrollProxy?.scrollTo("home-top", anchor: .top)
            }
        }
        .fullScreenCover(isPresented: $showDreamComposer) {
            NewDreamSheet {
                guard let userId else { return }
                ritualService.markDreamCaptured(for: userId)
            }
            .environment(authService)
        }
        .fullScreenCover(isPresented: $showAtlas) {
            AtlasView()
                .environment(authService)
        }
        .sheet(isPresented: $showPalm) {
            PalmReadingView()
                .environment(authService)
        }
    }

    private var homeHeader: some View {
        HStack(alignment: .top, spacing: AuroraSpacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: String(localized: "home.greeting.format"), greetingName))
                    .font(AuroraTypography.hero(40))
                    .foregroundColor(AuroraColors.textPrimary)
                    .accessibilityIdentifier("home.greeting")

                Text("home.header.subtitle")
                    .font(AuroraTypography.body(15))
                    .foregroundColor(AuroraColors.textSecondary)
                    .lineSpacing(4)

                HStack(spacing: AuroraSpacing.sm) {
                    PrismChip(sunSignName, icon: "sun.max.fill", accent: AuroraColors.auroraMint, isSelected: true)
                    PrismChip(guidanceTitle, icon: "sparkles", accent: AuroraColors.auroraViolet, isSelected: false)
                }
            }

            Spacer()

            Button {
                AppNavigation.openQuickActionsSheet()
            } label: {
                ZStack {
                    Circle()
                        .fill(AuroraSurfaceLevel.elevated.fillStyle)
                        .frame(width: 52, height: 52)

                    AuroraGlyph(kind: .saturn, color: AuroraColors.auroraMint, lineWidth: 1.9)
                        .frame(width: 24, height: 24)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("home.header.oracle_accessibility"))
            .accessibilityIdentifier("quick_actions.button")
        }
        .padding(.top, 4)
    }

    private var cosmicDashboardCard: some View {
        LumenCard(accent: AuroraColors.auroraMint) {
            VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                ConstellationHeader(
                    eyebrow: Date().formatted(as: "EEEE, d MMM"),
                    title: String(localized: "home.dashboard.title"),
                    subtitle: dailyAuraText
                )

                HStack(spacing: AuroraSpacing.sm) {
                    metricChip(title: String(localized: "home.metric.aura"), value: "\(Int(ritualProgress * 100))%", accent: AuroraColors.auroraMint)
                    metricChip(title: String(localized: "home.metric.moon"), value: moonSignName, accent: AuroraColors.auroraViolet)
                    metricChip(title: String(localized: "home.metric.asc"), value: ascendantName, accent: AuroraColors.auroraCyan)
                }

                RitualMeter(
                    progress: ritualProgress,
                    title: String(localized: "home.ritual.title"),
                    subtitle: ritualProgress >= 1
                        ? String(localized: "home.ritual.complete")
                        : String(localized: "home.ritual.incomplete"),
                    accent: AuroraColors.auroraMint
                )

                HStack(spacing: AuroraSpacing.sm) {
                    HaloButton(String(localized: "home.dashboard.ask_ai"), icon: "sparkles") {
                        AppNavigation.openChat(
                            context: .general,
                            prompt: "Read today's energy for me through my natal chart and suggest one grounding ritual."
                        )
                    }
                    .accessibilityIdentifier("home.ask_ai.cta")

                    HaloButton(String(localized: "home.dashboard.open_atlas"), icon: "arrow.right", style: .secondary) {
                        showAtlas = true
                    }
                    .accessibilityIdentifier("home.atlas.cta")
                }
            }
        }
    }

    private var quickActionGrid: some View {
        VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
            Text("home.experiences.title")
                .font(AuroraTypography.section(18))
                .foregroundColor(AuroraColors.textPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AuroraSpacing.sm),
                    GridItem(.flexible(), spacing: AuroraSpacing.sm)
                ],
                spacing: AuroraSpacing.sm
            ) {
                portalCard(
                    title: String(localized: "home.experience.palm.title"),
                    subtitle: String(localized: "home.experience.palm.subtitle"),
                    accent: AuroraColors.auroraViolet,
                    glyph: .profile,
                    accessibilityIdentifier: "home.palm.cta"
                ) {
                    showPalm = true
                }

                portalCard(
                    title: String(localized: "home.experience.tarot.title"),
                    subtitle: String(localized: "home.experience.tarot.subtitle"),
                    accent: AuroraColors.auroraRose,
                    glyph: .tarot,
                    accessibilityIdentifier: "home.tarot.cta"
                ) {
                    AppNavigation.switchToDestination(.tarot)
                }

                portalCard(
                    title: String(localized: "home.experience.dream.title"),
                    subtitle: String(localized: "home.experience.dream.subtitle"),
                    accent: AuroraColors.auroraCyan,
                    glyph: .dreamcatcher,
                    accessibilityIdentifier: "home.dreams.cta"
                ) {
                    showDreamComposer = true
                }

                portalCard(
                    title: String(localized: "home.experience.oracle.title"),
                    subtitle: String(localized: "home.experience.oracle.subtitle"),
                    accent: AuroraColors.auroraMint,
                    glyph: .eye,
                    accessibilityIdentifier: "home.oracle.cta"
                ) {
                    AppNavigation.switchToDestination(.oracle)
                }
            }
        }
    }

    private var natalSnapshotCard: some View {
        LumenCard(accent: AuroraColors.auroraCyan) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                HStack(alignment: .top) {
                    ConstellationHeader(
                        eyebrow: String(localized: "home.natal.eyebrow"),
                        title: String(format: String(localized: "home.natal.title_format"), sunSignName),
                        subtitle: String(localized: "home.natal.subtitle")
                    )

                    Spacer(minLength: 0)
                }

                HStack(spacing: AuroraSpacing.sm) {
                    statPill(symbol: "☉", title: String(localized: "home.natal.sun"), value: sunSignName)
                    statPill(symbol: "☽", title: String(localized: "home.natal.moon"), value: moonSignName)
                    statPill(symbol: "AC", title: String(localized: "home.natal.asc"), value: ascendantName)
                }

                if let latestInsight {
                    Divider()
                        .overlay(AuroraColors.hairline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("home.natal.last_insight")
                            .font(AuroraTypography.mono(11))
                            .foregroundColor(AuroraColors.textMuted)
                        Text(latestInsight.title)
                            .font(AuroraTypography.bodyStrong(14))
                            .foregroundColor(AuroraColors.textPrimary)
                        Text(latestInsight.summary)
                            .font(AuroraTypography.body(13))
                            .foregroundColor(AuroraColors.textSecondary)
                            .lineLimit(3)
                    }
                }
            }
        }
    }

    private func transitPulseCard(_ transit: TransitEvent) -> some View {
        LumenCard(accent: AuroraColors.auroraViolet) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                HStack {
                    Text("home.transit.title")
                        .font(AuroraTypography.section(18))
                        .foregroundColor(AuroraColors.textPrimary)

                    Spacer()

                    PrismChip(
                        transit.severity.localizedDisplayName,
                        icon: "waveform.path.ecg",
                        accent: AuroraColors.auroraViolet,
                        isSelected: true
                    )
                }

                Text("\(transit.transitPlanet.localizedDisplayName) \(transit.aspectType.symbol) \(transit.natalPlanet.localizedDisplayName)")
                    .font(AuroraTypography.bodyStrong(16))
                    .foregroundColor(AuroraColors.textPrimary)

                Text(transit.description.isEmpty ? String(localized: "home.transit.fallback") : transit.description)
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)
                    .lineSpacing(4)

                HStack(spacing: AuroraSpacing.sm) {
                    HaloButton(String(localized: "home.transit.decode"), icon: "sparkles", style: .secondary) {
                        AppNavigation.openChat(
                            context: .transit,
                            prompt: "Interpret my most active transit right now and tell me how to work with it."
                        )
                    }

                    HaloButton(String(localized: "home.transit.open_atlas"), icon: "arrow.right", style: .ghost) {
                        showAtlas = true
                    }
                }
            }
        }
    }

    private var reflectionCards: some View {
        VStack(spacing: AuroraSpacing.sm) {
            LumenCard(accent: AuroraColors.auroraRose) {
                VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                    Text(latestDream == nil ? String(localized: "home.dream.empty_title") : String(localized: "home.dream.return_title"))
                        .font(AuroraTypography.section(18))
                        .foregroundColor(AuroraColors.textPrimary)

                    Text(latestDream?.dreamText ?? String(localized: "home.dream.empty_body"))
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineSpacing(4)
                        .lineLimit(3)

                    HStack(spacing: AuroraSpacing.sm) {
                        HaloButton(String(localized: "home.dream.write"), icon: "moon.zzz") {
                            showDreamComposer = true
                        }

                        HaloButton(String(localized: "home.dream.open_journal"), icon: "arrow.right", style: .ghost) {
                            AppNavigation.switchToDestination(.dreams)
                        }
                    }
                }
            }

            LumenCard(accent: AuroraColors.polarWhite) {
                VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                    Text(latestSession == nil ? String(localized: "home.oracle.empty_title") : String(localized: "home.oracle.return_title"))
                        .font(AuroraTypography.section(18))
                        .foregroundColor(AuroraColors.textPrimary)

                    Text(latestSession?.lastMessagePreview ?? String(localized: "home.oracle.empty_body"))
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineSpacing(4)
                        .lineLimit(3)

                    HaloButton(String(localized: "home.oracle.enter"), icon: "sparkles") {
                        if let latestSession {
                            AppNavigation.openChat(context: latestSession.context)
                        } else {
                            AppNavigation.openChat(context: .general)
                        }
                    }
                }
            }
        }
    }

    private func metricChip(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(AuroraTypography.mono(10))
                .foregroundColor(AuroraColors.textMuted)
            Text(value)
                .font(AuroraTypography.bodyStrong(13))
                .foregroundColor(AuroraColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AuroraRadius.sm, style: .continuous)
                .fill(AuroraSurfaceLevel.elevated.fillStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: AuroraRadius.sm, style: .continuous)
                        .stroke(accent.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func portalCard(
        title: String,
        subtitle: String,
        accent: Color,
        glyph: AuroraGlyphKind,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            LumenCard(accent: accent) {
                VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.16))
                            .frame(width: 46, height: 46)
                        AuroraGlyph(kind: glyph, color: accent, lineWidth: 1.8)
                            .frame(width: 22, height: 22)
                    }

                    Text(title)
                        .font(AuroraTypography.bodyStrong(15))
                        .foregroundColor(AuroraColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(subtitle)
                        .font(AuroraTypography.body(13))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func statPill(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(symbol)
                .font(AuroraTypography.bodyStrong(14))
                .foregroundColor(AuroraColors.auroraCyan)
            Text(title)
                .font(AuroraTypography.mono(10))
                .foregroundColor(AuroraColors.textMuted)
            Text(value)
                .font(AuroraTypography.body(13))
                .foregroundColor(AuroraColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AuroraRadius.sm, style: .continuous)
                .fill(AuroraColors.surface.opacity(0.56))
        )
    }

    private func loadState() async {
        guard let userId else { return }
        await chatService.loadSessions(for: userId)
        await dreamService.loadEntries(for: userId)
        await insightService.loadInsights(for: userId)
        await ritualService.loadState(for: userId)

        if let birthData = authService.currentUser?.birthData {
            let chart = astrologyEngine.calculateNatalChart(birthData: birthData)
            chartData = chart
            transitSpotlight = astrologyEngine.calculateCurrentTransits(natalChart: chart).first
        } else {
            chartData = nil
            transitSpotlight = nil
        }
    }

    private func presentPendingFlowsIfNeeded() {
        if AppNavigation.consumePendingPalmQuickAction() {
            showPalm = true
        }
        if AppNavigation.consumePendingAtlasExperience() {
            showAtlas = true
        }
    }

    private func targetDestination(from notification: Notification) -> AppDestination? {
        if let destination = notification.object as? AppDestination {
            return destination
        }
        if let legacy = notification.object as? AppTab {
            return legacy.destination
        }
        return nil
    }
}
