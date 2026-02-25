import Foundation
import Observation

/// Manages dream entry persistence — saves/loads entries from UserDefaults.
/// TODO: Migrate to Firestore when ready.
@Observable
class DreamService {
    static let shared = DreamService()

    private(set) var entries: [DreamEntry] = []

    private let storageKey = "dreamEntries"

    private init() {
        loadEntries()
    }

    // MARK: - Public API

    /// Returns all dream entries for a given user, sorted by most recent.
    func entriesForUser(_ userId: String) -> [DreamEntry] {
        entries
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Adds a new dream entry and persists.
    func addEntry(_ entry: DreamEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }

    /// Updates an existing entry's interpretation.
    func updateInterpretation(_ interpretation: String, for entryId: String) {
        guard let index = entries.firstIndex(where: { $0.id == entryId }) else { return }
        entries[index].interpretation = interpretation
        saveEntries()
    }

    /// Deletes an entry by ID.
    func deleteEntry(_ entryId: String) {
        entries.removeAll { $0.id == entryId }
        saveEntries()
    }

    /// Clears all entries for a user (e.g., on sign out).
    func clearAllEntries(for userId: String) {
        entries.removeAll { $0.userId == userId }
        saveEntries()
    }

    // MARK: - Persistence (UserDefaults)

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DreamEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded
    }
}
