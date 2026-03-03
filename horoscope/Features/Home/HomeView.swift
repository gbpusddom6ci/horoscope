import SwiftUI

struct HomeView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mainChromeMetrics) private var chromeMetrics

    @State private var hasCompletedFirstValue = false
    @State private var firstValueChecked = false
    @State private var currentTransits: [TransitEvent] = []
    @State private var natalChart: ChartData?
    @State private var showPalmReading = false
    @State private var showTarot = false
    @State private var isDailyEnergyExpanded = true
    @State private var isNatalSummaryExpanded = true
    @State private var showAllTransits = false
    @State private var scrollProxy: ScrollViewProxy?

    private let chatService = ChatService.shared
    private let dreamService = DreamService.shared

    private var featureColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: MysticSpacing.sm),
            GridItem(.flexible(), spacing: MysticSpacing.sm)
        ]
    }

    private var birthData: BirthData? {
        authService.currentUser?.birthData
    }

    private var sunSign: ZodiacSign? {
        birthData?.sunSign
    }

    private var shouldShowFirstValueActions: Bool {
        birthData != nil && firstValueChecked && !hasCompletedFirstValue
    }

    private var transitSpotlight: TransitEvent? {
        currentTransits.first
    }

    private var remainingTransits: [TransitEvent] {
        Array(currentTransits.dropFirst())
    }

    private var visibleTransits: [TransitEvent] {
        showAllTransits ? remainingTransits : Array(remainingTransits.prefix(2))
    }

    var body: some View {
        ZStack {
            StarField(starCount: 60)

            VStack(spacing: 0) {
                MysticTopBar("tab.home") {
                    Button {
                        AppNavigation.openQuickActionsSheet()
                    } label: {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(MysticColors.mysticGold)
                    }
                    .accessibilityLabel(Text(String(localized: "quick_actions.title")))
                    .accessibilityHint(Text(String(localized: "quick_actions.hint")))
                    .accessibilityIdentifier("home.quick_actions")
                }

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: MysticSpacing.lg) {
                            Color.clear
                                .frame(height: 0)
                                .id("home_top")

                            greetingSection
                                .fadeInOnAppear(delay: 0)

                            dailyFocusCard
                                .fadeInOnAppear(delay: 0.05)

                            if shouldShowFirstValueActions {
                                firstValueActionCard
                                    .fadeInOnAppear(delay: 0.1)
                            }

                            dailyEnergyCard
                                .fadeInOnAppear(delay: 0.15)

                            if let spotlight = transitSpotlight {
                                transitSpotlightCard(transit: spotlight)
                                    .fadeInOnAppear(delay: 0.2)
                            }

                            featureGridSection
                                .fadeInOnAppear(delay: 0.25)

                            if let birthData, let chart = natalChart {
                                quickStatsSection(birthData: birthData, chart: chart)
                                    .fadeInOnAppear(delay: 0.3)
                            }

                            if !remainingTransits.isEmpty {
                                transitSection
                                    .fadeInOnAppear(delay: 0.35)
                            }

                            Color.clear.frame(height: max(90, chromeMetrics.contentBottomReservedSpace))
                        }
                        .padding(.horizontal, MysticLayout.screenHorizontalPadding)
                        .padding(.top, MysticSpacing.sm)
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
            }
        }
        .task(id: authService.currentUser?.id) {
            loadData()
            await refreshFirstValueState()
        }
        .onAppear {
            if AppNavigation.consumePendingPalmQuickAction() {
                showPalmReading = true
            }
            if AppNavigation.consumePendingTarotQuickAction() {
                showTarot = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPalmQuickAction)) { _ in
            _ = AppNavigation.consumePendingPalmQuickAction()
            showPalmReading = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTarotQuickAction)) { _ in
            _ = AppNavigation.consumePendingTarotQuickAction()
            showTarot = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard let tab = notification.object as? AppTab, tab == .home else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                scrollProxy?.scrollTo("home_top", anchor: .top)
            }
        }
        .sheet(isPresented: $showPalmReading) {
            PalmReadingView()
                .environment(authService)
        }
        .sheet(isPresented: $showTarot) {
            TarotView()
                .environment(authService)
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                    Text(greetingText)
                        .font(MysticFonts.caption(14))
                        .foregroundColor(MysticColors.textSecondary)

                    HStack(spacing: MysticSpacing.sm) {
                        if let sign = sunSign {
                            ZodiacSymbol(sign, size: 28, color: sign.elementColor)
                        }
                        Text(authService.currentUser?.displayName ?? String(localized: "common.user"))
                            .font(MysticTypographyRoles.hero)
                            .foregroundColor(MysticColors.textPrimary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [MysticColors.neonLavender.opacity(0.18), MysticColors.neonLavender.opacity(0.05)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 26
                            )
                        )
                        .frame(width: 50, height: 50)
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [MysticColors.neonLavender.opacity(0.4), MysticColors.stardust.opacity(0.2), MysticColors.celestialPink.opacity(0.3), MysticColors.neonLavender.opacity(0.4)],
                                center: .center
                            ),
                            lineWidth: 1.2
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(MysticColors.neonLavender)
                }
            }
        }
    }

    // MARK: - Daily Focus

    private var dailyFocusCard: some View {
        MysticCard(glowColor: MysticColors.neonLavender) {
            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: "Daily Focus")
                            .font(MysticTypographyRoles.section)
                            .foregroundColor(MysticColors.textPrimary)

                        Text(Date().formatted(as: "d MMMM, EEEE"))
                            .font(MysticTypographyRoles.metadata)
                            .foregroundColor(MysticColors.textMuted)
                    }

                    Spacer()

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 20))
                        .foregroundColor(MysticColors.neonLavender)
                        .padding(9)
                        .background(MysticColors.neonLavender.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md, style: .continuous))
                }

                Text(dailyFocusMessage)
                    .font(MysticTypographyRoles.cardBody)
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(4)

                HStack(spacing: MysticSpacing.sm) {
                    MysticButton("Ask the Oracle", icon: "bubble.left.and.bubble.right.fill", style: .secondary, size: .compact) {
                        AppNavigation.switchToTab(.chat)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            AppNavigation.openChat(context: .general, prompt: String(localized: "home.first_value.chat_prompt"))
                        }
                    }

                    MysticButton("Tarot Draw", icon: "suit.diamond.fill", style: .ghost, size: .compact) {
                        showTarot = true
                    }
                }
            }
        }
    }

    // MARK: - First Value

    private var firstValueActionCard: some View {
        MysticCard(glowColor: MysticColors.auroraGreen) {
            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: "sparkles")
                        .foregroundColor(MysticColors.auroraGreen)
                    Text("home.first_value.title")
                        .font(MysticFonts.heading(16))
                        .foregroundColor(MysticColors.textPrimary)
                }

                Text("home.first_value.subtitle")
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(2)

                MysticButton(
                    String(localized: "home.first_value.chat_button"),
                    icon: "bubble.left.and.bubble.right.fill",
                    style: .primary
                ) {
                    openFirstChatAction()
                }
                .accessibilityHint(Text(String(localized: "home.first_value.chat_hint")))

                Button(String(localized: "home.first_value.dream_button")) {
                    openFirstDreamAction()
                }
                .buttonStyle(.plain)
                .font(MysticFonts.caption(13))
                .foregroundColor(MysticColors.textMuted)
                .frame(minHeight: MysticAccessibility.minimumTapTarget, alignment: .leading)
                .accessibilityHint(Text(String(localized: "home.first_value.dream_hint")))
            }
        }
    }

    // MARK: - Daily Energy

    private var dailyEnergyCard: some View {
        MysticCard(glowColor: MysticColors.mysticGold) {
            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(MysticColors.mysticGold)

                    Text("home.energy.title")
                        .font(MysticFonts.heading(18))
                        .foregroundColor(MysticColors.textPrimary)

                    Spacer()

                    Text(Date().formatted(as: "d MMMM"))
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textMuted)

                    sectionToggleButton(isExpanded: $isDailyEnergyExpanded)
                }

                if isDailyEnergyExpanded {
                    if let sign = sunSign {
                        Text(String(format: String(localized: "home.energy.personalized_format"), sign.symbol, sign.localizedDisplayName))
                            .font(MysticFonts.mystic(15))
                            .foregroundColor(MysticColors.textSecondary)
                            .lineSpacing(4)
                    } else {
                        Text("home.energy.fallback")
                            .font(MysticFonts.mystic(15))
                            .foregroundColor(MysticColors.textSecondary)
                            .lineSpacing(4)
                    }

                    // Placeholder energy values; replace with API/calculation when available.
                    HStack(spacing: MysticSpacing.md) {
                        EnergyBar(label: String(localized: "home.energy.love"), value: 0.7, color: MysticColors.celestialPink)
                        EnergyBar(label: String(localized: "home.energy.career"), value: 0.85, color: MysticColors.mysticGold)
                        EnergyBar(label: String(localized: "home.energy.health"), value: 0.6, color: MysticColors.auroraGreen)
                    }
                    .transition(reduceMotion ? .identity : .opacity)
                }
            }
        }
    }

    // MARK: - Transit Spotlight

    private func transitSpotlightCard(transit: TransitEvent) -> some View {
        MysticCard(glowColor: MysticColors.celestialPink) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: "scope")
                        .foregroundColor(MysticColors.celestialPink)
                    Text(verbatim: "Transit Spotlight")
                        .font(MysticTypographyRoles.cardTitle)
                        .foregroundColor(MysticColors.textPrimary)
                    Spacer()
                    Text(transit.severity.localizedDisplayName)
                        .font(MysticTypographyRoles.metadata)
                        .foregroundColor(MysticColors.celestialPink)
                }

                Text(verbatim: "\(transit.transitPlanet.symbol) \(transit.aspectType.symbol) \(transit.natalPlanet.symbol)")
                    .font(MysticTypographyRoles.section)
                    .foregroundColor(MysticColors.textPrimary)

                Text(transit.description)
                    .font(MysticTypographyRoles.cardBody)
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(3)

                Text(String(format: String(localized: "home.transit.exact_date"), transit.exactDate.formatted(as: "d MMM yyyy")))
                    .font(MysticTypographyRoles.metadata)
                    .foregroundColor(MysticColors.textMuted)
            }
        }
    }

    // MARK: - Natal Summary

    private func quickStatsSection(birthData: BirthData, chart: ChartData) -> some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            HStack {
                Text("home.natal.title")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)

                Spacer()
                sectionToggleButton(isExpanded: $isNatalSummaryExpanded)
            }

            if isNatalSummaryExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MysticSpacing.sm) {
                        StatCard(
                            label: String(localized: "home.natal.sun"),
                            value: birthData.sunSign.localizedDisplayName,
                            icon: "sun.max.fill",
                            color: MysticColors.mysticGold
                        )
                        .frame(width: 110)

                        if let moonPos = chart.planetPositions.first(where: { $0.planet == .moon }) {
                            StatCard(
                                label: String(localized: "home.natal.moon"),
                                value: moonPos.sign.localizedDisplayName,
                                icon: "moon.fill",
                                color: MysticColors.neonLavender
                            )
                            .frame(width: 110)
                        }

                        if let firstHouse = chart.houseCusps.first {
                            StatCard(
                                label: String(localized: "home.natal.ascendant"),
                                value: firstHouse.sign.localizedDisplayName,
                                icon: "arrow.up.circle.fill",
                                color: MysticColors.auroraGreen
                            )
                            .frame(width: 110)
                        }

                        if let mercuryPos = chart.planetPositions.first(where: { $0.planet == .mercury }) {
                            StatCard(
                                label: String(localized: "home.natal.mercury"),
                                value: mercuryPos.sign.localizedDisplayName,
                                icon: "circle.fill",
                                color: MysticColors.celestialPink
                            )
                            .frame(width: 110)
                        }
                    }
                }
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
    }

    // MARK: - Transits

    private var transitSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            HStack {
                Text(verbatim: "Transit Queue")
                    .font(MysticTypographyRoles.section)
                    .foregroundColor(MysticColors.textPrimary)

                Spacer()

                Text(verbatim: "\(remainingTransits.count)")
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.mysticGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(MysticColors.mysticGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            ForEach(visibleTransits) { transit in
                TransitCard(transit: transit)
            }

            if remainingTransits.count > 2 {
                Button(showAllTransits ? String(localized: "home.transits.show_less") : String(localized: "home.transits.show_all")) {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        showAllTransits.toggle()
                    }
                }
                .buttonStyle(.plain)
                .font(MysticFonts.caption(13))
                .foregroundColor(MysticColors.neonLavender)
                .frame(minHeight: MysticAccessibility.minimumTapTarget)
            }
        }
    }

    // MARK: - Explore Grid

    private var featureGridSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text(verbatim: "Quick Rituals")
                .font(MysticTypographyRoles.section)
                .foregroundColor(MysticColors.textPrimary)

            LazyVGrid(columns: featureColumns, spacing: MysticSpacing.sm) {
                HomeQuickFeatureTile(
                    id: "home.feature.chat",
                    icon: "bubble.left.and.bubble.right.fill",
                    title: String(localized: "home.explore.chat"),
                    subtitle: String(localized: "home.explore.chat.subtitle"),
                    color: MysticColors.auroraGreen
                ) {
                    AppNavigation.switchToTab(.chat)
                }

                HomeQuickFeatureTile(
                    id: "home.feature.dream",
                    icon: "moon.zzz.fill",
                    title: String(localized: "home.explore.dream"),
                    subtitle: String(localized: "home.explore.dream.subtitle"),
                    color: MysticColors.celestialPink
                ) {
                    AppNavigation.switchToTab(.dream)
                }

                HomeQuickFeatureTile(
                    id: "home.feature.palm",
                    icon: "hand.raised.fill",
                    title: String(localized: "home.explore.palm"),
                    subtitle: String(localized: "home.explore.palm.subtitle"),
                    color: MysticColors.neonLavender
                ) {
                    showPalmReading = true
                }

                HomeQuickFeatureTile(
                    id: "home.feature.tarot",
                    icon: "suit.diamond.fill",
                    title: String(localized: "home.explore.tarot"),
                    subtitle: String(localized: "home.explore.tarot.subtitle"),
                    color: MysticColors.mysticGold
                ) {
                    showTarot = true
                }
            }
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return String(localized: "home.greeting.morning")
        case 12..<18:
            return String(localized: "home.greeting.day")
        case 18..<22:
            return String(localized: "home.greeting.evening")
        default:
            return String(localized: "home.greeting.night")
        }
    }

    private var dailyFocusMessage: String {
        if let sign = sunSign {
            return "\(sign.symbol) \(sign.localizedDisplayName): Stay patient and intentional today. A short ritual can unlock clarity."
        }
        return "Breathe, ground your energy, and choose one intentional action before noon."
    }

    private func sectionToggleButton(isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            Image(systemName: isExpanded.wrappedValue ? "chevron.up.circle.fill" : "chevron.down.circle")
                .font(.system(size: 18))
                .foregroundColor(MysticColors.textMuted)
        }
        .buttonStyle(.plain)
        .frame(minWidth: MysticAccessibility.minimumTapTarget, minHeight: MysticAccessibility.minimumTapTarget)
        .accessibilityLabel(Text(String(localized: "common.expand_collapse")))
    }

    private func openFirstChatAction() {
        AppNavigation.switchToTab(.chat)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            AppNavigation.openChat(
                context: .general,
                prompt: String(localized: "home.first_value.chat_prompt")
            )
        }
    }

    private func openFirstDreamAction() {
        AppNavigation.switchToTab(.dream)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            AppNavigation.openDreamComposer()
        }
    }

    private func loadData() {
        guard let birthData else { return }

        Task {
            natalChart = await AstrologyEngine.shared.calculateNatalChartAsync(birthData: birthData)

            if let chart = natalChart {
                currentTransits = AstrologyEngine.shared.calculateCurrentTransits(natalChart: chart)
            }
        }
    }

    private func refreshFirstValueState() async {
        guard let userId = authService.currentUser?.id else {
            firstValueChecked = true
            hasCompletedFirstValue = false
            return
        }

        await chatService.loadSessions(for: userId)
        await dreamService.loadEntries(for: userId)

        let hasFirstChat = chatService.hasUserMessages(for: userId)
        let hasFirstDream = dreamService.hasEntries(for: userId)
        hasCompletedFirstValue = hasFirstChat || hasFirstDream
        firstValueChecked = true
    }
}

