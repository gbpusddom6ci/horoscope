import SwiftUI

struct JournalView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showDreamComposer = false
    @State private var scrollProxy: ScrollViewProxy?

    private let dreamService = DreamService.shared
    private let insightService = InsightService.shared
    private let ritualService = RitualService.shared

    private var userId: String? {
        authService.currentUser?.id
    }

    private var dreams: [DreamEntry] {
        guard let userId else { return [] }
        return dreamService.entriesForUser(userId)
    }

    private var interpretedDreams: [DreamEntry] {
        dreams.filter { $0.interpretation?.isEmpty == false }
    }

    private var insights: [SavedInsight] {
        guard let userId else { return [] }
        return insightService.insightsForUser(userId)
    }

    private var weeklyReflection: WeeklyReflectionSummary {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyDreams = dreams.filter { $0.createdAt >= weekAgo }
        let weeklyInsights = insights.filter { $0.createdAt >= weekAgo }

        let title: String
        if weeklyDreams.count + weeklyInsights.count == 0 {
            title = String(localized: "dreams.weekly_reflection.quiet")
        } else if weeklyDreams.count >= weeklyInsights.count {
            title = String(localized: "dreams.weekly_reflection.leading")
        } else {
            title = String(localized: "dreams.weekly_reflection.crystallizing")
        }

        return WeeklyReflectionSummary(
            id: "weekly-reflection",
            title: title,
            summary: String(format: String(localized: "dreams.weekly_reflection.summary"), weeklyDreams.count, weeklyInsights.count),
            createdAt: Date()
        )
    }

    private var dominantMoodTitle: String {
        let moods = dreams.compactMap(\.mood)
        let grouped = Dictionary(grouping: moods, by: { $0 })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key.localizedDisplayName ?? String(localized: "dreams.dominant_mood.empty")
    }

    var body: some View {
        AuroraScreen(
            backdropStyle: .ambient,
            eyebrow: String(localized: "dreams.screen.eyebrow"),
            title: String(localized: "dreams.screen.title"),
            subtitle: String(localized: "dreams.screen.subtitle")
            ,
            usesScrollView: false
        ) {
            Button {
                showDreamComposer = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AuroraColors.textPrimary)
            }
            .buttonStyle(.plain)
        } content: {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: AuroraSpacing.md) {
                        Color.clear
                            .frame(height: 0)
                            .id("dreams-top")

                        reflectionCard
                        interpretedDreamsCard
                        dreamsSection
                        insightsSection
                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, AuroraSpacing.md)
                    .padding(.top, AuroraSpacing.md)
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }
        }
        .task(id: userId) {
            guard let userId else { return }
            await dreamService.loadEntries(for: userId)
            await insightService.loadInsights(for: userId)
        }
        .fullScreenCover(isPresented: $showDreamComposer) {
            NewDreamSheet {
                guard let userId else { return }
                ritualService.markDreamCaptured(for: userId)
            }
            .environment(authService)
        }
        .onAppear {
            if AppNavigation.consumePendingDreamComposer() {
                showDreamComposer = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDreamComposer)) { _ in
            _ = AppNavigation.consumePendingDreamComposer()
            showDreamComposer = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard targetDestination(from: notification) == .dreams else { return }
            withAnimation(reduceMotion ? nil : AuroraMotion.transition) {
                scrollProxy?.scrollTo("dreams-top", anchor: .top)
            }
        }
    }

    private var reflectionCard: some View {
        LumenCard(accent: AuroraColors.auroraRose) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                ConstellationHeader(
                    eyebrow: String(localized: "dreams.reflection.eyebrow"),
                    title: weeklyReflection.title,
                    subtitle: weeklyReflection.summary
                )

                HStack(spacing: AuroraSpacing.sm) {
                    PrismChip(dominantMoodTitle, icon: "moon.zzz.fill", accent: AuroraColors.auroraRose, isSelected: true)
                    PrismChip(String(format: String(localized: "dreams.reflection.entries"), dreams.count), icon: "sparkles", accent: AuroraColors.auroraViolet, isSelected: false)
                }

                HaloButton(String(localized: "dreams.reflection.write"), icon: "plus.circle.fill") {
                    showDreamComposer = true
                }
            }
        }
    }

    private var interpretedDreamsCard: some View {
        LumenCard(accent: AuroraColors.auroraViolet) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                Text("dreams.interpreted.title")
                    .font(AuroraTypography.section(18))
                    .foregroundColor(AuroraColors.textPrimary)

                if let interpreted = interpretedDreams.first {
                    Text(interpreted.interpretation ?? "")
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineSpacing(4)
                        .lineLimit(4)

                    HaloButton(String(localized: "dreams.interpreted.ask_oracle"), icon: "sparkles", style: .ghost) {
                        AppNavigation.openChat(context: .dream, prompt: interpreted.dreamText)
                    }
                } else {
                    Text("dreams.interpreted.empty")
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                }
            }
        }
    }

    private var dreamsSection: some View {
        VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
            Text("dreams.recent.title")
                .font(AuroraTypography.section(18))
                .foregroundColor(AuroraColors.textPrimary)

            if dreams.isEmpty {
                emptyCard(
                    title: String(localized: "dreams.recent.empty_title"),
                    body: String(localized: "dreams.recent.empty_body")
                )
            } else {
                ForEach(dreams.prefix(6)) { dream in
                    LumenCard(accent: AuroraColors.auroraRose) {
                        VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                            HStack {
                                Text(dream.createdAt.formatted(as: "d MMM · HH:mm"))
                                    .font(AuroraTypography.mono(11))
                                    .foregroundColor(AuroraColors.textMuted)
                                Spacer()
                                if let mood = dream.mood {
                                    PrismChip(mood.localizedDisplayName, icon: "moon.zzz.fill", accent: AuroraColors.auroraRose, isSelected: true)
                                }
                            }

                            Text(dream.dreamText)
                                .font(AuroraTypography.body(14))
                                .foregroundColor(AuroraColors.textPrimary)
                                .lineLimit(4)

                            if let interpretation = dream.interpretation {
                                Text(interpretation)
                                    .font(AuroraTypography.body(13))
                                    .foregroundColor(AuroraColors.textSecondary)
                                    .lineLimit(3)
                            }

                            HStack(spacing: AuroraSpacing.sm) {
                                HaloButton(String(localized: "dreams.recent.ask_oracle"), icon: "sparkles", style: .ghost) {
                                    AppNavigation.openChat(context: .dream, prompt: dream.dreamText)
                                }

                                HaloButton(String(localized: "dreams.recent.write_another"), icon: "plus.circle.fill", style: .secondary) {
                                    showDreamComposer = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
            Text("dreams.saved.title")
                .font(AuroraTypography.section(18))
                .foregroundColor(AuroraColors.textPrimary)

            if insights.isEmpty {
                emptyCard(
                    title: String(localized: "dreams.saved.empty_title"),
                    body: String(localized: "dreams.saved.empty_body")
                )
            } else {
                ForEach(insights.prefix(8)) { insight in
                    LumenCard(accent: accent(for: insight.accentKey)) {
                        VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                            HStack {
                                Text(insight.title)
                                    .font(AuroraTypography.bodyStrong(15))
                                    .foregroundColor(AuroraColors.textPrimary)
                                Spacer()
                                Text(insight.createdAt.formatted(as: "d MMM"))
                                    .font(AuroraTypography.mono(11))
                                    .foregroundColor(AuroraColors.textMuted)
                            }

                            Text(insight.summary)
                                .font(AuroraTypography.body(14))
                                .foregroundColor(AuroraColors.textSecondary)
                                .lineSpacing(4)
                                .lineLimit(4)
                        }
                    }
                }
            }
        }
    }

    private func emptyCard(title: String, body: String) -> some View {
        LumenCard(accent: AuroraColors.auroraViolet) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                Text(title)
                    .font(AuroraTypography.bodyStrong(15))
                    .foregroundColor(AuroraColors.textPrimary)
                Text(body)
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)
            }
        }
    }

    private func accent(for key: String) -> Color {
        switch key {
        case "atlas":
            return AuroraColors.auroraCyan
        case ChatContext.dream.rawValue:
            return AuroraColors.auroraRose
        case ChatContext.tarot.rawValue:
            return AuroraColors.auroraViolet
        default:
            return AuroraColors.auroraMint
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
