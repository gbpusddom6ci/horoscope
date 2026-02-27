import Foundation
import Observation
import os

/// Manages dream entries with Firestore as the source of truth.
@MainActor
@Observable
class DreamService {
    static let shared = DreamService()

    private(set) var entries: [DreamEntry] = []
    private(set) var lastErrorMessage: String?

    private let firestore = FirestoreService.shared
    private let logger = Logger(subsystem: "rk.horoscope", category: "DreamService")

    private init() {}

    // MARK: - Remote Sync

    func loadEntries(for userId: String) async {
        do {
            let remote = try await firestore.getDreamEntries(userId: userId)
            entries.removeAll { $0.userId == userId }
            entries.append(contentsOf: remote)
            lastErrorMessage = nil
        } catch {
            logger.error("Failed to load dream entries: \(error.localizedDescription, privacy: .public)")
            lastErrorMessage = String(localized: "dream.service.error.load")
        }
    }

    // MARK: - Public API

    /// Returns all dream entries for a given user, sorted by most recent.
    func entriesForUser(_ userId: String) -> [DreamEntry] {
        entries
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// True if user created at least one dream entry (first value metric).
    func hasEntries(for userId: String) -> Bool {
        !entriesForUser(userId).isEmpty
    }

    /// Earliest dream entry timestamp for first-value timing.
    func firstEntryDate(for userId: String) -> Date? {
        entriesForUser(userId).map(\.createdAt).min()
    }

    /// Adds a new dream entry and persists.
    func addEntry(_ entry: DreamEntry) {
        entries.insert(entry, at: 0)
        persistEntry(entry)
    }

    /// Updates an existing entry's interpretation.
    func updateInterpretation(_ interpretation: String, for entryId: String) {
        guard let index = entries.firstIndex(where: { $0.id == entryId }) else { return }
        entries[index].interpretation = interpretation
        persistEntry(entries[index])
    }

    /// Deletes an entry by ID.
    func deleteEntry(_ entryId: String) {
        guard let entry = entries.first(where: { $0.id == entryId }) else { return }
        entries.removeAll { $0.id == entryId }

        Task {
            do {
                try await firestore.deleteDreamEntry(userId: entry.userId, entryId: entryId)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to delete dream entry: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = String(localized: "dream.service.error.delete")
                }
            }
        }
    }

    /// Clears all entries for a user.
    func clearAllEntries(for userId: String) {
        entries.removeAll { $0.userId == userId }

        Task {
            do {
                try await firestore.clearDreamEntries(userId: userId)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to clear dream entries: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = String(localized: "dream.service.error.clear")
                }
            }
        }
    }

    private func persistEntry(_ entry: DreamEntry) {
        Task {
            do {
                try await firestore.saveDreamEntry(entry)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to persist dream entry: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = String(localized: "dream.service.error.persist")
                }
            }
        }
    }
}
