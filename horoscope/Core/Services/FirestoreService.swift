import Foundation
import Observation
import FirebaseFirestore

// MARK: - Firestore Service
/// Firestore wrapper for reading/writing user data, chat sessions, etc.
/// Currently uses local storage as mock. Replace with real Firestore after SDK integration.
@Observable
class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Remote User Document (Firestore)

    /// Fetches `users/{userId}` document from Firestore.
    func fetchUserDocument(userId: String) async throws -> DocumentSnapshot {
        try await db.collection("users").document(userId).getDocument()
    }

    /// Creates or updates `users/{userId}` document in Firestore.
    func setUserDocument(userId: String, data: [String: Any], merge: Bool = true) async throws {
        try await db.collection("users").document(userId).setData(data, merge: merge)
    }

    /// Updates fields of `users/{userId}` in Firestore.
    func updateUserDocument(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }

    // MARK: - User

    func saveUser(_ user: AppUser) async throws {
        // TODO: Replace with Firestore document write
        // db.collection("users").document(user.id).setData(...)
        let data = try JSONEncoder().encode(user)
        UserDefaults.standard.set(data, forKey: "user_\(user.id)")
    }

    func getUser(id: String) async throws -> AppUser? {
        // TODO: Replace with Firestore document read
        guard let data = UserDefaults.standard.data(forKey: "user_\(id)") else {
            return nil
        }
        return try JSONDecoder().decode(AppUser.self, from: data)
    }

    // MARK: - Chat Sessions

    func saveChatSession(_ session: ChatSession) async throws {
        // TODO: Replace with Firestore subcollection write
        // db.collection("users").document(session.userId)
        //   .collection("chatSessions").document(session.id).setData(...)
        var sessions = loadChatSessions(userId: session.userId)
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        let data = try JSONEncoder().encode(sessions)
        UserDefaults.standard.set(data, forKey: "chats_\(session.userId)")
    }

    func getChatSessions(userId: String, context: ChatContext? = nil) async throws -> [ChatSession] {
        let sessions = loadChatSessions(userId: userId)
        if let context = context {
            return sessions.filter { $0.context == context }
        }
        return sessions
    }

    private func loadChatSessions(userId: String) -> [ChatSession] {
        guard let data = UserDefaults.standard.data(forKey: "chats_\(userId)") else {
            return []
        }
        return (try? JSONDecoder().decode([ChatSession].self, from: data)) ?? []
    }

    // MARK: - Dream Entries

    func saveDreamEntry(_ entry: DreamEntry) async throws {
        var entries = loadDreamEntries(userId: entry.userId)
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        let data = try JSONEncoder().encode(entries)
        UserDefaults.standard.set(data, forKey: "dreams_\(entry.userId)")
    }

    func getDreamEntries(userId: String) async throws -> [DreamEntry] {
        return loadDreamEntries(userId: userId)
    }

    private func loadDreamEntries(userId: String) -> [DreamEntry] {
        guard let data = UserDefaults.standard.data(forKey: "dreams_\(userId)") else {
            return []
        }
        return (try? JSONDecoder().decode([DreamEntry].self, from: data)) ?? []
    }

    // MARK: - Chart Data

    func saveChartData(_ chart: ChartData, userId: String) async throws {
        let data = try JSONEncoder().encode(chart)
        UserDefaults.standard.set(data, forKey: "chart_\(userId)_\(chart.type.rawValue)")
    }

    func getChartData(userId: String, type: ChartType) async throws -> ChartData? {
        guard let data = UserDefaults.standard.data(forKey: "chart_\(userId)_\(type.rawValue)") else {
            return nil
        }
        return try JSONDecoder().decode(ChartData.self, from: data)
    }
}
