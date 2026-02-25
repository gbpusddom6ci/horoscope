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
        title: String = "Yeni Sohbet",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.context = context
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Last message preview for list display
    var lastMessagePreview: String {
        messages.last?.content ?? "Henüz mesaj yok"
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
