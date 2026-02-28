import Foundation
import Observation
import os

/// Manages chat sessions with Firestore as the source of truth.
@MainActor
@Observable
class ChatService {
    static let shared = ChatService()

    private(set) var sessions: [ChatSession] = []
    private(set) var lastErrorMessage: String?

    private let firestore = FirestoreService.shared
    private let logger = Logger(subsystem: "rk.horoscope", category: "ChatService")

    private init() {}

    // MARK: - Remote Sync

    func loadSessions(for userId: String) async {
        do {
            let remote = try await firestore.getChatSessions(userId: userId)
            sessions.removeAll { $0.userId == userId }
            sessions.append(contentsOf: remote)
            lastErrorMessage = nil
        } catch {
            logger.error("Failed to load chat sessions: \(error.localizedDescription, privacy: .public)")
            lastErrorMessage = String(localized: "chat.service.error.load")
        }
    }

    // MARK: - Public API

    /// Returns the most recent session for a given context, or creates a new one.
    func activeSession(for userId: String, context: ChatContext) -> ChatSession {
        if let existing = sessions
            .filter({ $0.userId == userId && $0.context == context })
            .sorted(by: { $0.updatedAt > $1.updatedAt })
            .first {
            return existing
        }

        let newSession = ChatSession(userId: userId, context: context)
        sessions.insert(newSession, at: 0)
        persistSession(newSession)
        return newSession
    }

    /// Returns all sessions for a given user, sorted by most recent.
    func sessionsForUser(_ userId: String) -> [ChatSession] {
        sessions
            .filter { $0.userId == userId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    /// True if the user has sent at least one message (first value metric).
    func hasUserMessages(for userId: String) -> Bool {
        sessionsForUser(userId)
            .contains(where: { session in
                session.messages.contains(where: { $0.role == .user })
            })
    }

    /// Earliest user message timestamp for first-value timing.
    func firstUserMessageDate(for userId: String) -> Date? {
        sessionsForUser(userId)
            .flatMap { session in
                session.messages.filter { $0.role == .user }.map(\.timestamp)
            }
            .min()
    }

    /// Appends a message to a session and persists.
    func addMessage(_ message: ChatMessage, to sessionId: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }

        let updatedTitle = Self.updatedTitle(
            currentTitle: sessions[index].title,
            existingMessages: sessions[index].messages,
            incomingMessage: message
        )

        sessions[index].messages.append(message)
        sessions[index].updatedAt = Date()
        sessions[index].title = updatedTitle

        let updatedSession = sessions[index]
        sessions.sort { $0.updatedAt > $1.updatedAt }
        persistSession(updatedSession)
    }

    /// Creates a brand new session for the given context.
    func createNewSession(userId: String, context: ChatContext) -> ChatSession {
        let session = ChatSession(userId: userId, context: context)
        sessions.insert(session, at: 0)
        persistSession(session)
        return session
    }

    /// Deletes a session by ID.
    func deleteSession(_ sessionId: String) {
        guard let session = sessions.first(where: { $0.id == sessionId }) else { return }
        sessions.removeAll { $0.id == sessionId }

        Task {
            do {
                try await firestore.deleteChatSession(userId: session.userId, sessionId: sessionId)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to delete chat session: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = String(localized: "chat.service.error.delete")
                }
            }
        }
    }

    /// Clears all sessions for a user.
    func clearAllSessions(for userId: String) {
        sessions.removeAll { $0.userId == userId }

        Task {
            do {
                try await firestore.clearChatSessions(userId: userId)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to clear chat sessions: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = String(localized: "chat.service.error.clear")
                }
            }
        }
    }

    private func persistSession(_ session: ChatSession) {
        Task {
            do {
                try await firestore.saveChatSession(session)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to persist chat session: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = String(localized: "chat.service.error.persist")
                }
            }
        }
    }

    nonisolated static func updatedTitle(
        currentTitle: String,
        existingMessages: [ChatMessage],
        incomingMessage: ChatMessage
    ) -> String {
        guard incomingMessage.role == .user else { return currentTitle }

        let hasUserMessageAlready = existingMessages.contains(where: { $0.role == .user })
        guard !hasUserMessageAlready else { return currentTitle }
        guard isUntitledTitle(currentTitle) else { return currentTitle }

        let proposal = incomingMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !proposal.isEmpty else { return String(localized: "chat.session.new_title") }
        return String(proposal.prefix(40))
    }

    nonisolated static func isUntitledTitle(_ title: String) -> Bool {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let untitledLabels = [
            String(localized: "chat.session.new_title"),
            "Yeni Sohbet",
            "New Chat"
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        return untitledLabels.contains(normalized)
    }
}
