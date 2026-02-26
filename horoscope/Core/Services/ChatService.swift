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
            lastErrorMessage = "Sohbetler yüklenemedi. Lütfen bağlantınızı kontrol edin."
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

    /// Appends a message to a session and persists.
    func addMessage(_ message: ChatMessage, to sessionId: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }

        sessions[index].messages.append(message)
        sessions[index].updatedAt = Date()

        // Auto-title based on first user message.
        if sessions[index].title == "Yeni Sohbet", message.role == .user {
            sessions[index].title = String(message.content.prefix(40))
        }

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
                    self.lastErrorMessage = "Sohbet silinirken bir sorun oluştu."
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
                    self.lastErrorMessage = "Sohbetler temizlenemedi."
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
                    self.lastErrorMessage = "Mesaj kaydedilemedi. İnternetinizi kontrol edin."
                }
            }
        }
    }
}
