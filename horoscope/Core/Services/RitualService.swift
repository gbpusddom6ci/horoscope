import Foundation
import Observation
import os

@MainActor
@Observable
final class RitualService {
    static let shared = RitualService()

    private(set) var states: [String: DailyRitualState] = [:]
    private(set) var lastErrorMessage: String?

    private let firestore = FirestoreService.shared
    private let logger = Logger(subsystem: "rk.horoscope", category: "RitualService")

    private init() {}

    func state(for userId: String, on date: Date = Date()) -> DailyRitualState? {
        states[storageKey(userId: userId, date: date)]
    }

    func loadState(for userId: String, on date: Date = Date()) async {
        let key = storageKey(userId: userId, date: date)

        do {
            if let remote = try await firestore.getDailyRitualState(userId: userId, date: date) {
                states[key] = remote
            } else {
                let fallback = DailyRitualState(
                    id: DailyRitualState.dateKey(for: date),
                    userId: userId,
                    date: Calendar.current.startOfDay(for: date),
                    streakCount: previousStreak(for: userId, before: date)
                )
                states[key] = fallback
                try await firestore.saveDailyRitualState(fallback)
            }
            lastErrorMessage = nil
        } catch {
            logger.error("Failed to load ritual state: \(error.localizedDescription, privacy: .public)")
            lastErrorMessage = "Could not load your ritual state."
        }
    }

    func markMorningComplete(for userId: String, sessionId: String? = nil, date: Date = Date()) {
        mutateState(for: userId, date: date) { state in
            state.morningCheckInCompleted = true
            state.oracleSessionId = sessionId ?? state.oracleSessionId
            if state.streakCount == 0 {
                state.streakCount = max(previousStreak(for: userId, before: date), 0) + 1
            }
        }
    }

    func markDreamCaptured(for userId: String, date: Date = Date()) {
        mutateState(for: userId, date: date) { state in
            state.dreamCaptured = true
        }
    }

    func markEveningReflectionComplete(for userId: String, date: Date = Date()) {
        mutateState(for: userId, date: date) { state in
            state.eveningReflectionCompleted = true
        }
    }

    private func mutateState(for userId: String, date: Date, mutation: (inout DailyRitualState) -> Void) {
        let key = storageKey(userId: userId, date: date)
        var state = states[key] ?? DailyRitualState(
            id: DailyRitualState.dateKey(for: date),
            userId: userId,
            date: Calendar.current.startOfDay(for: date),
            streakCount: max(previousStreak(for: userId, before: date), 0)
        )
        mutation(&state)
        state.updatedAt = Date()
        states[key] = state

        Task {
            do {
                try await firestore.saveDailyRitualState(state)
                await MainActor.run {
                    self.lastErrorMessage = nil
                }
            } catch {
                logger.error("Failed to persist ritual state: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.lastErrorMessage = "Could not update ritual progress."
                }
            }
        }
    }

    private func previousStreak(for userId: String, before date: Date) -> Int {
        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        let key = storageKey(userId: userId, date: previousDate)
        return states[key]?.streakCount ?? 0
    }

    private func storageKey(userId: String, date: Date) -> String {
        "\(userId)-\(DailyRitualState.dateKey(for: date))"
    }
}