private struct HomeQuickFeatureTile: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            MysticCard(glowColor: color) {
                VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: MysticRadius.md, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [color.opacity(0.28), color.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(color)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(color.opacity(0.5))
                            .padding(6)
                            .background(color.opacity(0.08))
                            .clipShape(Circle())
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(MysticTypographyRoles.cardTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(MysticColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(subtitle)
                            .font(MysticTypographyRoles.metadata)
                            .foregroundColor(MysticColors.textSecondary)
                            .lineLimit(2)
                            .frame(maxHeight: 30, alignment: .topLeading)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            }
            .scaleEffect(isPressed ? MysticEffects.cardPressedScale : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if reduceMotion { isPressed = true }
                    else { withAnimation(.spring(response: MysticMotion.springResponse, dampingFraction: MysticMotion.springDamping)) { isPressed = true } }
                }
                .onEnded { _ in
                    if reduceMotion { isPressed = false }
                    else { withAnimation(.spring(response: MysticMotion.springResponse, dampingFraction: MysticMotion.springDamping)) { isPressed = false } }
                }
        )
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(String(localized: "home.explore.item.hint")))
        .accessibilityIdentifier(id)
    }
}

// MARK: - Energy Bar
struct EnergyBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let label: String
    let value: Double
    let color: Color
    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(spacing: MysticSpacing.xs + 2) {
            Text(label)
                .font(MysticFonts.caption(11))
                .foregroundColor(MysticColors.textMuted)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))
                        .frame(height: 7)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * animatedValue), height: 7)
                        .shadow(color: color.opacity(0.3), radius: 4, y: 1)
                }
            }
            .frame(height: 7)

            Text(verbatim: "\(Int(value * 100))%")
                .font(MysticFonts.mono(11))
                .foregroundColor(color)
        }
        .onAppear {
            if reduceMotion {
                animatedValue = value
            } else {
                withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
                    animatedValue = value
                }
            }
        }
    }
}

