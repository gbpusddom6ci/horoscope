import Foundation
import Observation
import FirebaseFirestore

// MARK: - Firestore Service
/// Firestore wrapper for reading/writing app data.
@Observable
class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Collections

    private func usersCollection() -> CollectionReference {
        db.collection("users")
    }

    private func chatCollection(userId: String) -> CollectionReference {
        usersCollection().document(userId).collection("chatSessions")
    }

    private func dreamsCollection(userId: String) -> CollectionReference {
        usersCollection().document(userId).collection("dreamEntries")
    }

    private func chartsCollection(userId: String) -> CollectionReference {
        usersCollection().document(userId).collection("charts")
    }

    // MARK: - Remote User Document (raw)

    /// Fetches `users/{userId}` document from Firestore.
    func fetchUserDocument(userId: String) async throws -> DocumentSnapshot {
        try await usersCollection().document(userId).getDocument()
    }

    /// Creates or updates `users/{userId}` document in Firestore.
    func setUserDocument(userId: String, data: [String: Any], merge: Bool = true) async throws {
        try await usersCollection().document(userId).setData(data, merge: merge)
    }

    /// Updates fields of `users/{userId}` in Firestore.
    func updateUserDocument(userId: String, data: [String: Any]) async throws {
        try await usersCollection().document(userId).updateData(data)
    }

    // MARK: - User (Codable)

    func saveUser(_ user: AppUser) async throws {
        try usersCollection().document(user.id).setData(from: user, merge: true)
    }

    func getUser(id: String) async throws -> AppUser? {
        let snapshot = try await usersCollection().document(id).getDocument()
        guard snapshot.exists else {
            return nil
        }
        return try snapshot.data(as: AppUser.self)
    }

    // MARK: - Chat Sessions

    func saveChatSession(_ session: ChatSession) async throws {
        try chatCollection(userId: session.userId)
            .document(session.id)
            .setData(from: session, merge: true)
    }

    func getChatSessions(userId: String, context: ChatContext? = nil) async throws -> [ChatSession] {
        var query: Query = chatCollection(userId: userId)
        if let context {
            query = query.whereField("context", isEqualTo: context.rawValue)
        }
        query = query.order(by: "updatedAt", descending: true)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ChatSession.self) }
    }

    func deleteChatSession(userId: String, sessionId: String) async throws {
        try await chatCollection(userId: userId).document(sessionId).delete()
    }

    func clearChatSessions(userId: String) async throws {
        try await deleteAllDocuments(in: chatCollection(userId: userId))
    }

    // MARK: - Dream Entries

    func saveDreamEntry(_ entry: DreamEntry) async throws {
        try dreamsCollection(userId: entry.userId)
            .document(entry.id)
            .setData(from: entry, merge: true)
    }

    func getDreamEntries(userId: String) async throws -> [DreamEntry] {
        let snapshot = try await dreamsCollection(userId: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: DreamEntry.self) }
    }

    func deleteDreamEntry(userId: String, entryId: String) async throws {
        try await dreamsCollection(userId: userId).document(entryId).delete()
    }

    func clearDreamEntries(userId: String) async throws {
        try await deleteAllDocuments(in: dreamsCollection(userId: userId))
    }

    // MARK: - Chart Data

    func saveChartData(_ chart: ChartData, userId: String) async throws {
        try chartsCollection(userId: userId)
            .document(chart.type.rawValue)
            .setData(from: chart, merge: true)
    }

    func getChartData(userId: String, type: ChartType) async throws -> ChartData? {
        let snapshot = try await chartsCollection(userId: userId)
            .document(type.rawValue)
            .getDocument()

        guard snapshot.exists else {
            return nil
        }

        return try snapshot.data(as: ChartData.self)
    }

    func deleteChartData(userId: String, type: ChartType) async throws {
        try await chartsCollection(userId: userId)
            .document(type.rawValue)
            .delete()
    }

    // MARK: - Shared Helpers

    private func deleteAllDocuments(in collection: CollectionReference) async throws {
        let snapshot = try await collection.getDocuments()
        guard !snapshot.documents.isEmpty else {
            return
        }

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
}
