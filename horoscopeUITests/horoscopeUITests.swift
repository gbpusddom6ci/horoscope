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

    private func launchAuthenticatedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITEST_AUTHENTICATED",
            "-selected_language", "en"
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

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Mystic"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testQuickActionsSheetShowsItems() throws {
        let app = launchAuthenticatedApp()

        let quickButton = app.buttons["quick_actions.button"]
        XCTAssertTrue(quickButton.waitForExistence(timeout: 8))
        quickButton.tap()

        XCTAssertTrue(app.buttons["quick_action.new_chat"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["quick_action.new_dream"].exists)
        XCTAssertTrue(app.buttons["quick_action.open_tarot"].exists)
        XCTAssertTrue(app.buttons["quick_action.open_palm"].exists)
    }

    @MainActor
    func testQuickActionDreamOpensComposer() throws {
        let app = launchAuthenticatedApp()

        let quickButton = app.buttons["quick_actions.button"]
        XCTAssertTrue(quickButton.waitForExistence(timeout: 8))
        quickButton.tap()
        app.buttons["quick_action.new_dream"].tap()

        XCTAssertTrue(app.navigationBars["New Dream"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testChatMoreContextsSheetOpens() throws {
        let app = launchAuthenticatedApp()

        let chatTab = app.buttons["tab.chat"]
        XCTAssertTrue(chatTab.waitForExistence(timeout: 8))
        chatTab.tap()

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
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
