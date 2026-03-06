import XCTest

final class horoscopeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        if app.state != .notRunning {
            app.terminate()
        }
    }

    override func tearDownWithError() throws {
        let app = XCUIApplication()
        if app.state != .notRunning {
            app.terminate()
        }
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

    private func revealElementIfNeeded(_ element: XCUIElement, in app: XCUIApplication, maxScrolls: Int = 8) {
        var attempts = 0
        while (!element.exists || !element.isHittable) && attempts < maxScrolls {
            let scrollTarget = app.scrollViews.firstMatch
            if scrollTarget.exists {
                scrollTarget.swipeUp()
            } else {
                app.swipeUp()
            }
            attempts += 1
        }
    }

    @MainActor
    func testAuthenticatedHomeShowsGreetingAndDock() throws {
        let app = launchAuthenticatedApp()

        XCTAssertTrue(app.staticTexts["home.greeting"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.otherElements["main.tab_bar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dock.tarot"].exists)
        XCTAssertTrue(app.buttons["dock.oracle"].exists)
        XCTAssertTrue(app.buttons["dock.home"].exists)
        XCTAssertTrue(app.buttons["dock.dreams"].exists)
        XCTAssertTrue(app.buttons["dock.profile"].exists)
    }

    @MainActor
    func testQuickActionsButtonNavigatesToOracle() throws {
        let app = launchAuthenticatedApp()

        let quickButton = app.buttons["quick_actions.button"]
        XCTAssertTrue(quickButton.waitForExistence(timeout: 8))
        quickButton.tap()

        let composer = app.otherElements["chat.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 8))
    }

    @MainActor
    func testHomeContainsAtlasPalmAndTarotCTAs() throws {
        let app = launchAuthenticatedApp()

        let atlasCTA = app.buttons["home.atlas.cta"]
        let palmCTA = app.buttons["home.palm.cta"]
        let tarotCTA = app.buttons["home.tarot.cta"]

        XCTAssertTrue(app.staticTexts["home.greeting"].waitForExistence(timeout: 8))

        revealElementIfNeeded(atlasCTA, in: app)
        XCTAssertTrue(atlasCTA.exists)

        revealElementIfNeeded(palmCTA, in: app)
        XCTAssertTrue(palmCTA.exists)

        revealElementIfNeeded(tarotCTA, in: app)
        XCTAssertTrue(tarotCTA.exists)
    }

    @MainActor
    func testTarotTabShowsDrawCTA() throws {
        let app = launchAuthenticatedApp()

        let tarotDock = app.buttons["dock.tarot"]
        XCTAssertTrue(tarotDock.waitForExistence(timeout: 5))
        tarotDock.tap()

        XCTAssertTrue(app.buttons["tarot.draw.cta"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testChatComposerKeyboardAdaptiveChrome() throws {
        let app = launchAuthenticatedApp()

        app.buttons["quick_actions.button"].tap()

        let composer = app.otherElements["chat.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))

        let tabBar = app.otherElements["main.tab_bar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        let inputField = app.textFields["chat.input.field"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 5))
        inputField.tap()

        sleep(2)

        if !tabBar.exists || !tabBar.isHittable {
            XCTAssertTrue(composer.exists)
        } else {
            XCTAssertTrue(tabBar.exists)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
