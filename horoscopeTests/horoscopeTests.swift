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
            ChatMessage(role: .assistant, content: "Hoş geldin")
        )
        #expect(session.lastMessagePreview == "Hoş geldin")
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
            "quick_actions.title",
            "settings.section.quick",
            "settings.section.account",
            "settings.section.support",
            "config.error.missing_secret",
            "ai.error.unauthorized",
            "notifications.error.permission_denied",
            "common.accessibility.selected",
            "astro.zodiac.aries",
            "astro.planet.sun",
            "astro.aspect.conjunction",
            "astro.transit_severity.low",
            "transit.description.format"
        ]

        for key in requiredCoreKeys {
            #expect(enKeys.contains(key))
            #expect(trKeys.contains(key))
        }
    }
}
