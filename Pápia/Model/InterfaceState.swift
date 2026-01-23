//
//  InterfaceState.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//

import SwiftUI

class InterfaceState: ObservableObject {
    // Nothing selected by default.
    @Published var selection: DataMuseWord?
    @CodableAppStorage("search-history") var searchHistory: [String] = []
    @Published private(set) var searchHistoryIndex: Int? = nil
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

    var canGoBackInSearchHistory: Bool {
        if searchHistory.isEmpty {
            return false
        }
        guard let index = searchHistoryIndex else {
            return true
        }
        return index > 0
    }

    var canGoForwardInSearchHistory: Bool {
        guard let index = searchHistoryIndex else {
            return false
        }
        return index + 1 < searchHistory.count
    }

    func recordSearchText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        var history = searchHistory
        if let index = searchHistoryIndex, index + 1 < history.count {
            history.removeSubrange((index + 1)..<history.count)
        }

        if let existingIndex = history.firstIndex(of: trimmed) {
            history.remove(at: existingIndex)
        }

        history.append(trimmed)
        searchHistory = history
        searchHistoryIndex = history.count - 1
    }

    func goBackInSearchHistory() -> String? {
        guard !searchHistory.isEmpty else {
            return nil
        }

        if let index = searchHistoryIndex {
            guard index > 0 else {
                return nil
            }
            let newIndex = index - 1
            searchHistoryIndex = newIndex
            return searchHistory[newIndex]
        }

        let lastIndex = searchHistory.count - 1
        searchHistoryIndex = lastIndex
        return searchHistory[lastIndex]
    }

    func goForwardInSearchHistory() -> String? {
        guard let index = searchHistoryIndex else {
            return nil
        }

        let newIndex = index + 1
        guard newIndex < searchHistory.count else {
            return nil
        }
        searchHistoryIndex = newIndex
        return searchHistory[newIndex]
    }
}
