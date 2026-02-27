import Foundation

// MARK: - Chat Message
struct ChatMessage: Codable, Identifiable {
    let id: String
    var role: ChatRole
    var content: String
    var timestamp: Date
    var context: ChatContext

    init(
        id: String = UUID().uuidString,
        role: ChatRole,
        content: String,
        timestamp: Date = Date(),
        context: ChatContext = .general
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.context = context
    }
}

enum ChatRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - Chat Context (which module the chat belongs to)
enum ChatContext: String, Codable {
    case general = "general"
    case natal = "natal"
    case transit = "transit"
    case dream = "dream"
    case palmReading = "palmReading"
    case tarot = "tarot"
    case coffee = "coffee"

    var localizedDisplayName: String {
        switch self {
        case .general:
            return String(localized: "chat.context.general")
        case .natal:
            return String(localized: "chat.context.natal")
        case .transit:
            return String(localized: "chat.context.transit")
        case .dream:
            return String(localized: "chat.context.dream")
        case .palmReading:
            return String(localized: "chat.context.palm")
        case .tarot:
            return String(localized: "chat.context.tarot")
        case .coffee:
            return String(localized: "chat.context.coffee")
        }
    }
}

// MARK: - Chat Session
struct ChatSession: Codable, Identifiable {
    let id: String
    var userId: String
    var context: ChatContext
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        context: ChatContext = .general,
        title: String = "",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.context = context
        self.title = title.isEmpty ? String(localized: "chat.session.new_title") : title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Last message preview for list display
    var lastMessagePreview: String {
        messages.last?.content ?? String(localized: "chat.session.empty_preview")
    }
}

// MARK: - Dream Entry
struct DreamEntry: Codable, Identifiable {
    let id: String
    var userId: String
    var dreamText: String
    var interpretation: String?
    var chatSession: ChatSession?
    var mood: DreamMood?
    var tags: [String]
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        dreamText: String,
        interpretation: String? = nil,
        chatSession: ChatSession? = nil,
        mood: DreamMood? = nil,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.dreamText = dreamText
        self.interpretation = interpretation
        self.chatSession = chatSession
        self.mood = mood
        self.tags = tags
        self.createdAt = createdAt
    }
}

enum DreamMood: String, Codable, CaseIterable {
    case peaceful = "Huzurlu"
    case scary = "Korkutucu"
    case exciting = "Heyecanlı"
    case confusing = "Kafa Karıştırıcı"
    case sad = "Hüzünlü"
    case happy = "Mutlu"
    case neutral = "Nötr"

    var localizedDisplayName: String {
        switch self {
        case .peaceful: return String(localized: "dream.mood.peaceful")
        case .scary: return String(localized: "dream.mood.scary")
        case .exciting: return String(localized: "dream.mood.exciting")
        case .confusing: return String(localized: "dream.mood.confusing")
        case .sad: return String(localized: "dream.mood.sad")
        case .happy: return String(localized: "dream.mood.happy")
        case .neutral: return String(localized: "dream.mood.neutral")
        }
    }

    var emoji: String {
        switch self {
        case .peaceful: return "😌"
        case .scary: return "😨"
        case .exciting: return "🤩"
        case .confusing: return "🤔"
        case .sad: return "😢"
        case .happy: return "😊"
        case .neutral: return "😐"
        }
    }
}

// MARK: - Palm Reading
struct PalmReading: Codable, Identifiable {
    let id: String
    var userId: String
    var imageURL: String?
    var interpretation: String?
    var chatSession: ChatSession?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        imageURL: String? = nil,
        interpretation: String? = nil,
        chatSession: ChatSession? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageURL = imageURL
        self.interpretation = interpretation
        self.chatSession = chatSession
        self.createdAt = createdAt
    }
}
