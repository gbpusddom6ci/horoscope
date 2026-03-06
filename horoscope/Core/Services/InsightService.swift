import Foundation
import Observation
import os

@MainActor
@Observable
final class InsightService {
    static let shared = InsightService()

    private(set) var insights: [SavedInsight] = []
    private(set) var lastErrorMessage: String?

    private let firestore = FirestoreService.shared
    private let logger = Logger(subsystem: "rk.horoscope", category: "InsightService")

    private init() {}

    func loadInsights(for userId: String) async {
        do {
            let remote = try await firestore.getSavedInsights(userId: userId)
            insights.removeAll { $0.userId == userId }
            insights.append(contentsOf: remote)
            lastErrorMessage = nil
        } catch {
            logger.error("Failed to load saved insights: \(error.localizedDescription, privacy: .public)")
            lastErrorMessage = "Could not load saved insights."
        }
    }

    func insightsForUser(_ userId: String) -> [SavedInsight] {
        insights
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func saveInsight(_ insight: SavedInsight) {
        if let index = insights.firstIndex(where: { $0.id == insight.id }) {
            insights[index] = insight
        } else {
            insights.insert(insight, at: 0)
        }

        Task {
            do {
                try await firestore.saveSavedInsight(insight)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to persist saved insight: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = "Could not save this insight."
                }
            }
        }
    }

    func deleteInsight(_ insightId: String) {
        guard let insight = insights.first(where: { $0.id == insightId }) else { return }
        insights.removeAll { $0.id == insightId }

        Task {
            do {
                try await firestore.deleteSavedInsight(userId: insight.userId, insightId: insightId)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to delete saved insight: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = "Could not remove this insight."
                }
            }
        }
    }
}
