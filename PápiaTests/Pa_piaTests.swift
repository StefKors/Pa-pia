//
//  Pa_piaTests.swift
//  PápiaTests
//
//  Created by Stef Kors on 29/04/2024.
//

import XCTest
@testable import Pápia

@MainActor
final class Pa_piaTests: XCTestCase {
    private let searchHistoryKey = "search-history"

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: searchHistoryKey)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: searchHistoryKey)
    }

    func testAppendSearchHistoryTrimsAndCaps() {
        let state = InterfaceState()

        state.appendSearchHistory("  apple  ", maxCount: 3)
        state.appendSearchHistory("banana", maxCount: 3)
        state.appendSearchHistory("cherry", maxCount: 3)
        state.appendSearchHistory("date", maxCount: 3)

        XCTAssertEqual(state.searchHistory, ["banana", "cherry", "date"])
    }

    func testAppendSearchHistoryMovesExistingToEnd() {
        let state = InterfaceState()

        state.appendSearchHistory("apple")
        state.appendSearchHistory("banana")
        state.appendSearchHistory("apple")

        XCTAssertEqual(state.searchHistory, ["banana", "apple"])
    }

    func testAppendSearchHistoryIgnoresEmptyValues() {
        let state = InterfaceState()

        state.appendSearchHistory("")
        state.appendSearchHistory("   ")

        XCTAssertTrue(state.searchHistory.isEmpty)
    }

    func testSearchHistoryMemoryProfile() {
        let state = InterfaceState()
        measure(metrics: [XCTMemoryMetric()]) {
            state.searchHistory = []
            for index in 0..<1000 {
                state.appendSearchHistory("term-\(index)", maxCount: 50)
            }
            XCTAssertLessThanOrEqual(state.searchHistory.count, 50)
        }
    }

    func testViewModelCreationMemoryProfile() {
        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<200 {
                _ = DataMuseViewModel()
            }
        }
    }
}
