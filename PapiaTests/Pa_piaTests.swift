//
//  Pa_piaTests.swift
//  PapiaTests
//
//  Created by Stef Kors on 29/04/2024.
//

import XCTest
@testable import Papia

@MainActor
final class Pa_piaTests: XCTestCase {

    override func setUpWithError() throws {
        // No longer using UserDefaults for search history
    }

    override func tearDownWithError() throws {
        // No longer using UserDefaults for search history
    }

    func testAppendSearchHistoryIgnoresEmptyValues() async {
        let state = InterfaceState()

        // Empty and whitespace-only strings are rejected synchronously
        // before any SQLite write, so the history should remain unchanged.
        let historyBefore = state.searchHistory
        state.appendSearchHistory("")
        state.appendSearchHistory("   ")

        // Give any (unexpected) async writes a chance to settle.
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(state.searchHistory, historyBefore,
                       "Empty/whitespace queries should not be added to search history")
    }

    func testViewModelCreationMemoryProfile() {
        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<200 {
                _ = DataMuseViewModel()
            }
        }
    }
}
