# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS 16.0+ native SwiftUI astrology superapp with AI chat, natal chart interpretation, dream journaling, palm reading, and tarot features. Backend: Firebase Auth + Firestore. AI: OpenRouter → Google Gemini.

## Build & Test Commands

```bash
# Resolve SPM dependencies
xcodebuild -resolvePackageDependencies -project horoscope.xcodeproj

# Build for simulator
xcodebuild -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run unit tests (Swift Testing framework)
xcodebuild -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:horoscopeTests test

# Run UI tests
xcodebuild -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:horoscopeUITests test
```

If `iPhone 17` is unavailable, the CI auto-selects any available simulator. Check `xcrun simctl list devices` to find an available one.

## Secret Management

Secrets are NOT hardcoded. They are injected via `.xcconfig` files at build time.

1. Copy `Config/Secrets.template.xcconfig` → `Config/Secrets.xcconfig`
2. Fill in values (see template for required keys: `OPENROUTER_API_KEY`, `FREE_ASTRO_API_KEY`, `OPENROUTER_MODEL`, `PREMIUM_PRODUCT_IDS`, etc.)
3. `Secrets.xcconfig` is gitignored — never commit it

Runtime reads happen in `Core/Services/Secrets.swift` via `Info.plist` keys.

## Architecture

### State Machine Navigation (`Navigation/AppRouter.swift`)

`AppRouter` is the root entry point. It drives the entire app via `AuthService`'s auth state:

```
.unknown → .unauthenticated (Auth/Onboarding) → .onboarding → .authenticated (MainTabView)
```

`NetworkMonitor` is also observed by `AppRouter` to show a "No Internet" overlay automatically.

### Dependency Injection

Services are instantiated at `AppRouter` level and injected via SwiftUI's `.environment()` modifier. Feature views consume them with `@Environment`. The `@Observable` macro (iOS 17) is used for all service state — no `ObservableObject`/`@Published`.

### Core Services (`horoscope/Core/Services/`)

| Service | Responsibility |
|---|---|
| `AIService` | OpenRouter/Gemini API calls for chat, natal, dream, palm, tarot |
| `AuthService` | Firebase Auth state, Apple Sign-In, FCM token management |
| `FirestoreService` | All Firestore CRUD (users, chat sessions, dreams, charts) |
| `PremiumService` | StoreKit In-App Purchase integration |
| `UsageLimitService` | Freemium quota enforcement per feature |
| `ChatService` | Chat session management and title auto-generation |
| `DreamService` | Dream journal CRUD and interpretation |
| `AstrologyEngine` | Zodiac sign calculations, aspects, transits |
| `PlanetaryCalculator` | Natal chart math |
| `NotificationService` | APNs + FCM push notifications |
| `NetworkMonitor` | Internet connectivity monitoring |

### Feature Modules (`horoscope/Features/`)

Each feature has its own `Views/` and (where needed) `ViewModels/` subdirectory:
`Auth`, `Chat`, `Dreams`, `Home`, `NatalChart`, `Onboarding`, `PalmReading`, `Settings`, `Splash`, `Tarot`

### Design System (`horoscope/Core/Design/` and `Core/DesignSystem/`)

The UI is strictly dark-themed and custom — **never use standard `Color.red`, `Color.blue`, etc.**

- **Colors:** `MysticColors` — `voidBlack` backgrounds; accents are `mysticGold`, `neonLavender`, `auroraGreen`, `celestialPink`
- **Key components:** `MysticCard` (glow-framed container), `StarField` (Canvas-based animated star background, performance-critical), `MysticButton`, `MysticScreenScaffold`, `MysticTopBar`, `GlowingText`

## Critical Navigation Rule

**Root tab views (`HomeView`, `ChatView`, etc.) must NOT contain a `NavigationStack` directly.** This causes a swipe-to-pop bug at the tab bar level. Use nested `NavigationStack` inside sheets/fullscreenCover, or push from a child view.

## Testing

- **Unit tests:** Swift Testing framework (`@Test` macro), located in `horoscopeTests/`. Cover zodiac calculations, birth data, chat session logic, navigation quick actions, localization.
- **UI tests:** XCTest, located in `horoscopeUITests/`. Support `UITEST_AUTHENTICATED` launch argument to bypass auth during testing.
- **AI model in use:** `google/gemini-2.0-flash-001` via OpenRouter (agents.md references a preview model — use the xcconfig value at runtime).
