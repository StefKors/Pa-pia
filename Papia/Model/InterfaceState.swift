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

    /// Search history backed by SQLite (loaded async on init).
    @Published var searchHistory: [String] = []

    @CodableAppStorage("navigation-history") var navigationHistory: [DataMuseWord] = []

    @Published var navigation: [DataMuseWord] = [] {
        didSet {
            if let latest = navigation.last {
                appendToHistory(latest)
            }
        }
    }

    init() {
        // Load search history from SQLite on startup
        Task { @MainActor in
            self.searchHistory = await WordListDatabase.shared.fetchSearchHistory()
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

    /// Add query to search history (writes to SQLite and refreshes the published array).
    func appendSearchHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task { @MainActor in
            await WordListDatabase.shared.addSearchHistoryEntry(trimmed)
            self.searchHistory = await WordListDatabase.shared.fetchSearchHistory()
        }
    }
}
