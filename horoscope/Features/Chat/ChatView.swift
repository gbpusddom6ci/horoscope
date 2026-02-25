import SwiftUI

struct ChatView: View {
    @Environment(AuthService.self) private var authService
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var chatContext: ChatContext = .general
    @State private var currentSessionId: String?

    private let aiService = AIService.shared
    private let chatService = ChatService.shared

    private var currentSession: ChatSession? {
        guard let id = currentSessionId else { return nil }
        return chatService.sessions.first(where: { $0.id == id })
    }

    private var messages: [ChatMessage] {
        currentSession?.messages ?? []
    }

    var body: some View {
        ZStack {
            StarField(starCount: 40)

            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Text("AI Sohbet")
                        .font(MysticFonts.heading(18))
                        .foregroundColor(MysticColors.textPrimary)

                    Spacer()

                    Button {
                        startNewChat()
                    } label: {
                        Image(systemName: "plus.bubble.fill")
                            .font(.system(size: 18))
                            .foregroundColor(MysticColors.neonLavender)
                    }
                }
                .padding(.horizontal, MysticSpacing.md)
                .padding(.top, 10)
                .padding(.bottom, 10)

                // Context Picker
                    contextPickerBar

                    // Messages
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

                                Color.clear.frame(height: MysticSpacing.md)
                                    .id("bottom")
                            }
                            .padding(.horizontal, MysticSpacing.md)
                            .padding(.top, MysticSpacing.md)
                        }
                        .onAppear { scrollProxy = proxy }
                    }

            }

            // Input Bar
            inputBar
        }
        .onAppear {
            loadOrCreateSession()
        }
        .onChange(of: chatContext) { _, _ in
            loadOrCreateSession()
        }
    }

    // MARK: - Session Management

    private func loadOrCreateSession() {
        guard let userId = authService.currentUser?.id else { return }
        let session = chatService.activeSession(for: userId, context: chatContext)
        currentSessionId = session.id

        // Add welcome message if this is a brand new session
        if session.messages.isEmpty {
            let welcome = ChatMessage(
                role: .assistant,
                content: "✨ Merhaba! Ben Mystic, AI astroloji danışmanınızım. Natal haritanız, transitler, rüyalarınız veya merak ettiğiniz herhangi bir konu hakkında benimle sohbet edebilirsiniz.\n\nSize nasıl yardımcı olabilirim?",
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
            content: "✨ Yeni bir sohbet başlattınız! Size nasıl yardımcı olabilirim?",
            context: chatContext
        )
        chatService.addMessage(welcome, to: session.id)
    }

    // MARK: - Context Picker
    private var contextPickerBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MysticSpacing.sm) {
                contextChip("Genel", context: .general, icon: "sparkles")
                contextChip("Natal", context: .natal, icon: "moon.stars")
                contextChip("Transit", context: .transit, icon: "arrow.triangle.2.circlepath")
                contextChip("Rüya", context: .dream, icon: "moon.zzz")
                contextChip("El Falı", context: .palmReading, icon: "hand.raised")
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, MysticSpacing.sm)
        }
    }

    private func contextChip(_ title: String, context: ChatContext, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                chatContext = context
            }
        } label: {
            HStack(spacing: MysticSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(MysticFonts.caption(12))
            }
            .padding(.horizontal, MysticSpacing.sm)
            .padding(.vertical, 6)
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
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer().frame(height: 60)

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(MysticGradients.lavenderGlow)
                .shadow(color: MysticColors.neonLavender.opacity(0.4), radius: 10)

            VStack(spacing: MysticSpacing.sm) {
                Text("Mistik Sohbet")
                    .font(MysticFonts.heading(22))
                    .foregroundColor(MysticColors.textPrimary)

                Text("Natal haritanız, transitler, rüyalar veya herhangi bir konu hakkında AI danışmanınızla sohbet edin.")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.xl)
            }

            // Quick prompts
            VStack(spacing: MysticSpacing.sm) {
                quickPrompt("Bugün beni neler bekliyor?", icon: "sparkles")
                quickPrompt("Natal haritamı yorumla", icon: "moon.stars")
                quickPrompt("Aşk hayatım hakkında ne dersin?", icon: "heart.fill")
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
                    .font(.system(size: 14))
                    .foregroundColor(MysticColors.mysticGold)
                Text(text)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(MysticColors.neonLavender.opacity(0.5))
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, MysticSpacing.sm)
            .mysticCardStyle(glowColor: MysticColors.mysticGold.opacity(0.5))
        }
        .buttonStyle(.plain)
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
                // Text input
                HStack {
                    TextField("Mesajınızı yazın...", text: $inputText, axis: .vertical)
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textPrimary)
                        .lineLimit(1...5)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, MysticSpacing.md)
                .padding(.vertical, MysticSpacing.sm)
                .background(MysticColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(MysticColors.cardBorder, lineWidth: 1)
                )

                // Send button
                Button {
                    sendMessage()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? MysticColors.textMuted.opacity(0.2)
                                    : MysticColors.mysticGold
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(
                                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? MysticColors.textMuted
                                    : MysticColors.voidBlack
                            )
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, MysticSpacing.sm)
            .background(MysticColors.voidBlack.opacity(0.9))
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let sessionId = currentSessionId else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: text, context: chatContext)
        chatService.addMessage(userMessage, to: sessionId)
        inputText = ""

        // Scroll to bottom
        withAnimation {
            scrollProxy?.scrollTo("bottom", anchor: .bottom)
        }

        // Get AI response
        isLoading = true
        Task {
            do {
                let response = try await aiService.getChatResponse(
                    messages: messages,
                    context: chatContext,
                    birthData: authService.currentUser?.birthData
                )

                let assistantMessage = ChatMessage(
                    role: .assistant,
                    content: response,
                    context: chatContext
                )
                chatService.addMessage(assistantMessage, to: sessionId)

                withAnimation {
                    scrollProxy?.scrollTo("bottom", anchor: .bottom)
                }
            } catch {
                let errorMessage = ChatMessage(
                    role: .assistant,
                    content: "Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.",
                    context: chatContext
                )
                chatService.addMessage(errorMessage, to: sessionId)
            }
            isLoading = false
        }
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
                // Avatar + Name
                if !isUser {
                    HStack(spacing: MysticSpacing.xs) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MysticColors.mysticGold)
                        Text("Mystic")
                            .font(MysticFonts.caption(11))
                            .foregroundColor(MysticColors.mysticGold)
                    }
                }

                // Bubble
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
                    .clipShape(
                        RoundedRectangle(cornerRadius: MysticRadius.lg)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MysticRadius.lg)
                            .stroke(
                                isUser
                                    ? MysticColors.mysticGold.opacity(0.3)
                                    : MysticColors.cardBorder,
                                lineWidth: 1
                            )
                    )

                // Timestamp
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
