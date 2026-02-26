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
        #expect(session.lastMessagePreview == "Henüz mesaj yok")

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

}
