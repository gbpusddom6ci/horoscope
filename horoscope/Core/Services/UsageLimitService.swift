import Foundation
import Observation

/// Tracks and enforces daily usage limits for free users.
@MainActor
@Observable
final class UsageLimitService {
    static let shared = UsageLimitService()

    var authService: AuthService?
    private let defaults = UserDefaults.standard

    // Keys
    private let lastResetDateKey = "UsageLimitService_LastResetDate"
    private let chatMessageCountKey = "UsageLimitService_ChatMessageCount"
    private let palmReadingCountKey = "UsageLimitService_PalmReadingCount"
    private let natalInterpretationCountKey = "UsageLimitService_NatalInterpretationCount"
    private let dreamInterpretationCountKey = "UsageLimitService_DreamInterpretationCount"

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

    // MARK: - Core Logic

    private func checkAndResetDailyLimits() {
        let calendar = Calendar.current
        let today = Date()

        if let lastReset = defaults.object(forKey: lastResetDateKey) as? Date {
            if !calendar.isDate(today, inSameDayAs: lastReset) {
                resetCounts(today)
            }
        } else {
            resetCounts(today)
        }
    }

    private func resetCounts(_ date: Date) {
        defaults.set(date, forKey: lastResetDateKey)
        defaults.set(0, forKey: chatMessageCountKey)
        defaults.set(0, forKey: palmReadingCountKey)
        defaults.set(0, forKey: natalInterpretationCountKey)
        defaults.set(0, forKey: dreamInterpretationCountKey)
    }

    private func loadCounts() {
        chatMessageCount = defaults.integer(forKey: chatMessageCountKey)
        palmReadingCount = defaults.integer(forKey: palmReadingCountKey)
        natalInterpretationCount = defaults.integer(forKey: natalInterpretationCountKey)
        dreamInterpretationCount = defaults.integer(forKey: dreamInterpretationCountKey)
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
            defaults.set(chatMessageCount, forKey: chatMessageCountKey)
        case .palmReading:
            palmReadingCount += 1
            defaults.set(palmReadingCount, forKey: palmReadingCountKey)
        case .natalInterpretation:
            natalInterpretationCount += 1
            defaults.set(natalInterpretationCount, forKey: natalInterpretationCountKey)
        case .dreamInterpretation:
            dreamInterpretationCount += 1
            defaults.set(dreamInterpretationCount, forKey: dreamInterpretationCountKey)
        }
    }
}

enum AIAction {
    case chatMessage
    case palmReading
    case natalInterpretation
    case dreamInterpretation
}
