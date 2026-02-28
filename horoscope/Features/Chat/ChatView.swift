import SwiftUI

struct ChatView: View {
    private struct FailedChatRequest {
        let sessionId: String
        let context: ChatContext
        let messageHistory: [ChatMessage]
    }

    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var chatContext: ChatContext = .general
    @State private var currentSessionId: String?
    @State private var draftsByContext: [ChatContext: String] = [:]
    @State private var failedRequest: FailedChatRequest?
    @State private var inlineStatusMessage: String?
    @State private var transientErrorMessage: String?
    @State private var showMoreContexts = false
    @State private var showSessionHistory = false
    @State private var suppressAutoSessionSelectionOnContextChange = false
    @State private var composerHeight: CGFloat = 0
    @State private var activeResponseRequestID: UUID?
    @State private var didExceedSlowResponseThreshold = false

    private let aiService = AIService.shared
    private let chatService = ChatService.shared

    private var currentSession: ChatSession? {
        guard let id = currentSessionId else { return nil }
        return chatService.sessions.first(where: { $0.id == id })
    }

    private var messages: [ChatMessage] {
        currentSession?.messages ?? []
    }

    private var visibleFailedRequest: FailedChatRequest? {
        guard let failedRequest else { return nil }
        guard failedRequest.sessionId == currentSessionId,
              failedRequest.context == chatContext else { return nil }
        return failedRequest
    }

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        !trimmedInput.isEmpty && !isLoading
    }

    private var shouldShowSlowResponseNotice: Bool {
        Self.shouldShowSlowResponseNotice(
            isLoading: isLoading,
            didExceedThreshold: didExceedSlowResponseThreshold
        )
    }

    private var primaryContexts: [ChatContext] {
        [.general, .natal, .transit]
    }

    private var additionalContexts: [ChatContext] {
        [.dream, .palmReading, .tarot]
    }

    var body: some View {
        MysticScreenScaffold(
            "chat.title",
            showsBackground: false
        ) {
            HStack(spacing: MysticSpacing.sm) {
                Button {
                    showSessionHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 17))
                        .foregroundColor(MysticColors.textSecondary)
                }
                .accessibilityLabel(Text(String(localized: "chat.session.history")))
                .accessibilityIdentifier("chat.history")

                Button {
                    startNewChat()
                } label: {
                    Image(systemName: "plus.bubble.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MysticColors.neonLavender)
                }
                .accessibilityLabel(Text(String(localized: "chat.new_chat")))
                .accessibilityHint(Text(String(localized: "chat.new_chat.hint")))
                .accessibilityIdentifier("chat.new_topbar")
            }
        } content: {
            VStack(spacing: 0) {
                contextPickerBar

                if let syncError = chatService.lastErrorMessage {
                    syncErrorBanner(syncError)
                        .padding(.horizontal, MysticSpacing.md)
                        .padding(.bottom, MysticSpacing.xs)
                }

                if let transientErrorMessage, visibleFailedRequest != nil {
                    syncErrorBanner(transientErrorMessage)
                        .padding(.horizontal, MysticSpacing.md)
                        .padding(.bottom, MysticSpacing.xs)
                }

                if let failedRequest = visibleFailedRequest {
                    retryBanner(for: failedRequest)
                        .padding(.horizontal, MysticSpacing.md)
                        .padding(.bottom, MysticSpacing.xs)
                }

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: MysticSpacing.sm) {
                            if messages.isEmpty {
                                emptyStateView
                            }

                            ForEach(messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                typingIndicator
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(key: ChatComposerHeightKey.self, value: geometry.size.height)
                    }
                )
        }
        .onPreferenceChange(ChatComposerHeightKey.self) { newValue in
            composerHeight = newValue
        }
        .onChange(of: composerHeight) { _, _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
        .onChange(of: messages.count) { _, _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
        .task(id: authService.currentUser?.id) {
            loadDraftsForCurrentUser()
            await loadSessionsForCurrentUser()
        }
        .onChange(of: chatContext) { oldValue, newValue in
            draftsByContext[oldValue] = inputText
            inputText = draftsByContext[newValue] ?? ""
            persistDraftsForCurrentUser()

            if suppressAutoSessionSelectionOnContextChange {
                suppressAutoSessionSelectionOnContextChange = false
                return
            }

            loadOrCreateSession()
        }
        .onChange(of: inputText) { _, newValue in
            draftsByContext[chatContext] = newValue
            persistDraftsForCurrentUser()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard let tab = notification.object as? AppTab, tab == .home else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChatQuickAction)) { notification in
            if let rawContext = notification.userInfo?[AppNavigationPayload.context] as? String,
               let targetContext = ChatContext(rawValue: rawContext) {
                chatContext = targetContext
            }

            if let prompt = notification.userInfo?[AppNavigationPayload.prompt] as? String {
                inputText = prompt
                draftsByContext[chatContext] = prompt
                persistDraftsForCurrentUser()
            }
        }
        .sheet(isPresented: $showMoreContexts) {
            moreContextsSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSessionHistory) {
            ChatSessionHistorySheet(
                sessions: chatService.sessionsForUser(authService.currentUser?.id ?? ""),
                onSelect: { session in
                    currentSessionId = session.id
                    if session.context != chatContext {
                        suppressAutoSessionSelectionOnContextChange = true
                        chatContext = session.context
                    }
                    showSessionHistory = false
                },
                onDelete: { session in
                    chatService.deleteSession(session.id)
                    if currentSessionId == session.id {
                        loadOrCreateSession()
                    }
                }
            )
            .environment(authService)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Session Management

    private func loadSessionsForCurrentUser() async {
        guard let userId = authService.currentUser?.id else { return }
        await chatService.loadSessions(for: userId)
        loadOrCreateSession()
    }

    private func loadOrCreateSession() {
        guard let userId = authService.currentUser?.id else { return }
        let session = chatService.activeSession(for: userId, context: chatContext)
        currentSessionId = session.id

        if session.messages.isEmpty {
            let welcome = ChatMessage(
                role: .assistant,
                content: String(localized: "chat.welcome"),
                context: chatContext
            )
            chatService.addMessage(welcome, to: session.id)
        }
    }

    private func startNewChat() {
        guard let userId = authService.currentUser?.id else { return }
        let session = chatService.createNewSession(userId: userId, context: chatContext)
        currentSessionId = session.id

        let welcome = ChatMessage(
            role: .assistant,
            content: String(localized: "chat.welcome_new"),
            context: chatContext
        )
        chatService.addMessage(welcome, to: session.id)
        failedRequest = nil
        transientErrorMessage = nil
    }

    // MARK: - Draft Persistence

    private func draftsStorageKey(for userId: String) -> String {
        "chat_drafts_\(userId)"
    }

    private func loadDraftsForCurrentUser() {
        guard let userId = authService.currentUser?.id else {
            draftsByContext = [:]
            inputText = ""
            return
        }

        guard let raw = UserDefaults.standard.dictionary(forKey: draftsStorageKey(for: userId)) as? [String: String] else {
            draftsByContext = [:]
            inputText = ""
            return
        }

        var restored: [ChatContext: String] = [:]
        for (key, value) in raw {
            if let context = ChatContext(rawValue: key) {
                restored[context] = value
            }
        }
        draftsByContext = restored
        inputText = restored[chatContext] ?? ""
    }

    private func persistDraftsForCurrentUser() {
        guard let userId = authService.currentUser?.id else { return }

        let raw = Dictionary(uniqueKeysWithValues: draftsByContext.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(raw, forKey: draftsStorageKey(for: userId))
    }

    // MARK: - Context Picker
    private var contextPickerBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MysticSpacing.sm) {
                ForEach(primaryContexts, id: \.self) { context in
                    contextChip(context)
                }
                moreContextsButton
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, MysticSpacing.sm)
        }
        .frame(minHeight: 58)
    }

    private func contextChip(_ context: ChatContext) -> some View {
        let title = titleForContext(context)
        let icon = iconForContext(context)

        return Button {
            chatContext = context
        } label: {
            HStack(spacing: MysticSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(MysticFonts.caption(12))
            }
            .padding(.horizontal, MysticSpacing.sm)
            .padding(.vertical, 8)
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
            .foregroundColor(chatContext == context ? MysticColors.voidBlack : MysticColors.textSecondary)
            .background(
                chatContext == context
                    ? AnyShapeStyle(MysticGradients.goldShimmer)
                    : AnyShapeStyle(MysticColors.cardBackground)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        chatContext == context
                            ? MysticColors.mysticGold.opacity(0.5)
                            : MysticColors.cardBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(String(localized: "chat.context.select.hint")))
    }

    private var moreContextsButton: some View {
        let isAdditionalContextSelected = additionalContexts.contains(chatContext)

        return Button {
            showMoreContexts = true
        } label: {
            HStack(spacing: MysticSpacing.xs) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 12))
                Text("chat.context.more")
                    .font(MysticFonts.caption(12))
            }
            .padding(.horizontal, MysticSpacing.sm)
            .padding(.vertical, 8)
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
            .foregroundColor(isAdditionalContextSelected ? MysticColors.voidBlack : MysticColors.textSecondary)
            .background(
                isAdditionalContextSelected
                    ? AnyShapeStyle(MysticGradients.goldShimmer)
                    : AnyShapeStyle(MysticColors.cardBackground)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isAdditionalContextSelected
                            ? MysticColors.mysticGold.opacity(0.5)
                            : MysticColors.cardBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "chat.context.more")))
        .accessibilityHint(Text(String(localized: "chat.context.more.hint")))
        .accessibilityIdentifier("chat.context.more")
    }

    private var moreContextsSheet: some View {
        ZStack {
            MysticColors.voidBlack.ignoresSafeArea()
            StarField(starCount: 25, mode: .modal)

            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                Text("chat.context.sheet.title")
                    .font(MysticFonts.heading(20))
                    .foregroundColor(MysticColors.textPrimary)

                ForEach(additionalContexts, id: \.self) { context in
                    Button {
                        chatContext = context
                        showMoreContexts = false
                    } label: {
                        MysticCard(glowColor: chatContext == context ? MysticColors.mysticGold : MysticColors.neonLavender) {
                            HStack(spacing: MysticSpacing.md) {
                                Image(systemName: iconForContext(context))
                                    .font(.system(size: 16))
                                    .foregroundColor(chatContext == context ? MysticColors.mysticGold : MysticColors.textSecondary)
                                    .frame(width: 24)

                                Text(titleForContext(context))
                                    .font(MysticFonts.body(15))
                                    .foregroundColor(MysticColors.textPrimary)

                                Spacer()

                                if chatContext == context {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MysticColors.mysticGold)
                                }
                            }
                            .frame(minHeight: MysticAccessibility.minimumTapTarget)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(titleForContext(context)))
                    .accessibilityHint(Text(String(localized: "chat.context.select.hint")))
                }

                Spacer(minLength: 0)
            }
            .padding(MysticSpacing.md)
        }
    }

    private func titleForContext(_ context: ChatContext) -> String {
        switch context {
        case .general:
            return String(localized: "chat.context.general")
        case .natal:
            return String(localized: "chat.context.natal")
        case .transit:
            return String(localized: "chat.context.transit")
        case .dream:
            return String(localized: "chat.context.dream")
        case .palmReading:
            return String(localized: "chat.context.palm")
        case .tarot:
            return String(localized: "chat.context.tarot")
        case .coffee:
            return String(localized: "chat.context.coffee")
        }
    }

    private func iconForContext(_ context: ChatContext) -> String {
        switch context {
        case .general:
            return "sparkles"
        case .natal:
            return "moon.stars"
        case .transit:
            return "arrow.triangle.2.circlepath"
        case .dream:
            return "moon.zzz"
        case .palmReading:
            return "hand.raised"
        case .tarot:
            return "suit.diamond"
        case .coffee:
            return "cup.and.saucer"
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: MysticSpacing.md) {
            Spacer().frame(height: 60)

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(MysticGradients.lavenderGlow)
                .shadow(color: MysticColors.neonLavender.opacity(0.4), radius: 10)

            VStack(spacing: MysticSpacing.sm) {
                Text("chat.empty.title")
                    .font(MysticFonts.heading(22))
                    .foregroundColor(MysticColors.textPrimary)

                Text("chat.empty.subtitle")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.xl)
            }

            VStack(spacing: MysticSpacing.sm) {
                quickPrompt(String(localized: "chat.quick.today"), icon: "sparkles")
                quickPrompt(String(localized: "chat.quick.natal"), icon: "moon.stars")
                quickPrompt(String(localized: "chat.quick.love"), icon: "heart.fill")
            }
        }
        .accessibilityIdentifier("chat.empty.state")
    }

    private func quickPrompt(_ text: String, icon: String) -> some View {
        Button {
            inputText = text
            sendMessage()
        } label: {
            HStack(spacing: MysticSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(MysticColors.mysticGold)
                Text(text)
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MysticColors.neonLavender.opacity(0.5))
            }
            .padding(.horizontal, MysticSpacing.sm)
            .padding(.vertical, 8)
            .background(MysticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MysticRadius.md)
                    .stroke(MysticColors.mysticGold.opacity(0.22), lineWidth: 1)
            )
            .frame(minHeight: MysticAccessibility.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(String(localized: "chat.quick.hint")))
    }

    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.xs) {
            HStack {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(MysticColors.neonLavender)
                            .frame(width: 6, height: 6)
                            .offset(y: isLoading ? -4 : 0)
                            .animation(
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                                value: isLoading
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(MysticColors.cardBackground)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: MysticRadius.lg,
                        bottomLeadingRadius: 4,
                        bottomTrailingRadius: MysticRadius.lg,
                        topTrailingRadius: MysticRadius.lg
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: MysticRadius.lg,
                        bottomLeadingRadius: 4,
                        bottomTrailingRadius: MysticRadius.lg,
                        topTrailingRadius: MysticRadius.lg
                    )
                    .stroke(MysticColors.cardBorder.opacity(0.5), lineWidth: 1)
                )

                Spacer()
            }

            if shouldShowSlowResponseNotice {
                Text("chat.loading.slow")
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.textMuted)
                    .padding(.leading, MysticSpacing.xs)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(localized: "chat.loading.reply")))
        .accessibilityIdentifier("chat.loading.reply")
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 1)
                .accessibilityElement()
                .accessibilityIdentifier("chat.composer")

            Divider()
                .background(MysticColors.cardBorder.opacity(0.5))

            HStack(spacing: MysticSpacing.sm) {
                HStack {
                    TextField(String(localized: "chat.input.placeholder"), text: $inputText, axis: .vertical)
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textPrimary)
                        .lineLimit(1...5)
                        .submitLabel(.send)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .onSubmit {
                            if canSend {
                                sendMessage()
                            }
                        }
                        .accessibilityIdentifier("chat.input.field")
                }
                .background(MysticColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            isLoading
                                ? MysticColors.neonLavender.opacity(0.6)
                                : (canSend ? MysticColors.mysticGold.opacity(0.5) : MysticColors.cardBorder.opacity(0.3)),
                            lineWidth: 1
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: canSend)
                .animation(.easeInOut(duration: 0.15), value: isLoading)

                Button {
                    sendMessage()
                } label: {
                    ZStack {
                        if isLoading {
                            Circle()
                                .fill(MysticColors.neonLavender.opacity(0.25))
                                .frame(width: 42, height: 42)

                            ProgressView()
                                .tint(MysticColors.neonLavender)
                        } else {
                            Circle()
                                .fill(canSend ? MysticColors.mysticGold : MysticColors.textMuted.opacity(0.15))
                                .frame(width: 42, height: 42)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(canSend ? MysticColors.voidBlack : MysticColors.textSecondary)
                        }
                    }
                }
                .disabled(!canSend)
                .frame(
                    minWidth: MysticAccessibility.minimumTapTarget,
                    minHeight: MysticAccessibility.minimumTapTarget
                )
                .accessibilityLabel(Text(String(localized: "chat.send")))
                .accessibilityHint(Text(String(localized: "chat.send.hint")))
                .accessibilityIdentifier("chat.send.button")
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, 8)

            if let inlineStatusMessage {
                Text(inlineStatusMessage)
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.auroraGreen)
                    .padding(.bottom, 6)
            }
        }
        .background(
            ZStack {
                MysticColors.voidBlack
                Rectangle()
                    .fill(MysticGradients.cardGlass)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        )
    }

    // MARK: - Error / Retry UI

    private func retryBanner(for failedRequest: FailedChatRequest) -> some View {
        HStack(spacing: MysticSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(MysticColors.celestialPink)

            Text(String(localized: "chat.retry.message"))
                .font(MysticFonts.caption(12))
                .foregroundColor(MysticColors.celestialPink)

            Spacer()

            Button(String(localized: "chat.retry.action")) {
                retryLastRequest(failedRequest)
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

    // MARK: - Actions

    private func sendMessage() {
        let text = trimmedInput
        guard !isLoading, !text.isEmpty, let sessionId = currentSessionId else { return }

        let userMessage = ChatMessage(role: .user, content: text, context: chatContext)
        chatService.addMessage(userMessage, to: sessionId)
        inputText = ""
        draftsByContext[chatContext] = ""
        persistDraftsForCurrentUser()

        let history = chatService.sessions.first(where: { $0.id == sessionId })?.messages ?? [userMessage]
        failedRequest = nil
        transientErrorMessage = nil

        withAnimation {
            scrollProxy?.scrollTo("bottom", anchor: .bottom)
        }

        inlineStatusMessage = String(localized: "chat.sent")
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                inlineStatusMessage = nil
            }
        }

        requestAssistantResponse(history: history, sessionId: sessionId, context: chatContext)
    }

    private func retryLastRequest(_ request: FailedChatRequest) {
        failedRequest = nil
        transientErrorMessage = nil
        requestAssistantResponse(history: request.messageHistory, sessionId: request.sessionId, context: request.context)
    }

    private func requestAssistantResponse(history: [ChatMessage], sessionId: String, context: ChatContext) {
        let requestID = UUID()
        activeResponseRequestID = requestID
        didExceedSlowResponseThreshold = false
        isLoading = true

        scheduleSlowResponseHint(for: requestID)

        Task {
            do {
                let response = try await aiService.getChatResponse(
                    messages: history,
                    context: context,
                    birthData: authService.currentUser?.birthData
                )

                await MainActor.run {
                    let assistantMessage = ChatMessage(role: .assistant, content: response, context: context)
                    chatService.addMessage(assistantMessage, to: sessionId)
                    failedRequest = nil
                    transientErrorMessage = nil

                    withAnimation {
                        scrollProxy?.scrollTo("bottom", anchor: .bottom)
                    }
                }
            } catch {
                await MainActor.run {
                    failedRequest = FailedChatRequest(
                        sessionId: sessionId,
                        context: context,
                        messageHistory: history
                    )

                    let fallback = friendlyChatErrorMessage(for: error)
                    transientErrorMessage = fallback
                }
            }

            await MainActor.run {
                if activeResponseRequestID == requestID {
                    activeResponseRequestID = nil
                }
                didExceedSlowResponseThreshold = false
                isLoading = false
            }
        }
    }

    private func scheduleSlowResponseHint(for requestID: UUID) {
        Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            await MainActor.run {
                guard activeResponseRequestID == requestID else { return }
                didExceedSlowResponseThreshold = true
            }
        }
    }

    private func friendlyChatErrorMessage(for error: Error) -> String {
        if let configError = error as? ConfigurationError {
            return configError.localizedDescription
        }

        if let aiError = error as? AIServiceError {
            return aiError.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return String(localized: "chat.error.offline")
            case .timedOut:
                return String(localized: "chat.error.timeout")
            default:
                return String(localized: "chat.error.server")
            }
        }

        return String(localized: "chat.error.generic")
    }

    nonisolated static func shouldShowSlowResponseNotice(isLoading: Bool, didExceedThreshold: Bool) -> Bool {
        isLoading && didExceedThreshold
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: MysticSpacing.xs) {
                if !isUser {
                    HStack(spacing: MysticSpacing.xs) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MysticColors.mysticGold)
                        Text("chat.assistant.name")
                            .font(MysticFonts.caption(11))
                            .foregroundColor(MysticColors.mysticGold)
                    }
                }

                Text(message.content)
                    .font(MysticFonts.body(15))
                    .foregroundColor(isUser ? MysticColors.voidBlack : MysticColors.textPrimary)
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? AnyShapeStyle(MysticGradients.goldShimmer)
                            : AnyShapeStyle(MysticColors.cardBackground)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: MysticRadius.lg,
                            bottomLeadingRadius: isUser ? MysticRadius.lg : 4,
                            bottomTrailingRadius: isUser ? 4 : MysticRadius.lg,
                            topTrailingRadius: MysticRadius.lg
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: MysticRadius.lg,
                            bottomLeadingRadius: isUser ? MysticRadius.lg : 4,
                            bottomTrailingRadius: isUser ? 4 : MysticRadius.lg,
                            topTrailingRadius: MysticRadius.lg
                        )
                        .stroke(
                            isUser
                                ? MysticColors.mysticGold.opacity(0.2)
                                : MysticColors.cardBorder.opacity(0.5),
                            lineWidth: 1
                        )
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label(String(localized: "chat.bubble.copy"), systemImage: "doc.on.doc")
                        }

                        ShareLink(item: message.content) {
                            Label(String(localized: "chat.bubble.share"), systemImage: "square.and.arrow.up")
                        }
                    }

                Text(message.timestamp.formatted(as: "HH:mm"))
                    .font(MysticFonts.caption(10))
                    .foregroundColor(MysticColors.textMuted)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ChatView()
        .environment(AuthService())
}

