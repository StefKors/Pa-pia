//
//  ContentView.swift
//  Papia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI
import SwiftData
import Get

// TODO: add search progress @Environment(\.isSearching) private var isSearching
// TODO: add indicator if the word exists in the wordle dictionary
// TODO: add buttons to insert wild card character for complex searches
// TODO: add indicator if the word exists in the scrabble dictionary
// TODO: show word also in Dutch and Greek
// TODO: lazy load the Word Detail List Sections so they are loaded as you scroll, most are out of view anyways
// TODO: add feature to favourite words
struct ContentView: View {
    @StateObject private var model = DataMuseViewModel()
    @StateObject private var state = InterfaceState()
    @State private var showSettings: Bool = false

    // macOS Search Focus
    @FocusState private var searchFocused: Bool

    /// For macOS search suggestions
    private var filteredSearchHistory: [String] {
        if model.searchText.isEmpty {
            return state.searchHistory
        }

        return state.searchHistory.filter { $0.contains(model.searchText) }
    }

    private var macOSContentView: some View {
#if os(macOS)
        NavigationSplitView {
            List(selection: $state.selection) {
                ForEach(model.filteredSearchResults) { word in
                    WordView(word: word)
                        .tag(word)
                }
                resultsFooterRow
            }
            .onChange(of: state.selection) { oldValue, newValue in
                if let newValue {
                    state.navigation = [newValue]
                }
            }
        } detail: {
            if let word = state.navigation.last {
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        ForEach(Array(state.navigation.enumerated()), id: \.offset) { index, nav in
                            if index != 0 {
                                Divider()
                                    .frame(height: 12)
                            }
                            Button {
                                if let index = state.navigation.firstIndex(of: nav) {
                                    state.navigation = Array(state.navigation[...index])
                                }
                            } label: {
                                Text(nav.word.capitalized)
                            }
                            .buttonStyle(.accessoryBar)
                            .id(nav)
                        }
                        Spacer()
                    }
                    .padding(8)

                    Divider()

                    WordDetailView(word: word)
                        .id(state.selection)
                }
            } else {
                SearchContentUnavailableView(
                    searchResultsCount: model.filteredSearchResults.count,
                    totalResultsCount: model.searchResults.count,
                    searchText: model.searchText,
                    searchIsFocused: $searchFocused,
                    searchHistoryItems: [],
                    hasActiveFilters: !model.activeFilters.isEmpty,
                    onClearFilters: {
                        model.clearFilters()
                    },
                    showSettings: $showSettings
                )
            }
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "Find words...")
        .searchSelection($model.searchTextSelection)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                FilterButtonsGroup()
                    .environmentObject(model)
            }
        }
        .searchSuggestions {
            ForEach(filteredSearchHistory, id: \.self) { suggestion in
                HighlightedText(
                    text: suggestion,
                    highlightedText: model.searchText,
                    shapeStyle: .tint.opacity(0.4)
                )
                .searchCompletion(suggestion)
            }
        }
        .onSubmit(of: .search, {
            state.appendSearchHistory(model.searchText)
        })
        .searchFocused($searchFocused)
        .task {
            searchFocused = true
        }
        .onChange(of: model.searchText) { oldValue, newValue in
            if newValue.isEmpty {
                state.navigation = []
            }
        }
        .environmentObject(state)
        .modifier(
            iOSContentViewAdjustmentsView(
                searchResultsCount: model.filteredSearchResults.count,
                totalResultsCount: model.searchResults.count,
                searchText: model.searchText,
                searchIsFocused: $searchFocused,
                searchHistoryItems: [],
                hasActiveFilters: !model.activeFilters.isEmpty,
                onClearFilters: {
                    model.clearFilters()
                },
                showSettings: $showSettings
            )
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .toolbar {
#if os(macOS)
                        ToolbarItem {
                            Button("Done") { showSettings = false }
                        }
#else
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                        }
#endif
                    }
            }
            .frame(minWidth: 420, minHeight: 300)
        }
#else
        EmptyView()
#endif
    }

    var body: some View {
#if os(macOS)
        VStack {
            macOSContentView
        }
        .environmentObject(state)
        .environmentObject(model)
        .task(id: model.searchQuery, priority: .userInitiated) {
            if model.searchText.isEmpty {
                self.model.searchResults = []
                return
            }

            // Debounce: wait 120ms before firing the request.
            // If the user types another character the task is cancelled
            // automatically by SwiftUI before the sleep finishes.
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }

            self.model.searchResults = await self.model.fetch(
                scope: self.model.searchScope,
                searchText: self.model.searchText
            )
        }
#else
        // iOS uses UIKit navigation core (see Papia/UIKit/).
        // This path should never be reached since Pa_piaApp routes
        // iOS to iOSRootView() instead.
        EmptyView()
#endif
    }

    private var shouldShowResultsFooter: Bool {
        !model.searchText.isEmpty && !model.searchResults.isEmpty
    }

    @ViewBuilder
    private var resultsFooterRow: some View {
        if shouldShowResultsFooter {
            ResultsFooterView(
                resultsCount: model.searchResults.count,
                showsMax: model.isAtMaxResultsLimit
            )
        }
    }
}

#Preview {
    ContentView()
}
