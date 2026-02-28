//
//  horoscopeUITests.swift
//  horoscopeUITests
//
//  Created by malware on 2/25/26.
//

import XCTest

final class horoscopeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    private func launchAuthenticatedApp(language: String = "en") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITEST_AUTHENTICATED",
            "-selected_language", language
        ]
        app.launch()
        return app
    }

    private func revealElementIfNeeded(_ element: XCUIElement, in app: XCUIApplication, maxScrolls: Int = 4) {
        var attempts = 0
        while !element.exists && attempts < maxScrolls {
            app.swipeUp()
            attempts += 1
        }
    }

    private func waitForNonExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Mystic"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testQuickActionsButtonNavigatesToChat() throws {
        let app = launchAuthenticatedApp()

        let quickButton = app.buttons["quick_actions.button"]
        XCTAssertTrue(quickButton.waitForExistence(timeout: 8))
        quickButton.tap()

        // Floating button should navigate to Chat tab
        let composer = app.otherElements["chat.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
    }

    @MainActor
    func testQuickActionDreamOpensComposer() throws {
        let app = launchAuthenticatedApp()

        // Navigate to Dream tab directly
        let dreamTab = app.buttons["tab.dream"]
        XCTAssertTrue(dreamTab.waitForExistence(timeout: 8))
        dreamTab.tap()

        // Use topbar + button to open dream composer
        let topBarCta = app.buttons["dream.new_topbar"]
        XCTAssertTrue(topBarCta.waitForExistence(timeout: 5))
        topBarCta.tap()

        XCTAssertTrue(app.staticTexts["New Dream"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testChatMoreContextsSheetOpens() throws {
        let app = launchAuthenticatedApp()

        // Navigate to Chat via floating button
        let quickButton = app.buttons["quick_actions.button"]
        XCTAssertTrue(quickButton.waitForExistence(timeout: 8))
        quickButton.tap()

        let moreButton = app.buttons["chat.context.more"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 5))
        moreButton.tap()

        XCTAssertTrue(app.staticTexts["More Contexts"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Tarot"].exists)
    }

    @MainActor
    func testHomeGridShowsCompactTiles() throws {
        let app = launchAuthenticatedApp()

        let homeTab = app.buttons["tab.home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 8))
        homeTab.tap()

        let chatTile = app.buttons["home.feature.chat"]
        revealElementIfNeeded(chatTile, in: app)
        XCTAssertTrue(chatTile.waitForExistence(timeout: 3))

        let dreamTile = app.buttons["home.feature.dream"]
        revealElementIfNeeded(dreamTile, in: app)
        XCTAssertTrue(dreamTile.exists)

        let palmTile = app.buttons["home.feature.palm"]
        revealElementIfNeeded(palmTile, in: app)
        XCTAssertTrue(palmTile.exists)

        let tarotTile = app.buttons["home.feature.tarot"]
        revealElementIfNeeded(tarotTile, in: app)
        XCTAssertTrue(tarotTile.exists)
    }

    @MainActor
    func testSelectedTabPersistsAfterRelaunch() throws {
        let app = launchAuthenticatedApp()

        let dreamTab = app.buttons["tab.dream"].firstMatch
        XCTAssertTrue(dreamTab.waitForExistence(timeout: 8))
        dreamTab.tap()
        XCTAssertTrue(app.staticTexts["Dream Journal"].waitForExistence(timeout: 8))

        app.terminate()
        app.launch()

        let relaunchedDreamTab = app.buttons["tab.dream"].firstMatch
        XCTAssertTrue(relaunchedDreamTab.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Dream Journal"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testMainTabBarIsAnchoredNearBottomEdge() throws {
        let app = launchAuthenticatedApp()

        let tabBar = app.otherElements["main.tab_bar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 8))

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 8))

        let gap = window.frame.maxY - tabBar.frame.maxY
        XCTAssertLessThanOrEqual(gap, 4, "Tab bar should sit near the native bottom edge.")
        XCTAssertGreaterThanOrEqual(gap, -1, "Tab bar should not render below the window edge.")
    }

    @MainActor
    func testChatComposerKeyboardAdaptiveChrome() throws {
        let app = launchAuthenticatedApp()

        // Navigate to Chat via floating button
        let quickButton = app.buttons["quick_actions.button"]
        XCTAssertTrue(quickButton.waitForExistence(timeout: 8))
        quickButton.tap()

        let composer = app.otherElements["chat.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))

        let tabBar = app.otherElements["main.tab_bar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        let inputField = app.textFields["chat.input.field"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 5))
        inputField.tap()

        if app.keyboards.element.waitForExistence(timeout: 2) {
            XCTAssertTrue(waitForNonExistence(tabBar, timeout: 2))
            XCTAssertTrue(composer.exists)
        } else {
            XCTAssertTrue(tabBar.exists)
        }
    }

    @MainActor
    func testDreamPrimaryCtaIsReachable() throws {
        let app = launchAuthenticatedApp()

        let dreamTab = app.buttons["tab.dream"].firstMatch
        XCTAssertTrue(dreamTab.waitForExistence(timeout: 8))
        dreamTab.tap()

        XCTAssertTrue(app.staticTexts["Dream Journal"].waitForExistence(timeout: 8))

        let topBarCta = app.buttons["dream.new_topbar"]
        XCTAssertTrue(topBarCta.waitForExistence(timeout: 10))
    }

    @MainActor
    func testSettingsCoreSectionsVisible() throws {
        let app = launchAuthenticatedApp()

        let profileTab = app.buttons["tab.profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 8))
        profileTab.tap()

        XCTAssertTrue(app.staticTexts["Quick Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Account"].exists)
        XCTAssertTrue(app.staticTexts["Support & Privacy"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