private struct ChatComposerHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Chat Session History Sheet
struct ChatSessionHistorySheet: View {
    let sessions: [ChatSession]
    let onSelect: (ChatSession) -> Void
    let onDelete: (ChatSession) -> Void

    var body: some View {
        ZStack {
            MysticColors.voidBlack.ignoresSafeArea()
            StarField(starCount: 25, mode: .modal)

            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                Text("chat.session.history")
                    .font(MysticFonts.heading(20))
                    .foregroundColor(MysticColors.textPrimary)

                if sessions.isEmpty {
                    VStack(spacing: MysticSpacing.md) {
                        Spacer().frame(height: 40)
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(MysticColors.textMuted)
                        Text("chat.session.no_history")
                            .font(MysticFonts.body(15))
                            .foregroundColor(MysticColors.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("chat.session.empty")
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: MysticSpacing.sm) {
                            ForEach(sessions) { session in
                                Button {
                                    onSelect(session)
                                } label: {
                                    MysticCard(glowColor: contextColor(session.context)) {
                                        VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                                            HStack {
                                                Image(systemName: contextIcon(session.context))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(contextColor(session.context))
                                                Text(session.title)
                                                    .font(MysticFonts.body(15))
                                                    .foregroundColor(MysticColors.textPrimary)
                                                    .lineLimit(1)
                                                Spacer()
                                                Text(session.updatedAt.relativeFormatted)
                                                    .font(MysticFonts.caption(11))
                                                    .foregroundColor(MysticColors.textMuted)
                                            }

                                            Text(session.lastMessagePreview)
                                                .font(MysticFonts.caption(13))
                                                .foregroundColor(MysticColors.textSecondary)
                                                .lineLimit(2)
                                        }
                                        .frame(minHeight: MysticAccessibility.minimumTapTarget)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(session.title))
                                .accessibilityHint(Text(String(localized: "chat.context.select.hint")))
                                .accessibilityIdentifier("chat.session.\(session.id)")
                                .contextMenu {
                                    Button(role: .destructive) {
                                        onDelete(session)
                                    } label: {
                                        Label(String(localized: "common.delete"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(MysticSpacing.md)
        }
    }

    private func contextColor(_ context: ChatContext) -> Color {
        switch context {
        case .general: return MysticColors.neonLavender
        case .natal: return MysticColors.mysticGold
        case .transit: return MysticColors.auroraGreen
        case .dream: return MysticColors.celestialPink
        case .palmReading: return MysticColors.neonLavender
        case .tarot: return MysticColors.mysticGold
        case .coffee: return MysticColors.mysticGold
        }
    }

    private func contextIcon(_ context: ChatContext) -> String {
        switch context {
        case .general: return "sparkles"
        case .natal: return "moon.stars"
        case .transit: return "arrow.triangle.2.circlepath"
        case .dream: return "moon.zzz"
        case .palmReading: return "hand.raised"
        case .tarot: return "suit.diamond"
        case .coffee: return "cup.and.saucer"
        }
    }
}
