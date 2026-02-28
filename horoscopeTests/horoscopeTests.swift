//
//  horoscopeTests.swift
//  horoscopeTests
//
//  Created by malware on 2/25/26.
//

import Testing
import Foundation
@testable import horoscope

struct horoscopeTests {

    @Test("Zodiac boundary dates are mapped correctly")
    func zodiacBoundaryDates() {
        #expect(ZodiacSign.from(month: 3, day: 21) == .aries)
        #expect(ZodiacSign.from(month: 4, day: 19) == .aries)
        #expect(ZodiacSign.from(month: 4, day: 20) == .taurus)
        #expect(ZodiacSign.from(month: 12, day: 25) == .capricorn)
        #expect(ZodiacSign.from(month: 2, day: 20) == .pisces)
    }

    @Test("BirthData computes sun sign and known-time state")
    func birthDataSunSign() {
        var components = DateComponents()
        components.year = 1992
        components.month = 5
        components.day = 12
        let date = Calendar(identifier: .gregorian).date(from: components) ?? Date()

        let birthData = BirthData(
            birthDate: date,
            birthTime: nil,
            birthPlace: "Istanbul",
            latitude: 41.0082,
            longitude: 28.9784,
            timeZoneIdentifier: "Europe/Istanbul"
        )

        #expect(birthData.sunSign == .taurus)
        #expect(birthData.isBirthTimeKnown == false)
    }

    @Test("Chat session preview returns fallback and latest message")
    func chatSessionPreview() {
        var session = ChatSession(userId: "user-1")
        #expect(session.lastMessagePreview == String(localized: "chat.session.empty_preview"))

        session.messages.append(
            ChatMessage(role: .assistant, content: "Welcome")
        )
        #expect(session.lastMessagePreview == "Welcome")
    }

    @Test("Chat title auto-generates from first user message when untitled")
    func chatSessionAutoTitleGeneration() {
        let firstUserMessage = ChatMessage(role: .user, content: "   Please read my weekly energy and transit themes in detail   ")
        let updated = ChatService.updatedTitle(
            currentTitle: String(localized: "chat.session.new_title"),
            existingMessages: [],
            incomingMessage: firstUserMessage
        )

        let expected = String(firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        #expect(updated == expected)
    }

    @Test("Chat title is preserved for custom titles or non-first user messages")
    func chatSessionTitlePreservation() {
        let incoming = ChatMessage(role: .user, content: "New question")
        let existingUser = ChatMessage(role: .user, content: "Previous question")

        let preservedCustom = ChatService.updatedTitle(
            currentTitle: "My Custom Title",
            existingMessages: [],
            incomingMessage: incoming
        )
        #expect(preservedCustom == "My Custom Title")

        let preservedAfterFirst = ChatService.updatedTitle(
            currentTitle: String(localized: "chat.session.new_title"),
            existingMessages: [existingUser],
            incomingMessage: incoming
        )
        #expect(preservedAfterFirst == String(localized: "chat.session.new_title"))
    }

    @Test("Transit duration is calculated from start and end dates")
    func transitDuration() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 5, to: start) ?? start

        let transit = TransitEvent(
            transitPlanet: .jupiter,
            natalPlanet: .sun,
            aspectType: .trine,
            exactDate: start,
            startDate: start,
            endDate: end,
            severity: .medium,
            description: "Test transit"
        )

