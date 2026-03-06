//
//  horoscopeApp.swift
//  horoscope
//
//  Created by malware on 2/25/26.
//

import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications
import os

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

// MARK: - App Delegate for Firebase Setup
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private let logger = Logger(subsystem: "rk.horoscope", category: "Push")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        NotificationCenter.default.post(name: .didReceiveFCMToken, object: fcmToken)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.badge, .sound, .banner, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if response.notification.request.identifier == "daily_horoscope_notification" {
            NotificationCenter.default.post(name: .switchToMainTab, object: AppTab.home)
        }
        
        if let action = userInfo["action"] as? String {
            switch action {
            case "chat":
                NotificationCenter.default.post(name: .switchToMainTab, object: AppTab.chat)
            case "dream":
                NotificationCenter.default.post(name: .switchToMainTab, object: AppTab.dream)
            case "chart":
                NotificationCenter.default.post(name: .switchToMainTab, object: AppTab.chart)
            case "profile":
                NotificationCenter.default.post(name: .switchToMainTab, object: AppTab.profile)
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// MARK: - Main App
@main
struct horoscopeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // Some singleton services may touch Firebase very early in app startup.
        // Configure once at app init to avoid timing-dependent warnings.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .preferredColorScheme(.dark)
        }
    }
}
