//
//  Pa_piaUITests.swift
//  PápiaUITests
//
//  Created by Stef Kors on 29/04/2024.
//

import XCTest

final class Pa_piaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
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
}
