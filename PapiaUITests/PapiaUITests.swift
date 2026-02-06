//
//  Pa_piaUITests.swift
//  PapiaUITests
//
//  Created by Stef Kors on 29/04/2024.
//

import XCTest

final class PapiaUITests: XCTestCase {

    /// Generous timeout for Xcode Cloud which can be very slow.
    private let ciTimeout: TimeInterval = 10

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    // MARK: - Helpers

    /// Ensure the search field exists and is focused (first responder) so that
    /// toolbar button taps actually insert text.
    @discardableResult
    private func focusSearchField(in app: XCUIApplication) -> XCUIElement {
        let searchInput = app.searchFields.matching(identifier: "search-input").firstMatch
        XCTAssertTrue(searchInput.waitForExistence(timeout: ciTimeout), "Search field should exist")
        // Tap the search field to make sure the keyboard / first responder is active.
        searchInput.tap()
        // Give the keyboard time to appear on slow CI.
        sleep(1)
        return searchInput
    }

    /// Tap a toolbar button once and wait until the search field value changes
    /// (or until timeout). Returns whether the tap was acknowledged.
    @discardableResult
    private func tapAndWaitForChange(
        button: XCUIElement,
        searchField: XCUIElement,
        timeout: TimeInterval = 3
    ) -> Bool {
        let valueBefore = searchField.value as? String ?? ""
        button.tap()

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let current = searchField.value as? String ?? ""
            if current != valueBefore { return true }
            usleep(100_000) // 100 ms
        }
        return false
    }

    /// Tap a button `count` times, verifying after each tap that the search
    /// field value grew. Retries each tap up to 3 times if the value didn't
    /// change (handles slow Xcode Cloud runners).
    private func tapRepeatedly(
        _ button: XCUIElement,
        count: Int,
        searchField: XCUIElement
    ) {
        for i in 0..<count {
            var success = false
            for attempt in 0..<3 {
                if tapAndWaitForChange(button: button, searchField: searchField) {
                    success = true
                    break
                }
                // Retry: re-focus the search field and try again.
                searchField.tap()
                usleep(300_000) // 300 ms
            }
            if !success {
                XCTFail("Toolbar button tap \(i + 1) of \(count) did not register after 3 attempts")
                return
            }
        }
    }

    /// Poll the search field until its value equals `expected` or the timeout
    /// elapses. Uses a generous default for slow CI.
    private func assertSearchFieldEquals(
        _ searchInput: XCUIElement,
        expected: String,
        timeout: TimeInterval = 5,
        message: String
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (searchInput.value as? String) == expected { break }
            usleep(150_000) // 150 ms
        }
        XCTAssertEqual(searchInput.value as? String, expected, message)
    }

    /// Poll the search field until its value does NOT equal `unexpected`.
    private func assertSearchFieldNotEquals(
        _ searchInput: XCUIElement,
        unexpected: String,
        timeout: TimeInterval = 5,
        message: String
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (searchInput.value as? String) != unexpected { break }
            usleep(150_000)
        }
        XCTAssertNotEqual(searchInput.value as? String, unexpected, message)
    }

    // MARK: - Tests

    func testSearchAndNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for the UI to be fully loaded
        let searchInput = focusSearchField(in: app)

        let button = app.buttons.matching(identifier: "? any letter").firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: ciTimeout), "Wildcard button should exist")

        // Re-focus search field right before tapping toolbar buttons
        searchInput.tap()
        sleep(1)

        tapRepeatedly(button, count: 5, searchField: searchInput)

        assertSearchFieldEquals(searchInput, expected: "?????",
                                message: "Expected search input to contain \"?????\"")

        // navigate to word detail
        let firstResult = app.cells.matching(identifier: "word-list-word-view").firstMatch
        XCTAssertTrue(firstResult.waitForExistence(timeout: 15), "Expected search results to appear")
        firstResult.tap()

        // navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: ciTimeout), "Back button should exist")
        backButton.tap()

        // clear input
        let clearButton = app.buttons["Clear text"].firstMatch
        XCTAssertTrue(clearButton.waitForExistence(timeout: ciTimeout), "Clear button should exist")
        clearButton.tap()
        assertSearchFieldNotEquals(searchInput, unexpected: "?????",
                                   message: "Expected search input to be cleared")
    }

    func testSearchAndNavigationPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure() {
                let app = XCUIApplication()
                app.launch()

                let searchInput = focusSearchField(in: app)

                let button = app.buttons.matching(identifier: "? any letter").firstMatch
                XCTAssertTrue(button.waitForExistence(timeout: ciTimeout), "Wildcard button should exist")

                searchInput.tap()
                sleep(1)

                tapRepeatedly(button, count: 5, searchField: searchInput)

                assertSearchFieldEquals(searchInput, expected: "?????",
                                        message: "Expected search input to contain \"?????\"")

                // navigate to word detail
                let firstResult = app.cells.matching(identifier: "word-list-word-view").firstMatch
                XCTAssertTrue(firstResult.waitForExistence(timeout: 15), "Expected search results to appear")
                firstResult.tap()

                // navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                XCTAssertTrue(backButton.waitForExistence(timeout: ciTimeout), "Back button should exist")
                backButton.tap()

                // clear input
                let clearButton = app.buttons["Clear text"].firstMatch
                XCTAssertTrue(clearButton.waitForExistence(timeout: ciTimeout), "Clear button should exist")
                clearButton.tap()
                assertSearchFieldNotEquals(searchInput, unexpected: "?????",
                                           message: "Expected search input to be cleared")
            }
        }
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    /// Test that pressing a toolbar button after clearing the search input does not crash.
    /// Regression test for stale TextSelection indices causing index-out-of-bounds.
    func testToolbarButtonAfterClearDoesNotCrash() throws {
        let app = XCUIApplication()
        app.launch()

        let searchInput = focusSearchField(in: app)

        let questionMarkButton = app.buttons.matching(identifier: "? any letter").firstMatch
        XCTAssertTrue(questionMarkButton.waitForExistence(timeout: ciTimeout), "Wildcard button should exist")

        searchInput.tap()
        sleep(1)

        tapRepeatedly(questionMarkButton, count: 3, searchField: searchInput)

        assertSearchFieldEquals(searchInput, expected: "???",
                                message: "Expected search input to contain \"???\"")

        // Clear the input
        let clearButton = app.buttons["Clear text"].firstMatch
        XCTAssertTrue(clearButton.waitForExistence(timeout: ciTimeout), "Clear button should exist")
        clearButton.tap()
        assertSearchFieldNotEquals(searchInput, unexpected: "???",
                                   message: "Expected search input to be cleared")

        // Re-focus after clearing — the keyboard may have dismissed.
        searchInput.tap()
        sleep(1)

        // Now tap a toolbar button again — this should NOT crash.
        let asteriskButton = app.buttons.matching(identifier: "* many").firstMatch
        XCTAssertTrue(asteriskButton.waitForExistence(timeout: ciTimeout), "Asterisk button should exist")

        tapAndWaitForChange(button: asteriskButton, searchField: searchInput)
        assertSearchFieldEquals(searchInput, expected: "*",
                                message: "Expected search input to contain \"*\" after pressing toolbar button")

        tapAndWaitForChange(button: questionMarkButton, searchField: searchInput)
        assertSearchFieldEquals(searchInput, expected: "*?",
                                message: "Expected search input to contain \"*?\"")
    }
}
