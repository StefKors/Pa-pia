//
//  Pa_piaUITests.swift
//  PápiaUITests
//
//  Created by Stef Kors on 29/04/2024.
//

import XCTest

final class PapiaUITests: XCTestCase {

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
        let element = app.buttons["? any"].firstMatch
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        element.tap()

        // confirm button result
        XCTAssertEqual(app.textFields["search-input"].firstMatch.value as? String, "?????", "Expected search input to contain \"?????\"")

        // navigate to word detail
        app.buttons.matching(identifier: "word-list-word-view").firstMatch.tap()

        // navigate back
        app.staticTexts["navigation-back-button"].firstMatch.tap()

        // clear input
        let element2 = app.buttons["xmark.circle.fill"].firstMatch
        element2.tap()
        XCTAssertEqual(app.textFields["search-input"].firstMatch.value as? String, "", "Expected search input to be empty")


    }

    func testSearchAndNavigationPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure() {
                let app = XCUIApplication()
                app.activate()
                let element = app.buttons["? any"].firstMatch
                element.tap()
                element.tap()
                element.tap()
                element.tap()
                element.tap()

                // confirm button result
                XCTAssertEqual(app.textFields["search-input"].firstMatch.value as? String, "?????", "Expected search input to contain \"?????\"")

                // navigate to word detail
                app.buttons.matching(identifier: "word-list-word-view").firstMatch.tap()

                // navigate back
                app.staticTexts["navigation-back-button"].firstMatch.tap()

                // clear input
                let element2 = app.buttons["xmark.circle.fill"].firstMatch
                element2.tap()
                XCTAssertEqual(app.textFields["search-input"].firstMatch.value as? String, "", "Expected search input to be empty")
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

        // Add some characters using the toolbar buttons
        let questionMarkButton = app.buttons["? any"].firstMatch
        questionMarkButton.tap()
        questionMarkButton.tap()
        questionMarkButton.tap()

        // Verify text was added
        let searchInput = app.textFields["search-input"].firstMatch
        XCTAssertEqual(searchInput.value as? String, "???", "Expected search input to contain \"???\"")

        // Clear the input using the clear button
        let clearButton = app.buttons["xmark"].firstMatch
        XCTAssertTrue(clearButton.waitForExistence(timeout: 2), "Clear button should exist")
        clearButton.tap()

        // Verify input is cleared
        XCTAssertEqual(searchInput.value as? String, "", "Expected search input to be empty after clear")

        // Now tap a toolbar button again - this should NOT crash
        // The bug was that stale TextSelection indices from the previous text would cause a crash
        let asteriskButton = app.buttons["* many"].firstMatch
        asteriskButton.tap()

        // Verify the character was added successfully
        XCTAssertEqual(searchInput.value as? String, "*", "Expected search input to contain \"*\" after pressing toolbar button")

        // Tap another button to make sure it continues to work
        questionMarkButton.tap()
        XCTAssertEqual(searchInput.value as? String, "*?", "Expected search input to contain \"*?\"")
    }
}