// MARK: - Transit Card
struct TransitCard: View {
    let transit: TransitEvent

    var body: some View {
        MysticCard(glowColor: transitColor) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack {
                    Text(transit.severity.emoji)
                    Text(verbatim: "\(transit.transitPlanet.symbol) \(transit.aspectType.symbol) \(transit.natalPlanet.symbol)")
                        .font(MysticFonts.heading(16))
                        .foregroundColor(MysticColors.textPrimary)
                    Spacer()
                    Text(String(format: String(localized: "home.transit.duration_days"), transit.durationDays))
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MysticColors.inputBackground)
                        .clipShape(Capsule())
                }

                Text(transit.description)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(2)

                HStack {
                    Text(String(format: String(localized: "home.transit.exact_date"), transit.exactDate.formatted(as: "d MMM yyyy")))
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textMuted)
                    Spacer()
                    Text(transit.severity.localizedDisplayName)
                        .font(MysticFonts.caption(11))
                        .foregroundColor(transitColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(transitColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var transitColor: Color {
        switch transit.severity {
        case .low: return MysticColors.auroraGreen
        case .medium: return MysticColors.mysticGold
        case .high: return MysticColors.transitOrange
        case .critical: return MysticColors.celestialPink
        }
    }
}

#Preview {
    let authService = AuthService()
    HomeView()
        .environment(authService)
}
