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
    @State private var composerHeight: CGFloat = 0

    private let aiService = AIService.shared
    private let chatService = ChatService.shared

    private var currentSession: ChatSession? {
        guard let id = currentSessionId else { return nil }
        return chatService.sessions.first(where: { $0.id == id })
    }

    private var messages: [ChatMessage] {
        currentSession?.messages ?? []
    }

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        !trimmedInput.isEmpty && !isLoading
    }

    private var primaryContexts: [ChatContext] {
        [.general, .natal, .transit]
    }

    private var additionalContexts: [ChatContext] {
        [.dream, .palmReading, .tarot]
    }

    var body: some View {
        ZStack {
            StarField(starCount: 40)

            VStack(spacing: 0) {
                MysticTopBar("chat.title") {
                    Button {
                        startNewChat()
                    } label: {
                        Image(systemName: "plus.bubble.fill")
                            .font(.system(size: 18))
                            .foregroundColor(MysticColors.neonLavender)
                    }
                    .accessibilityLabel(Text(String(localized: "chat.new_chat")))
                    .accessibilityHint(Text(String(localized: "chat.new_chat.hint")))
                }

                contextPickerBar

                if let syncError = chatService.lastErrorMessage {
                    syncErrorBanner(syncError)
                        .padding(.horizontal, MysticSpacing.md)
                        .padding(.bottom, MysticSpacing.xs)
                }

                if let transientErrorMessage {
                    syncErrorBanner(transientErrorMessage)
                        .padding(.horizontal, MysticSpacing.md)
                        .padding(.bottom, MysticSpacing.xs)
                }

                if let failedRequest {
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
                .padding(.bottom, chromeMetrics.tabBarVisible ? MysticSpacing.xs : MysticSpacing.sm)
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
            loadOrCreateSession()
        }
        .onChange(of: inputText) { _, newValue in
            draftsByContext[chatContext] = newValue
            persistDraftsForCurrentUser()
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
            StarField(starCount: 25)

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
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(MysticColors.neonLavender)
                        .frame(width: 8, height: 8)
                        .opacity(0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                            value: isLoading
                        )
                }
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, MysticSpacing.sm)
            .background(MysticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg))

            Spacer()
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MysticColors.cardBorder)

            HStack(spacing: MysticSpacing.sm) {
                HStack {
                    TextField(String(localized: "chat.input.placeholder"), text: $inputText, axis: .vertical)
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textPrimary)
                        .lineLimit(1...5)
                        .submitLabel(.send)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            if canSend {
                                sendMessage()
                            }
                        }
                        .accessibilityIdentifier("chat.input.field")
                }
                .padding(.horizontal, MysticSpacing.md)
                .padding(.vertical, MysticSpacing.sm)
                .background(MysticColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isLoading
                                ? MysticColors.neonLavender.opacity(0.6)
                                : (canSend ? MysticColors.mysticGold.opacity(0.65) : MysticColors.cardBorder),
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
                                .frame(width: 44, height: 44)

                            ProgressView()
                                .tint(MysticColors.neonLavender)
                        } else {
                            Circle()
                                .fill(canSend ? MysticColors.mysticGold : MysticColors.textMuted.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canSend ? MysticColors.voidBlack : MysticColors.textMuted)
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
            .padding(.top, MysticSpacing.sm)

            if let inlineStatusMessage {
                Text(inlineStatusMessage)
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.auroraGreen)
                    .padding(.top, 4)
                    .padding(.bottom, MysticSpacing.xs)
            } else {
                Color.clear.frame(height: MysticSpacing.xs)
            }
        }
        .background(MysticColors.voidBlack.opacity(0.92))
        .accessibilityIdentifier("chat.composer")
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
        }
        .padding(.horizontal, MysticSpacing.sm)
        .padding(.vertical, 8)
        .background(MysticColors.celestialPink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.sm))
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
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = trimmedInput
        guard !text.isEmpty, let sessionId = currentSessionId else { return }

        let userMessage = ChatMessage(role: .user, content: text, context: chatContext)
        chatService.addMessage(userMessage, to: sessionId)
        inputText = ""
        draftsByContext[chatContext] = ""
        persistDraftsForCurrentUser()

        let history = chatService.sessions.first(where: { $0.id == sessionId })?.messages ?? [userMessage]
        failedRequest = nil

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
        requestAssistantResponse(history: request.messageHistory, sessionId: request.sessionId, context: request.context)
    }

    private func requestAssistantResponse(history: [ChatMessage], sessionId: String, context: ChatContext) {
        isLoading = true

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
                isLoading = false
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
                    .lineSpacing(3)
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.vertical, MysticSpacing.sm + 2)
                    .background(
                        isUser
                            ? AnyShapeStyle(MysticGradients.goldShimmer)
                            : AnyShapeStyle(MysticColors.cardBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MysticRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: MysticRadius.lg)
                            .stroke(
                                isUser
                                    ? MysticColors.mysticGold.opacity(0.3)
                                    : MysticColors.cardBorder,
                                lineWidth: 1
                            )
                    )

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
