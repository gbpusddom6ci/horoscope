import Foundation
import Observation

/// Tracks and enforces daily usage limits for free users.
@MainActor
@Observable
final class UsageLimitService {
    static let shared = UsageLimitService()

    var authService: AuthService?
    private let defaults = UserDefaults.standard

    // Base keys (scoped per user identifier)
    private let lastResetDateKeyBase = "UsageLimitService_LastResetDate"
    private let chatMessageCountKeyBase = "UsageLimitService_ChatMessageCount"
    private let palmReadingCountKeyBase = "UsageLimitService_PalmReadingCount"
    private let natalInterpretationCountKeyBase = "UsageLimitService_NatalInterpretationCount"
    private let dreamInterpretationCountKeyBase = "UsageLimitService_DreamInterpretationCount"

    // Limits
    private let chatMessageLimit = 3
    private let palmReadingLimit = 1
    private let natalInterpretationLimit = 2
    private let dreamInterpretationLimit = 2

    // State Variables for views to observe
    var showPaywall: Bool = false
    
    // Published Counts
    private(set) var chatMessageCount: Int = 0
    private(set) var palmReadingCount: Int = 0
    private(set) var natalInterpretationCount: Int = 0
    private(set) var dreamInterpretationCount: Int = 0

    private init() {
        checkAndResetDailyLimits()
        loadCounts()
    }

    func refreshForCurrentUser() {
        checkAndResetDailyLimits()
        loadCounts()
        showPaywall = false
    }

    // MARK: - Core Logic

    private func checkAndResetDailyLimits() {
        let calendar = Calendar.current
        let today = Date()
        let lastResetDateKey = scopedKey(lastResetDateKeyBase)

        if let lastReset = defaults.object(forKey: lastResetDateKey) as? Date {
            if !calendar.isDate(today, inSameDayAs: lastReset) {
                resetCounts(today)
            }
        } else {
            resetCounts(today)
        }
    }

    private func resetCounts(_ date: Date) {
        defaults.set(date, forKey: scopedKey(lastResetDateKeyBase))
        defaults.set(0, forKey: scopedKey(chatMessageCountKeyBase))
        defaults.set(0, forKey: scopedKey(palmReadingCountKeyBase))
        defaults.set(0, forKey: scopedKey(natalInterpretationCountKeyBase))
        defaults.set(0, forKey: scopedKey(dreamInterpretationCountKeyBase))
    }

    private func loadCounts() {
        chatMessageCount = defaults.integer(forKey: scopedKey(chatMessageCountKeyBase))
        palmReadingCount = defaults.integer(forKey: scopedKey(palmReadingCountKeyBase))
        natalInterpretationCount = defaults.integer(forKey: scopedKey(natalInterpretationCountKeyBase))
        dreamInterpretationCount = defaults.integer(forKey: scopedKey(dreamInterpretationCountKeyBase))
    }

    private func scopedKey(_ base: String) -> String {
        let userId = authService?.currentUser?.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let scope = userId.flatMap { $0.isEmpty ? nil : $0 } ?? "anonymous"
        return "\(base)_\(scope)"
    }

    private var hasPremium: Bool {
        authService?.currentUser?.isPremium == true || PremiumService.shared.hasPremiumAccess
    }

    // MARK: - Action Verification

    /// Call this before performing an action. It returns `true` if allowed.
    /// If `false`, it automatically triggers the Paywall sheet.
    func canPerformAction(_ action: AIAction) -> Bool {
        if hasPremium { return true }
        
        checkAndResetDailyLimits()
        
        let canPerform: Bool
        switch action {
        case .chatMessage:
            canPerform = chatMessageCount < chatMessageLimit
        case .palmReading:
            canPerform = palmReadingCount < palmReadingLimit
        case .natalInterpretation:
            canPerform = natalInterpretationCount < natalInterpretationLimit
        case .dreamInterpretation:
            canPerform = dreamInterpretationCount < dreamInterpretationLimit
        }
        
        if !canPerform {
            showPaywall = true
        }
        
        return canPerform
    }

    /// Call this immediately AFTER an action successfully completes.
    func recordAction(_ action: AIAction) {
        if hasPremium { return } // Don't bother counting for premium users
        
        switch action {
        case .chatMessage:
            chatMessageCount += 1
            defaults.set(chatMessageCount, forKey: scopedKey(chatMessageCountKeyBase))
        case .palmReading:
            palmReadingCount += 1
            defaults.set(palmReadingCount, forKey: scopedKey(palmReadingCountKeyBase))
        case .natalInterpretation:
            natalInterpretationCount += 1
            defaults.set(natalInterpretationCount, forKey: scopedKey(natalInterpretationCountKeyBase))
        case .dreamInterpretation:
            dreamInterpretationCount += 1
            defaults.set(dreamInterpretationCount, forKey: scopedKey(dreamInterpretationCountKeyBase))
        }
    }
}

enum AIAction {
    case chatMessage
    case palmReading
    case natalInterpretation
    case dreamInterpretation
}
