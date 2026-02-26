import Foundation
import Observation
import UserNotifications
import UIKit

@MainActor
@Observable
final class NotificationService {
    static let shared = NotificationService()

    private enum Keys {
        static let enabled = "daily_horoscope_notifications_enabled"
        static let hour = "daily_horoscope_notifications_hour"
        static let minute = "daily_horoscope_notifications_minute"
    }

    private let notificationID = "daily_horoscope_notification"

    var isAuthorized = false
    var dailyNotificationsEnabled = false
    var notificationTime: Date
    var lastErrorMessage: String?

    private init() {
        let defaults = UserDefaults.standard
        let savedHour = defaults.object(forKey: Keys.hour) as? Int ?? 9
        let savedMinute = defaults.object(forKey: Keys.minute) as? Int ?? 0
        let savedEnabled = defaults.bool(forKey: Keys.enabled)

        var components = DateComponents()
        components.hour = savedHour
        components.minute = savedMinute
        notificationTime = Calendar.current.date(from: components) ?? Date()
        dailyNotificationsEnabled = savedEnabled

        Task {
            await refreshAuthorizationStatus()
            if dailyNotificationsEnabled {
                await updateSchedule()
            }
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func setDailyNotificationsEnabled(_ enabled: Bool) async {
        if enabled {
            let granted = await requestAuthorizationIfNeeded()
            guard granted else {
                dailyNotificationsEnabled = false
                lastErrorMessage = "Bildirim izni verilmedi. iOS Ayarlar'dan izin açabilirsiniz."
                persistPreferences()
                return
            }
        }

        dailyNotificationsEnabled = enabled
        persistPreferences()
        await updateSchedule()
    }

    func setNotificationTime(_ date: Date) async {
        notificationTime = date
        persistPreferences()

        if dailyNotificationsEnabled {
            await updateSchedule()
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()
        if isAuthorized {
            return true
        }

        let granted = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }

        await refreshAuthorizationStatus()
        if !(granted && isAuthorized) {
            lastErrorMessage = "Bildirim izni kapalı. Ayarlar > Bildirimler üzerinden izin verebilirsiniz."
        } else {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return granted && isAuthorized
    }

    private func updateSchedule() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        guard dailyNotificationsEnabled else {
            return
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)

        let content = UNMutableNotificationContent()
        content.title = "Mystic Günlük Yorumu"
        content.body = "Yıldızlardan bugünkü mesajınız hazır. Açıp göz atabilirsiniz."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        do {
            try await center.add(request)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Bildirim planlanamadı. Lütfen tekrar deneyin."
        }
    }

    private func persistPreferences() {
        let defaults = UserDefaults.standard
        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)

        defaults.set(dailyNotificationsEnabled, forKey: Keys.enabled)
        defaults.set(components.hour ?? 9, forKey: Keys.hour)
        defaults.set(components.minute ?? 0, forKey: Keys.minute)
    }
}
