import SwiftUI

@Observable
final class ChatViewModel {
    struct FailedChatRequest {
        let sessionId: String
        let context: ChatContext
        let messageHistory: [ChatMessage]
    }

    var inputText: String = ""
    var isLoading: Bool = false
    var chatContext: ChatContext = .general
    var currentSessionId: String?
    var draftsByContext: [ChatContext: String] = [:]
    var failedRequest: FailedChatRequest?
    var inlineStatusMessage: String?
    var transientErrorMessage: String?
    var activeResponseRequestID: UUID?
    var didExceedSlowResponseThreshold = false

    var authService: AuthService?
    private let aiService = AIService.shared
    private let chatService = ChatService.shared

    var currentSession: ChatSession? {
        guard let id = currentSessionId else { return nil }
        return chatService.sessions.first(where: { $0.id == id })
    }

    var messages: [ChatMessage] {
        currentSession?.messages ?? []
    }

    var visibleFailedRequest: FailedChatRequest? {
        guard let failedRequest else { return nil }
        guard failedRequest.sessionId == currentSessionId,
              failedRequest.context == chatContext else { return nil }
        return failedRequest
    }

    var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSend: Bool {
        !trimmedInput.isEmpty && !isLoading
    }

    var shouldShowSlowResponseNotice: Bool {
        isLoading && didExceedSlowResponseThreshold
    }

    var primaryContexts: [ChatContext] {
        [.general, .natal, .transit]
    }

    var additionalContexts: [ChatContext] {
        [.dream, .palmReading, .tarot]
    }

    // MARK: - Session Management

    func loadSessionsForCurrentUser() async {
        guard let userId = authService?.currentUser?.id else { return }
        await chatService.loadSessions(for: userId)
        loadOrCreateSession()
    }

    func loadOrCreateSession() {
        guard let userId = authService?.currentUser?.id else { return }
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

    func startNewChat() {
        guard let userId = authService?.currentUser?.id else { return }
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

    func deleteSession(id: String) {
        chatService.deleteSession(id)
        if currentSessionId == id {
            loadOrCreateSession()
        }
    }

    // MARK: - Draft Persistence

    private func draftsStorageKey(for userId: String) -> String {
        "chat_drafts_\(userId)"
    }

    func loadDraftsForCurrentUser() {
        guard let userId = authService?.currentUser?.id else {
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

    func persistDraftsForCurrentUser() {
        guard let userId = authService?.currentUser?.id else { return }

        let raw = Dictionary(uniqueKeysWithValues: draftsByContext.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(raw, forKey: draftsStorageKey(for: userId))
    }

    // MARK: - Actions

    func applyPendingChatQuickActionIfNeeded() {
        guard let pendingAction = AppNavigation.consumePendingChatQuickAction() else { return }
        applyChatQuickAction(context: pendingAction.context, prompt: pendingAction.prompt)
    }

    func applyChatQuickAction(context: ChatContext?, prompt: String?) {
        if let targetContext = context {
            chatContext = targetContext
        }

        if let prompt {
            inputText = prompt
            draftsByContext[chatContext] = prompt
            persistDraftsForCurrentUser()
        }
    }

    func sendMessage(scrollProxy: ScrollViewProxy?) {
        let text = trimmedInput
        guard !isLoading, !text.isEmpty, let sessionId = currentSessionId else { return }

        guard UsageLimitService.shared.canPerformAction(.chatMessage) else { return }

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

        requestAssistantResponse(history: history, sessionId: sessionId, context: chatContext, scrollProxy: scrollProxy)
    }

    func retryLastRequest(_ request: FailedChatRequest, scrollProxy: ScrollViewProxy?) {
        failedRequest = nil
        transientErrorMessage = nil
        requestAssistantResponse(history: request.messageHistory, sessionId: request.sessionId, context: request.context, scrollProxy: scrollProxy)
    }

    private func requestAssistantResponse(history: [ChatMessage], sessionId: String, context: ChatContext, scrollProxy: ScrollViewProxy?) {
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
                    birthData: authService?.currentUser?.birthData
                )

                await MainActor.run {
                    let assistantMessage = ChatMessage(role: .assistant, content: response, context: context)
                    chatService.addMessage(assistantMessage, to: sessionId)
                    failedRequest = nil
                    transientErrorMessage = nil

                    withAnimation {
                        scrollProxy?.scrollTo("bottom", anchor: .bottom)
                    }
                    UsageLimitService.shared.recordAction(.chatMessage)
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
}
