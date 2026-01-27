//
//  Pa_piaUITests.swift
//  PapiaUITests
//
//  Created by Stef Kors on 29/04/2024.
//

import XCTest

final class PapiaUITests: XCTestCase {

    private func searchInput(in app: XCUIApplication) -> XCUIElement {
        let field = app.textFields.matching(identifier: "search-input").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2), "Search input should exist")
        return field
    }

    private func addQuestionMarks(app: XCUIApplication, searchInput: XCUIElement, count: Int) {
#if os(macOS)
        searchInput.click()
        searchInput.typeText(String(repeating: "?", count: count))
#else
        let button = app.buttons.matching(identifier: "? any letter").firstMatch
        for _ in 0..<count {
            button.tap()
        }
#endif
    }

    private func addAsterisk(app: XCUIApplication, searchInput: XCUIElement) {
#if os(macOS)
        searchInput.click()
        searchInput.typeText("*")
#else
        app.buttons.matching(identifier: "* many").firstMatch.tap()
#endif
    }

    private func clearSearchInput(app: XCUIApplication, searchInput: XCUIElement) {
#if os(macOS)
        searchInput.click()
        searchInput.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
#else
        let clearButton = app.buttons.matching(identifier: "xmark").firstMatch
        XCTAssertTrue(clearButton.waitForExistence(timeout: 2), "Clear button should exist")
        clearButton.tap()
#endif
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSearchAndNavigation() throws {
        let app = XCUIApplication()
        app.activate()
        let searchInput = searchInput(in: app)
        addQuestionMarks(app: app, searchInput: searchInput, count: 5)

        // confirm button result
        XCTAssertEqual(searchInput.value as? String, "?????", "Expected search input to contain \"?????\"")

        // navigate to word detail
        app.buttons.matching(identifier: "word-list-word-view").firstMatch.tap()

        // navigate back
        app.staticTexts.matching(identifier: "navigation-back-button").firstMatch.tap()

        // clear input
        clearSearchInput(app: app, searchInput: searchInput)
        XCTAssertEqual(searchInput.value as? String, "", "Expected search input to be empty")


    }

    func testSearchAndNavigationPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure() {
                let app = XCUIApplication()
                app.activate()
                let searchInput = searchInput(in: app)
                addQuestionMarks(app: app, searchInput: searchInput, count: 5)

                // confirm button result
                XCTAssertEqual(searchInput.value as? String, "?????", "Expected search input to contain \"?????\"")

                // navigate to word detail
                app.buttons.matching(identifier: "word-list-word-view").firstMatch.tap()

                // navigate back
                app.staticTexts.matching(identifier: "navigation-back-button").firstMatch.tap()

                // clear input
                clearSearchInput(app: app, searchInput: searchInput)
                XCTAssertEqual(searchInput.value as? String, "", "Expected search input to be empty")
            }
        }
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    /// Test that pressing a toolbar button after clearing the search input does not crash
    /// This tests for a bug where stale TextSelection indices would cause an index out of bounds crash
    func testToolbarButtonAfterClearDoesNotCrash() throws {
        let app = XCUIApplication()
        app.launch()

        let searchInput = searchInput(in: app)

        // Add some characters using the toolbar buttons
        addQuestionMarks(app: app, searchInput: searchInput, count: 3)

        // Verify text was added
        XCTAssertEqual(searchInput.value as? String, "???", "Expected search input to contain \"???\"")

        // Clear the input using the clear button
        clearSearchInput(app: app, searchInput: searchInput)

        // Verify input is cleared
        XCTAssertEqual(searchInput.value as? String, "", "Expected search input to be empty after clear")

        // Now tap a toolbar button again - this should NOT crash
        // The bug was that stale TextSelection indices from the previous text would cause a crash
        addAsterisk(app: app, searchInput: searchInput)

        // Verify the character was added successfully
        XCTAssertEqual(searchInput.value as? String, "*", "Expected search input to contain \"*\" after pressing toolbar button")

        // Tap another button to make sure it continues to work
        addQuestionMarks(app: app, searchInput: searchInput, count: 1)
        XCTAssertEqual(searchInput.value as? String, "*?", "Expected search input to contain \"*?\"")
    }
}
