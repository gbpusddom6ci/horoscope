import Foundation
import os

/// Migrates legacy UserDefaults data (from pre-Firestore versions) into Firestore/Keychain-backed flow.
final class LegacyDataMigrationService {
    static let shared = LegacyDataMigrationService()

    private let defaults = UserDefaults.standard
    private let firestore = FirestoreService.shared
    private let logger = Logger(subsystem: "rk.horoscope", category: "LegacyMigration")

    private init() {}

    func migrateUserDataIfNeeded(for userId: String) async {
        let markerKey = "legacy_migrated_\(userId)"
        guard !defaults.bool(forKey: markerKey) else { return }

        do {
            try await migrateUserDocument(userId: userId)
            try await migrateChatSessions(userId: userId)
            try await migrateDreamEntries(userId: userId)
            try await migrateCharts(userId: userId)

            defaults.set(true, forKey: markerKey)
            removeLegacyKeys(for: userId)
        } catch {
            logger.error("Legacy migration failed for user \(userId, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadLegacySessionFromUserDefaults() -> AppUser? {
        guard let data = defaults.data(forKey: "currentUser") else {
            return nil
        }

        guard let user = try? JSONDecoder().decode(AppUser.self, from: data) else {
            return nil
        }

        if let encoded = try? JSONEncoder().encode(user) {
            _ = KeychainService.set(encoded, for: "currentUserSession")
        }

        defaults.removeObject(forKey: "currentUser")
        return user
    }

    private func migrateUserDocument(userId: String) async throws {
        guard let data = defaults.data(forKey: "user_\(userId)") else { return }
        let user = try JSONDecoder().decode(AppUser.self, from: data)
        try await firestore.saveUser(user)
    }

    private func migrateChatSessions(userId: String) async throws {
        guard let data = defaults.data(forKey: "chats_\(userId)") else { return }
        let sessions = try JSONDecoder().decode([ChatSession].self, from: data)
        for session in sessions where session.userId == userId {
            try await firestore.saveChatSession(session)
        }
    }

    private func migrateDreamEntries(userId: String) async throws {
        guard let data = defaults.data(forKey: "dreams_\(userId)") else { return }
        let entries = try JSONDecoder().decode([DreamEntry].self, from: data)
        for entry in entries where entry.userId == userId {
            try await firestore.saveDreamEntry(entry)
        }
    }

    private func migrateCharts(userId: String) async throws {
        let chartTypes: [ChartType] = [.natal, .transit]
        for chartType in chartTypes {
            let key = "chart_\(userId)_\(chartType.rawValue)"
            guard let data = defaults.data(forKey: key) else { continue }
            let chart = try JSONDecoder().decode(ChartData.self, from: data)
            try await firestore.saveChartData(chart, userId: userId)
        }
    }

    private func removeLegacyKeys(for userId: String) {
        defaults.removeObject(forKey: "user_\(userId)")
        defaults.removeObject(forKey: "chats_\(userId)")
        defaults.removeObject(forKey: "dreams_\(userId)")
        defaults.removeObject(forKey: "chart_\(userId)_\(ChartType.natal.rawValue)")
        defaults.removeObject(forKey: "chart_\(userId)_\(ChartType.transit.rawValue)")
    }
}
