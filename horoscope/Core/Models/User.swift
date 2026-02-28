import Foundation

// MARK: - App User
struct AppUser: Codable, Identifiable {
    let id: String                  // Firebase Auth UID
    var displayName: String
    var email: String?
    var birthData: BirthData?
    var isPremium: Bool
    var createdAt: Date
    var lastActiveAt: Date?
    var fcmToken: String?
    var hasCompletedOnboarding: Bool

    init(
        id: String,
        displayName: String,
        email: String? = nil,
        birthData: BirthData? = nil,
        isPremium: Bool = false,
        createdAt: Date = Date(),
        lastActiveAt: Date? = nil,
        fcmToken: String? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.birthData = birthData
        self.isPremium = isPremium
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.fcmToken = fcmToken
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
