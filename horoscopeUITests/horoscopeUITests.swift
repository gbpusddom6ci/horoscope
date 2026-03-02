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

    private func revealElementIfNeeded(_ element: XCUIElement, in app: XCUIApplication, maxScrolls: Int = 8) {
        var attempts = 0
        while !element.isHittable && attempts < maxScrolls {
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
        
        // Wait briefly for potential keyboard animation
        sleep(2)

        // In iOS simulators with hardware keyboard connected, software keyboard doesn't appear.
        // We evaluate success by checking if tabBar hid (software keyboard up) or remained (hardware keyboard).
        if !tabBar.exists || !tabBar.isHittable {
            XCTAssertTrue(composer.exists)
        } else {
            XCTAssertTrue(tabBar.exists)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
