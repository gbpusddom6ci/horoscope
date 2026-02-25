//
//  horoscopeApp.swift
//  horoscope
//
//  Created by malware on 2/25/26.
//

import SwiftUI
import Firebase

// MARK: - App Delegate for Firebase Setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Try to configure Firebase safely to prevent crash if plist is missing
        if FirebaseApp.app() == nil {
            print("🚀 Attempting Firebase configuration...")
            FirebaseApp.configure()
            print("✅ Firebase configured successfully!")
        }
        return true
    }
}

// MARK: - Main App
@main
struct horoscopeApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            // First display a very simple view, ignoring AppRouter initially
            // This isolates whether the White Screen is from SwiftUI/Router
            // or from something else like Firebase crashing.
            AppRouter()
                .preferredColorScheme(.dark)
        }
    }
}
