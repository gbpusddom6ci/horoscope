import Foundation

enum GuidanceIntent: String, Codable, CaseIterable, Identifiable {
    case clarity
    case love
    case career
    case healing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clarity:
            return String(localized: "guidance.intent.clarity.title")
        case .love:
            return String(localized: "guidance.intent.love.title")
        case .career:
            return String(localized: "guidance.intent.career.title")
        case .healing:
            return String(localized: "guidance.intent.healing.title")
        }
    }

    var subtitle: String {
        switch self {
        case .clarity:
            return String(localized: "guidance.intent.clarity.subtitle")
        case .love:
            return String(localized: "guidance.intent.love.subtitle")
        case .career:
            return String(localized: "guidance.intent.career.subtitle")
        case .healing:
            return String(localized: "guidance.intent.healing.subtitle")
        }
    }

    var iconName: String {
        switch self {
        case .clarity:
            return "sparkles.rectangle.stack"
        case .love:
            return "heart.circle.fill"
        case .career:
            return "briefcase.circle.fill"
        case .healing:
            return "cross.case.circle.fill"
        }
    }
}

enum PreferredSessionTone: String, Codable, CaseIterable {
    case softSpiritual
    case grounded
    case poetic

    var title: String {
        switch self {
        case .softSpiritual:
            return String(localized: "session_tone.soft_spiritual")
        case .grounded:
            return String(localized: "session_tone.grounded")
        case .poetic:
            return String(localized: "session_tone.poetic")
        }
    }
}

enum SavedInsightSourceType: String, Codable {
    case oracle
    case chart
    case dailyRitual
}

struct SavedInsight: Codable, Identifiable, Equatable {
    let id: String
    var userId: String
    var sourceType: SavedInsightSourceType
    var sourceRefId: String
    var title: String
    var summary: String
    var createdAt: Date
    var accentKey: String

    init(
        id: String = UUID().uuidString,
        userId: String,
        sourceType: SavedInsightSourceType,
        sourceRefId: String,
        title: String,
        summary: String,
        createdAt: Date = Date(),
        accentKey: String = "oracle"
    ) {
        self.id = id
        self.userId = userId
        self.sourceType = sourceType
        self.sourceRefId = sourceRefId
        self.title = title
        self.summary = summary
        self.createdAt = createdAt
        self.accentKey = accentKey
    }
}

struct DailyRitualState: Codable, Identifiable, Equatable {
    let id: String
    var userId: String
    var date: Date
    var morningCheckInCompleted: Bool
    var oracleSessionId: String?
    var eveningReflectionCompleted: Bool
    var dreamCaptured: Bool
    var streakCount: Int
    var updatedAt: Date

    init(
        id: String = DailyRitualState.dateKey(for: Date()),
        userId: String,
        date: Date = Date(),
        morningCheckInCompleted: Bool = false,
        oracleSessionId: String? = nil,
        eveningReflectionCompleted: Bool = false,
        dreamCaptured: Bool = false,
        streakCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.morningCheckInCompleted = morningCheckInCompleted
        self.oracleSessionId = oracleSessionId
        self.eveningReflectionCompleted = eveningReflectionCompleted
        self.dreamCaptured = dreamCaptured
        self.streakCount = streakCount
        self.updatedAt = updatedAt
    }

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Calendar.current.startOfDay(for: date))
    }
}

struct WeeklyReflectionSummary: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let createdAt: Date
}

enum JournalFeedItem: Identifiable {
    case dream(DreamEntry)
    case insight(SavedInsight)

    var id: String {
        switch self {
        case .dream(let dream):
            return "dream-\(dream.id)"
        case .insight(let insight):
            return "insight-\(insight.id)"
        }
    }

    var createdAt: Date {
        switch self {
        case .dream(let dream):
            return dream.createdAt
        case .insight(let insight):
            return insight.createdAt
        }
    }
}
