import SwiftUI

struct ChatView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = ChatViewModel()

    @State private var scrollProxy: ScrollViewProxy?
    @State private var showMoreContexts = false
    @State private var showSessionHistory = false
    @State private var suppressAutoSessionSelectionOnContextChange = false
    @State private var composerHeight: CGFloat = 0

    var body: some View {
        MysticScreenScaffold(
            "chat.title",
            showsBackground: false
        ) {
            headerBar
        } content: {
            mainScrollView
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomInputOverlay
        }
        .onPreferenceChange(ChatComposerHeightKey.self) { newValue in
            composerHeight = newValue
        }
        .onChange(of: composerHeight) { _, _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
        .onAppear {
            viewModel.applyPendingChatQuickActionIfNeeded()
        }
        .task(id: authService.currentUser?.id) {
            viewModel.authService = authService
            viewModel.loadDraftsForCurrentUser()
            await viewModel.loadSessionsForCurrentUser()
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
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard let tab = notification.object as? AppTab, tab == .chat else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChatQuickAction)) { notification in
            if let pendingAction = AppNavigation.consumePendingChatQuickAction() {
                viewModel.applyChatQuickAction(context: pendingAction.context, prompt: pendingAction.prompt)
                return
            }

            let targetContext: ChatContext?
            if let rawContext = notification.userInfo?[AppNavigationPayload.context] as? String {
                targetContext = ChatContext(rawValue: rawContext)
            } else {
                targetContext = nil
            }

            let prompt = notification.userInfo?[AppNavigationPayload.prompt] as? String
            viewModel.applyChatQuickAction(context: targetContext, prompt: prompt)
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
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Extracted UI Views

    private var headerBar: some View {
        HStack(spacing: MysticSpacing.sm) {
            Button {
                showSessionHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MysticColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(MysticColors.textSecondary.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(String(localized: "chat.session.history")))
            .accessibilityIdentifier("chat.history")

            Button {
                viewModel.startNewChat()
            } label: {
                Image(systemName: "plus.bubble.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MysticColors.neonLavender)
                    .frame(width: 34, height: 34)
                    .background(MysticColors.neonLavender.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(String(localized: "chat.new_chat")))
            .accessibilityHint(Text(String(localized: "chat.new_chat.hint")))
            .accessibilityIdentifier("chat.new_topbar")
        }
    }

    private var mainScrollView: some View {
        VStack(spacing: 0) {
            contextPickerBar
            chatEditorialHeader
                .padding(.horizontal, MysticSpacing.md)
                .padding(.bottom, MysticSpacing.sm)

            if let syncError = ChatService.shared.lastErrorMessage {
                syncErrorBanner(syncError)
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.bottom, MysticSpacing.xs)
            }

            if let transientErrorMessage = viewModel.transientErrorMessage, viewModel.visibleFailedRequest != nil {
                syncErrorBanner(transientErrorMessage)
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.bottom, MysticSpacing.xs)
            }

            if let failedRequest = viewModel.visibleFailedRequest {
                retryBanner(for: failedRequest)
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.bottom, MysticSpacing.xs)
            }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: MysticSpacing.sm) {
                        if viewModel.messages.isEmpty {
                            ChatEmptyStateView(inputText: $viewModel.inputText) {
                                viewModel.sendMessage(scrollProxy: proxy)
                            }
                        }

                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            ChatTypingIndicator(
                                isLoading: viewModel.isLoading,
                                shouldShowSlowResponseNotice: viewModel.shouldShowSlowResponseNotice
                            )
                        }

                        Color.clear.frame(height: MysticSpacing.sm)
                            .id("bottom")
                    }
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.top, MysticSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear { scrollProxy = proxy }
            }
        }
    }

    private var chatEditorialHeader: some View {
        MysticCard(glowColor: viewModel.chatContext.themeColor.opacity(0.85)) {
            HStack(alignment: .center, spacing: MysticSpacing.sm) {
                Image(systemName: viewModel.chatContext.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(viewModel.chatContext.themeColor)
                    .frame(width: 30, height: 30)
                    .background(viewModel.chatContext.themeColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: MysticRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "Arcane Dialogue")
                        .font(MysticTypographyRoles.cardTitle)
                        .foregroundColor(MysticColors.textPrimary)
                    Text(viewModel.chatContext.localizedPromptHint)
                        .font(MysticTypographyRoles.metadata)
                        .foregroundColor(MysticColors.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
        }
    }

    private var bottomInputOverlay: some View {
        ChatInputBar(
            inputText: $viewModel.inputText,
            isLoading: viewModel.isLoading,
            inlineStatusMessage: viewModel.inlineStatusMessage,
            canSend: viewModel.canSend
        ) {
            viewModel.sendMessage(scrollProxy: scrollProxy)
        }
        .padding(.bottom, chromeMetrics.tabBarVisible ? chromeMetrics.tabBarHeight : 0)
        .background(
            GeometryReader { geometry in
                Color.clear.preference(key: ChatComposerHeightKey.self, value: geometry.size.height)
            }
        )
    }

    // MARK: - Context Picker
    private var contextPickerBar: some View {
        ChatContextPicker(
            chatContext: $viewModel.chatContext,
            showMoreContexts: $showMoreContexts
        )
    }

    // MARK: - Error / Retry UI

    private func retryBanner(for failedRequest: ChatViewModel.FailedChatRequest) -> some View {
        HStack(spacing: MysticSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(MysticColors.celestialPink)

            Text(String(localized: "chat.retry.message"))
                .font(MysticFonts.caption(12))
                .foregroundColor(MysticColors.celestialPink)

            Spacer()

            Button(String(localized: "chat.retry.action")) {
                viewModel.retryLastRequest(failedRequest, scrollProxy: scrollProxy)
            }
            .font(MysticFonts.caption(12))
            .foregroundColor(MysticColors.neonLavender)
            .accessibilityHint(Text(String(localized: "chat.retry.hint")))
            .accessibilityIdentifier("chat.retry.action")
        }
        .padding(.horizontal, MysticSpacing.sm)
        .padding(.vertical, 8)
        .background(MysticColors.celestialPink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("chat.retry.banner")
    }

    private func syncErrorBanner(_ text: String) -> some View {
        HStack(spacing: MysticSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(MysticColors.celestialPink)
            Text(text)
                .font(MysticFonts.caption(12))
                .foregroundColor(MysticColors.celestialPink)
            Spacer()
        }
        .padding(.horizontal, MysticSpacing.sm)
        .padding(.vertical, 8)
        .background(MysticColors.celestialPink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("chat.error.banner")
    }
}

private struct ChatComposerHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ChatView()
        .environment(AuthService())
}