        #expect(transit.durationDays == 5)
    }

    @Test("AppTab raw values support persistence")
    func appTabRawRoundTrip() {
        for tab in AppTab.allCases {
            #expect(AppTab(rawValue: tab.rawValue) == tab)
        }
    }

    @Test("Navigation quick actions retain pending payloads until consumed")
    func navigationQuickActionPendingPayloads() {
        AppNavigation.openChat(context: .tarot, prompt: "test prompt")
        let pendingChat = AppNavigation.consumePendingChatQuickAction()
        #expect(pendingChat?.context == .tarot)
        #expect(pendingChat?.prompt == "test prompt")
        #expect(AppNavigation.consumePendingChatQuickAction() == nil)

        AppNavigation.openDreamComposer()
        #expect(AppNavigation.consumePendingDreamComposer())
        #expect(!AppNavigation.consumePendingDreamComposer())

        AppNavigation.openTarotQuickAction()
        #expect(AppNavigation.consumePendingTarotQuickAction())
        #expect(!AppNavigation.consumePendingTarotQuickAction())

        AppNavigation.openPalmQuickAction()
        #expect(AppNavigation.consumePendingPalmQuickAction())
        #expect(!AppNavigation.consumePendingPalmQuickAction())
    }

    @Test("Additional chat contexts can be restored from raw values")
    func chatContextRoundTrip() {
        #expect(ChatContext(rawValue: "general") == .general)
        #expect(ChatContext(rawValue: "dream") == .dream)
        #expect(ChatContext(rawValue: "palmReading") == .palmReading)
        #expect(ChatContext(rawValue: "tarot") == .tarot)
        #expect(ChatContext(rawValue: "coffee") == .coffee)
    }

    @Test("Main chrome reserved space includes quick action clearance")
    func mainChromeReservedSpaceIncludesQuickAction() {
        let metrics = MainChromeMetrics(
            tabBarVisible: true,
            tabBarHeight: 78,
            floatingQuickActionSize: 56,
            bottomSafeAreaInset: 34
        )

        #expect(metrics.floatingQuickActionClearance > 0)
        #expect(metrics.contentBottomReservedSpace > metrics.tabBarHeight)

        let hidden = MainChromeMetrics.hidden
        #expect(hidden.contentBottomReservedSpace == MysticLayout.contentBottomExtraSpacing)
    }

    @Test("Tab bar bottom padding aligns with native bottom spacing")
    func tabBarBottomPaddingAlignment() {
        #expect(MysticLayout.tabBarBottomPadding(bottomSafeArea: 0) == 4)
        #expect(MysticLayout.tabBarBottomPadding(bottomSafeArea: 34) == 30)
    }

    @Test("Tab bar height reflects bottom alignment spacing")
    func tabBarHeightAlignment() {
        #expect(MysticLayout.tabBarHeight(bottomSafeArea: 34) == 94)
    }

    @Test("Date helpers honor selected app language with fallback locale")
    func dateHelperLocaleSelection() {
        let fallback = Locale(identifier: "en_US_POSIX")

        let turkish = Date.appLocale(selectedLanguage: "tr", fallback: fallback)
        #expect(turkish.identifier.hasPrefix("tr"))

        let english = Date.appLocale(selectedLanguage: "en", fallback: fallback)
        #expect(english.identifier.hasPrefix("en"))

        let blank = Date.appLocale(selectedLanguage: " ", fallback: fallback)
        #expect(blank.identifier == fallback.identifier)

        let missing = Date.appLocale(selectedLanguage: nil, fallback: fallback)
        #expect(missing.identifier == fallback.identifier)
    }

    @Test("App router language codes normalize safely with fallback")
    func appRouterLanguageNormalization() {
        #expect(AppRouter.resolveLanguageCode("tr") == "tr")
        #expect(AppRouter.resolveLanguageCode("TR_tr") == "tr")
        #expect(AppRouter.resolveLanguageCode("en-US") == "en")
        #expect(AppRouter.resolveLanguageCode("  ") == "en")
        #expect(AppRouter.resolveLanguageCode("de") == "en")
    }

    @Test("Home view initializes")
    func homeViewInitializes() {
        _ = HomeView()
        #expect(true)
    }

    @Test("Dream loading placeholder appears only for initial refresh")
    func dreamInitialLoadingPlaceholderState() {
        #expect(DreamJournalView.shouldShowInitialLoadingState(isRefreshing: true, dreamsCount: 0))
        #expect(!DreamJournalView.shouldShowInitialLoadingState(isRefreshing: false, dreamsCount: 0))
        #expect(!DreamJournalView.shouldShowInitialLoadingState(isRefreshing: true, dreamsCount: 2))
    }

    @Test("Dream refresh notice appears only while refreshing existing entries")
    func dreamRefreshNoticeState() {
        #expect(DreamJournalView.shouldShowRefreshNotice(isRefreshing: true, dreamsCount: 2))
        #expect(!DreamJournalView.shouldShowRefreshNotice(isRefreshing: true, dreamsCount: 0))
        #expect(!DreamJournalView.shouldShowRefreshNotice(isRefreshing: false, dreamsCount: 4))
    }

    @Test("Chat slow-response notice appears only after threshold while loading")
    func chatSlowResponseNoticeState() {
        #expect(ChatView.shouldShowSlowResponseNotice(isLoading: true, didExceedThreshold: true))
        #expect(!ChatView.shouldShowSlowResponseNotice(isLoading: true, didExceedThreshold: false))
        #expect(!ChatView.shouldShowSlowResponseNotice(isLoading: false, didExceedThreshold: true))
    }

    @Test("Natal interpretation retry visibility depends on error and loading state")
    func natalInterpretationRetryVisibility() {
        #expect(NatalChartView.shouldShowInterpretationRetry(errorMessage: "Failed", isLoading: false))
        #expect(!NatalChartView.shouldShowInterpretationRetry(errorMessage: "Failed", isLoading: true))
        #expect(!NatalChartView.shouldShowInterpretationRetry(errorMessage: "  ", isLoading: false))
        #expect(!NatalChartView.shouldShowInterpretationRetry(errorMessage: nil, isLoading: false))
    }

    @Test("Palm errors are mapped to user-facing messages")
    func palmErrorMapping() {
        let offline = PalmReadingView.userFacingErrorMessage(for: URLError(.notConnectedToInternet))
        #expect(offline == String(localized: "palm.error.offline"))

        let timeout = PalmReadingView.userFacingErrorMessage(for: URLError(.timedOut))
        #expect(timeout == String(localized: "palm.error.timeout"))

        let aiRateLimited = PalmReadingView.userFacingErrorMessage(for: AIServiceError.rateLimited)
        #expect(aiRateLimited == String(localized: "ai.error.rate_limited"))
    }

    @Test("Palm retry action visibility requires selected image and idle state")
    func palmRetryActionVisibility() {
        #expect(PalmReadingView.shouldShowRetryAction(hasSelectedImage: true, isAnalyzing: false))
        #expect(!PalmReadingView.shouldShowRetryAction(hasSelectedImage: false, isAnalyzing: false))
        #expect(!PalmReadingView.shouldShowRetryAction(hasSelectedImage: true, isAnalyzing: true))
    }

    @Test("Onboarding view initializes")
    func onboardingViewInitializes() {
        _ = OnboardingView()
        #expect(true)
    }

    @Test("Domain display names are localized and non-empty")
    func localizedDomainDisplayNames() {
        for sign in ZodiacSign.allCases {
            #expect(!sign.localizedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!sign.localizedElement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!sign.localizedModality.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }

        for planet in Planet.allCases {
            #expect(!planet.localizedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }

        for mood in DreamMood.allCases {
            #expect(!mood.localizedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test("Core localization keys exist in both English and Turkish files")
    func coreLocalizationParity() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent() // horoscopeTests
            .deletingLastPathComponent() // project root
        let enURL = projectRoot.appendingPathComponent("horoscope/en.lproj/Localizable.strings")
        let trURL = projectRoot.appendingPathComponent("horoscope/tr.lproj/Localizable.strings")

        let enText = try String(contentsOf: enURL, encoding: .utf8)
        let trText = try String(contentsOf: trURL, encoding: .utf8)

        let pattern = #"^\s*"([^"]+)"\s*="#
        let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])

        func keys(from text: String) -> Set<String> {
            let ns = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
            return Set(matches.compactMap { match in
                guard match.numberOfRanges > 1 else { return nil }
                return ns.substring(with: match.range(at: 1))
            })
        }

        let enKeys = keys(from: enText)
        let trKeys = keys(from: trText)

        let requiredCoreKeys: [String] = [
            "chat.input.placeholder",
            "chat.retry.message",
            "chat.retry.action",
            "chat.retry.hint",
            "chat.loading.reply",
            "chat.loading.slow",
            "quick_actions.title",
            "tab.chat.fab.hint",
            "home.personalized.loading",
            "dream.loading.entries",
            "dream.loading.refresh",
            "dream.retry.action",
            "natal.interpretation.retry",
            "natal.dignity.domicile",
            "natal.house.description.1",
            "natal.pattern.grand_trine.title",
            "natal.orb_format",
            "natal.score_label",
            "settings.section.quick",
            "settings.section.account",
            "settings.edit.location.resolve_failed",
            "settings.section.support",
            "settings.signout.confirm.title",
            "settings.signout.confirm.message",
            "settings.signout.confirm.action",
            "config.error.missing_secret",
            "ai.error.unauthorized",
            "palm.error.generic",
            "palm.analyzing",
            "palm.retry.hint",
            "notifications.error.permission_denied",
            "common.accessibility.selected",
            "common.retry",
            "astro.zodiac.aries",
            "astro.planet.sun",
            "astro.aspect.conjunction",
            "astro.transit_severity.low",
            "transit.description.format",
            "tarot.card.reversed_format",
            "tarot.card.fool.name"
        ]

        for key in requiredCoreKeys {
            #expect(enKeys.contains(key))
            #expect(trKeys.contains(key))
        }
    }
}
