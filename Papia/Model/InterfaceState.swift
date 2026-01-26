//
//  InterfaceState.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//

import SwiftUI

class InterfaceState: ObservableObject {
    // Nothing selected by default.
    @Published var selection: DataMuseWord?
    @CodableAppStorage("search-history") var searchHistory: [String] = []
    @CodableAppStorage("navigation-history") var navigationHistory: [DataMuseWord] = []

    @Published var navigation: [DataMuseWord] = [] {
        didSet {
            if let latest = navigation.last {
                appendToHistory(latest)
            }
        }
    }
    /// Add word to history
    /// Limit history to 15
    /// If word is already in history move to end
    /// remove duplicates
    func appendToHistory(_ word: DataMuseWord) {
        navigationHistory = Array(Set(navigationHistory))
        if let i = navigationHistory.firstIndex(of: word) {
            navigationHistory.remove(at: i)
        }
        navigationHistory.append(word)
        if navigationHistory.count > 15 {
            navigationHistory.remove(at: 0)
        }
    }

    /// Add query to search history with a fixed cap.
    func appendSearchHistory(_ query: String, maxCount: Int = 50) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existingIndex = searchHistory.firstIndex(of: trimmed) {
            searchHistory.remove(at: existingIndex)
        }
        searchHistory.append(trimmed)

        if searchHistory.count > maxCount {
            searchHistory.removeFirst(searchHistory.count - maxCount)
        }
    }
}
