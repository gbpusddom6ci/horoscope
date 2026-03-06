import SwiftUI

struct OracleView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = ChatViewModel()
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showSessionHistory = false
    @State private var suppressAutoSessionSelectionOnContextChange = false
    @State private var showPalm = false
    @State private var showAtlas = false

    private let insightService = InsightService.shared
    private let orderedModes: [ChatContext] = [.general, .natal, .transit, .dream, .tarot, .palmReading]

    var body: some View {
        AuroraScreen(
            backdropStyle: .oracleMist,
            eyebrow: String(localized: "oracle.eyebrow"),
            title: String(localized: "oracle.title"),
            subtitle: String(localized: "oracle.subtitle"),
            usesScrollView: false,
            contentBottomInsetStrategy: .none
        ) {
            HStack(spacing: 10) {
                headerButton(icon: "plus", action: {
                    viewModel.startNewChat()
                })

                headerButton(icon: "clock.arrow.circlepath", action: {
                    showSessionHistory = true
                })
            }
        } content: {
            VStack(spacing: 0) {
                modeRail
                contextHero
                promptStrip
                messageScroller
            }
        }
        .accessibilityIdentifier("oracle.screen")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composerBar
        }
        .task(id: authService.currentUser?.id) {
            viewModel.authService = authService
            viewModel.loadDraftsForCurrentUser()
            await viewModel.loadSessionsForCurrentUser()
            presentPendingFlowsIfNeeded()
        }
        .onAppear {
            viewModel.applyPendingChatQuickActionIfNeeded()
            presentPendingFlowsIfNeeded()
        }
        .onChange(of: viewModel.chatContext) { oldValue, newValue in
            viewModel.draftsByContext[oldValue] = viewModel.inputText
            viewModel.inputText = viewModel.draftsByContext[newValue] ?? ""
            viewModel.persistDraftsForCurrentUser()

            if suppressAutoSessionSelectionOnContextChange {
                suppressAutoSessionSelectionOnContextChange = false
                return
            }

            viewModel.loadOrCreateSession()
        }
        .onChange(of: viewModel.inputText) { _, newValue in
            viewModel.draftsByContext[viewModel.chatContext] = newValue
            viewModel.persistDraftsForCurrentUser()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChatQuickAction)) { notification in
            if let pendingAction = AppNavigation.consumePendingChatQuickAction() {
                viewModel.applyChatQuickAction(context: pendingAction.context, prompt: pendingAction.prompt)
                return
            }

            let context = (notification.userInfo?[AppNavigationPayload.context] as? String).flatMap(ChatContext.init(rawValue:))
            let prompt = notification.userInfo?[AppNavigationPayload.prompt] as? String
            viewModel.applyChatQuickAction(context: context, prompt: prompt)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPalmQuickAction)) { _ in
            _ = AppNavigation.consumePendingPalmQuickAction()
            showPalm = true
            viewModel.chatContext = .palmReading
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAtlasExperience)) { _ in
            _ = AppNavigation.consumePendingAtlasExperience()
            showAtlas = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard targetDestination(from: notification) == .oracle else { return }
            withAnimation(reduceMotion ? nil : AuroraMotion.transition) {
                scrollProxy?.scrollTo("oracle-bottom", anchor: .bottom)
            }
        }
        .sheet(isPresented: $showSessionHistory) {
            ChatSessionHistorySheet(
                sessions: ChatService.shared.sessionsForUser(authService.currentUser?.id ?? ""),
                onSelect: { session in
                    viewModel.currentSessionId = session.id
                    if session.context != viewModel.chatContext {
                        suppressAutoSessionSelectionOnContextChange = true
                        viewModel.chatContext = session.context
                    }
                    showSessionHistory = false
                },
                onDelete: { session in
                    viewModel.deleteSession(id: session.id)
                }
            )
            .environment(authService)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPalm) {
            PalmReadingView()
                .environment(authService)
        }
        .fullScreenCover(isPresented: $showAtlas) {
            AtlasView()
                .environment(authService)
        }
    }

    private func headerButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AuroraColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AuroraColors.secondaryCard))
        }
        .buttonStyle(.plain)
    }

    private var modeRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AuroraSpacing.sm) {
                ForEach(orderedModes, id: \.self) { mode in
                    Button {
                        viewModel.chatContext = mode
                    } label: {
                        PrismChip(
                            mode.localizedDisplayName,
                            icon: mode.iconName,
                            accent: accent(for: mode),
                            isSelected: viewModel.chatContext == mode
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AuroraSpacing.md)
            .padding(.vertical, AuroraSpacing.sm)
        }
    }

    private var contextHero: some View {
        LumenCard(accent: accent(for: viewModel.chatContext)) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                HStack {
                    Text(viewModel.chatContext.localizedDisplayName)
                        .font(AuroraTypography.section(19))
                        .foregroundColor(AuroraColors.textPrimary)
                    Spacer()
                    PrismChip(
                        viewModel.chatContext == .general ? String(localized: "oracle.hero.live") : String(localized: "oracle.hero.focused"),
                        icon: "sparkles",
                        accent: accent(for: viewModel.chatContext),
                        isSelected: true
                    )
                }

                Text(heroDescription(for: viewModel.chatContext))
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)
                    .lineSpacing(4)

                HStack(spacing: AuroraSpacing.sm) {
                    primaryHeroButton
                    secondaryHeroButton
                }
            }
        }
        .padding(.horizontal, AuroraSpacing.md)
        .padding(.bottom, AuroraSpacing.sm)
    }

    private var primaryHeroButton: some View {
        Group {
            switch viewModel.chatContext {
            case .natal, .transit:
                HaloButton(String(localized: "oracle.cta.open_atlas"), icon: "arrow.right") {
                    showAtlas = true
                }
            case .palmReading:
                HaloButton(String(localized: "oracle.cta.open_palm"), icon: "hand.raised.fill") {
                    showPalm = true
                }
            case .tarot:
                HaloButton(String(localized: "oracle.cta.open_tarot"), icon: "sparkles.rectangle.stack.fill") {
                    AppNavigation.switchToDestination(.tarot)
                }
            case .dream:
                HaloButton(String(localized: "oracle.cta.open_dreams"), icon: "moon.zzz") {
                    AppNavigation.switchToDestination(.dreams)
                }
            default:
                HaloButton(String(localized: "oracle.cta.ask_chart"), icon: "sparkles") {
                    viewModel.chatContext = .natal
                    viewModel.inputText = "Interpret the strongest part of my natal chart right now."
                }
            }
        }
    }

    private var secondaryHeroButton: some View {
        HaloButton(String(localized: "oracle.cta.use_prompt"), icon: "arrow.right", style: .ghost) {
            if let prompt = recommendedPrompts(for: viewModel.chatContext).first {
                viewModel.inputText = prompt
            }
        }
    }

    private var promptStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AuroraSpacing.sm) {
                ForEach(recommendedPrompts(for: viewModel.chatContext), id: \.self) { prompt in
                    Button {
                        viewModel.inputText = prompt
                    } label: {
                        Text(prompt)
                            .font(AuroraTypography.body(13))
                            .foregroundColor(AuroraColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AuroraSurfaceLevel.elevated.fillStyle)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(accent(for: viewModel.chatContext).opacity(0.22), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AuroraSpacing.md)
            .padding(.bottom, AuroraSpacing.sm)
        }
    }

    private var messageScroller: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: AuroraSpacing.sm) {
                    if viewModel.messages.isEmpty {
                        oracleEmptyState
                    }

                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message) {
                            saveInsight(from: message)
                        }
                        .id(message.id)
                    }

                    if viewModel.isLoading {
                        ChatTypingIndicator(
                            isLoading: viewModel.isLoading,
                            shouldShowSlowResponseNotice: viewModel.shouldShowSlowResponseNotice
                        )
                    }

                    Color.clear
                        .frame(height: 8)
                        .id("oracle-bottom")
                }
                .padding(.horizontal, AuroraSpacing.md)
                .padding(.bottom, AuroraSpacing.md)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(reduceMotion ? nil : AuroraMotion.transition) {
                    proxy.scrollTo("oracle-bottom", anchor: .bottom)
                }
            }
        }
    }

    private var oracleEmptyState: some View {
        LumenCard(accent: accent(for: viewModel.chatContext)) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                Text("oracle.empty.title")
                    .font(AuroraTypography.section(18))
                    .foregroundColor(AuroraColors.textPrimary)

                Text("oracle.empty.subtitle")
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)

                ForEach(recommendedPrompts(for: viewModel.chatContext), id: \.self) { prompt in
                    quickPrompt(prompt)
                }
            }
        }
    }

    private func quickPrompt(_ text: String) -> some View {
        Button {
            viewModel.inputText = text
        } label: {
            HStack {
                Text(text)
                    .font(AuroraTypography.body(13))
                    .foregroundColor(AuroraColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundColor(accent(for: viewModel.chatContext))
            }
            .padding(.horizontal, AuroraSpacing.md)
            .padding(.vertical, 12)
            .background(AuroraColors.secondaryCard)
            .clipShape(RoundedRectangle(cornerRadius: AuroraRadius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var composerBar: some View {
        ChatInputBar(
            inputText: $viewModel.inputText,
            isLoading: viewModel.isLoading,
            inlineStatusMessage: viewModel.inlineStatusMessage,
            canSend: viewModel.canSend
        ) {
            viewModel.sendMessage(scrollProxy: scrollProxy)
        }
        .padding(.bottom, chromeMetrics.tabBarVisible ? chromeMetrics.tabBarHeight : 0)
    }

    private func heroDescription(for context: ChatContext) -> String {
        switch context {
        case .general:
            return String(localized: "oracle.description.general")
        case .natal:
            return String(localized: "oracle.description.natal")
        case .transit:
            return String(localized: "oracle.description.transit")
        case .dream:
            return String(localized: "oracle.description.dream")
        case .palmReading:
            return String(localized: "oracle.description.palm")
        case .tarot:
            return String(localized: "oracle.description.tarot")
        case .coffee:
            return viewModel.chatContext.localizedPromptHint
        }
    }

    private func recommendedPrompts(for context: ChatContext) -> [String] {
        switch context {
        case .general:
            return [
                String(localized: "oracle.prompt.general.1"),
                String(localized: "oracle.prompt.general.2"),
                String(localized: "oracle.prompt.general.3")
            ]
        case .natal:
            return [
                String(localized: "oracle.prompt.natal.1"),
                String(localized: "oracle.prompt.natal.2"),
                String(localized: "oracle.prompt.natal.3")
            ]
        case .transit:
            return [
                String(localized: "oracle.prompt.transit.1"),
                String(localized: "oracle.prompt.transit.2"),
                String(localized: "oracle.prompt.transit.3")
            ]
        case .dream:
            return [
                String(localized: "oracle.prompt.dream.1"),
                String(localized: "oracle.prompt.dream.2"),
                String(localized: "oracle.prompt.dream.3")
            ]
        case .palmReading:
            return [
                String(localized: "oracle.prompt.palm.1"),
                String(localized: "oracle.prompt.palm.2"),
                String(localized: "oracle.prompt.palm.3")
            ]
        case .tarot:
            return [
                String(localized: "oracle.prompt.tarot.1"),
                String(localized: "oracle.prompt.tarot.2"),
                String(localized: "oracle.prompt.tarot.3")
            ]
        case .coffee:
            return [viewModel.chatContext.localizedPromptHint]
        }
    }

    private func accent(for context: ChatContext) -> Color {
        switch context {
        case .general:
            return AuroraColors.auroraMint
        case .natal, .palmReading:
            return AuroraColors.auroraCyan
        case .transit, .coffee:
            return AuroraColors.auroraMint
        case .dream:
            return AuroraColors.auroraRose
        case .tarot:
            return AuroraColors.auroraViolet
        }
    }

    private func saveInsight(from message: ChatMessage) {
        guard message.role == .assistant, let userId = authService.currentUser?.id else { return }

        let trimmed = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let title = String(trimmed.prefix(38))
        let summary = String(trimmed.prefix(220))

        insightService.saveInsight(
            SavedInsight(
                userId: userId,
                sourceType: .oracle,
                sourceRefId: viewModel.currentSessionId ?? message.id,
                title: title,
                summary: summary,
                accentKey: viewModel.chatContext.rawValue
            )
        )
    }

    private func presentPendingFlowsIfNeeded() {
        if AppNavigation.consumePendingPalmQuickAction() {
            showPalm = true
            viewModel.chatContext = .palmReading
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
