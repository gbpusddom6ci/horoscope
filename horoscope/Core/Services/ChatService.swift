import Foundation
import Observation

/// Manages chat session persistence — saves/loads sessions from UserDefaults.
/// TODO: Migrate to Firestore when ready.
@Observable
class ChatService {
    static let shared = ChatService()

    private(set) var sessions: [ChatSession] = []

    private let storageKey = "chatSessions"

    private init() {
        loadSessions()
    }

    // MARK: - Public API

    /// Returns the most recent session for a given context, or creates a new one.
    func activeSession(for userId: String, context: ChatContext) -> ChatSession {
        if let existing = sessions.first(where: { $0.userId == userId && $0.context == context }) {
            return existing
        }
        let newSession = ChatSession(userId: userId, context: context)
        sessions.insert(newSession, at: 0)
        saveSessions()
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

        // Auto-title based on first user message
        if sessions[index].title == "Yeni Sohbet",
           message.role == .user {
            sessions[index].title = String(message.content.prefix(40))
        }

        saveSessions()
    }

    /// Creates a brand new session for the given context.
    func createNewSession(userId: String, context: ChatContext) -> ChatSession {
        let session = ChatSession(userId: userId, context: context)
        sessions.insert(session, at: 0)
        saveSessions()
        return session
    }

    /// Deletes a session by ID.
    func deleteSession(_ sessionId: String) {
        sessions.removeAll { $0.id == sessionId }
        saveSessions()
    }

    /// Clears all sessions for a user (e.g., on sign out).
    func clearAllSessions(for userId: String) {
        sessions.removeAll { $0.userId == userId }
        saveSessions()
    }

    // MARK: - Persistence (UserDefaults — replace with Firestore later)

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            sessions = []
            return
        }
        sessions = decoded
    }
}
