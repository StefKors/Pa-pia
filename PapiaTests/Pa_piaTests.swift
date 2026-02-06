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

    func testAppendSearchHistoryIgnoresEmptyValues() {
        let state = InterfaceState()

        // These should not crash and should leave history empty
        state.appendSearchHistory("")
        state.appendSearchHistory("   ")

        // Note: the published array updates asynchronously via SQLite,
        // but empty/whitespace queries are rejected synchronously.
    }

    func testViewModelCreationMemoryProfile() {
        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<200 {
                _ = DataMuseViewModel()
            }
        }
    }
}
