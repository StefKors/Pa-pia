//
//  ContentView.swift
//  Pápia
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
                    searchText: model.searchText,
                    searchIsFocused: $searchFocused,
                    searchHistoryItems: [],
                    showSettings: $showSettings
                )
            }
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "Find words...")
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
            var newHistory = Set(state.searchHistory)
            newHistory.insert(model.searchText)
            state.searchHistory = Array(newHistory)
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
                searchText: model.searchText,
                searchIsFocused: $searchFocused,
                searchHistoryItems: [],
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

    private var showClearButton: Bool {
        !model.searchText.isEmpty
    }

    private var showCancelButton: Bool {
        showClearButton || searchIsFocused
    }

    private var backgroundColor: Color {
#if os(macOS)
        Color(nsColor: NSColor.windowBackgroundColor)
#else
        Color(uiColor: UIColor.secondarySystemBackground)
#endif
    }

    @Namespace private var namespace

    // iOS search focus
    @FocusState private var searchIsFocused: Bool

    private var iOSContentView: some View {
#if os(iOS)
        NavigationStack(path: $state.navigation) {
            List {
                ForEach(model.filteredSearchResults) { word in
                    NavigationLink(value: word) {
                        WordView(word: word)
                    }
                    .accessibilityLabel("word-list-word-view")
                    .onAppear {
                        loadMoreIfNeeded(for: word)
                    }
                }
                resultsFooterRow
            }
            .contentMargins(.bottom, 60, for: .scrollContent)
            .scrollEdgeEffectStyle(.soft, for: .vertical)
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                ToolbarItem(placement: .title) {
                    VStack {
                        Picker("Search Scope", selection: $model.searchScope) {
                            ForEach(model.globalSearchScopes) { scope in
                                Text(scope.label)
                                    .font(.callout)
                                    .tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .glassEffect()

                        FilterButtonsGroup()
                            .environmentObject(model)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.medium)
                            .foregroundStyle(.tertiary)
                        TextField("Find words...", text: $model.searchText, selection: $model.searchTextSelection)
                            .focused($searchIsFocused)
                            .environmentObject(model)
                            .defaultFocus($searchIsFocused, true)
                            .accessibilityLabel("search-input")
                    }
                    .padding(8)
                    .glassEffectID("search", in: namespace)

                }


                if showClearButton {
                    ToolbarSpacer(placement: .bottomBar)

                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            self.model.searchText = ""
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(Color.secondary)
                                .imageScale(.medium)
                        }
                        .glassEffectID("clear", in: namespace)
                    }
                }
            }
            .navigationDestination(for: DataMuseWord.self, destination: { word in
                WordDetailView(word: word)
            })
            .modifier(
                iOSContentViewAdjustmentsView(
                    searchResultsCount: model.filteredSearchResults.count,
                    searchText: model.searchText,
                    searchIsFocused: $searchIsFocused,
                    searchHistoryItems: state.navigationHistory,
                    showSettings: $showSettings
                )
            )
            .scrollDismissesKeyboard(.immediately)
            .background(backgroundColor)
            .environmentObject(model)
            .overlay(alignment: .bottom) {
                VStack(alignment: .trailing) {
                    ToolbarButtonsGroup()
                        .environmentObject(model)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
        }
        .animation(.snappy(duration: 0.16), value: showClearButton)
#else
        EmptyView()
#endif
    }

    var body: some View {
        VStack {
#if os(macOS)
            macOSContentView
#else
            iOSContentView
#endif
        }
        .environmentObject(state)
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
        }
        .task(id: model.searchText, priority: .userInitiated) {
            if model.searchText.isEmpty {
                self.model.resetPagination()
                self.model.searchResults = []
                return
            }

            self.model.resetPagination()
            let results = await self.model.fetch(
                scope: self.model.searchScope,
                searchText: self.model.searchText,
                maxResults: self.model.resultsLimit
            )
            self.model.searchResults = results
            self.model.updatePaginationState(resultCount: results.count)
        }
        .onChange(of: model.searchScope, initial: true, { oldValue, newValue in
            if model.searchText.isEmpty {
                self.model.resetPagination()
                self.model.searchResults = []
                return
            }
            Task(priority: .userInitiated) {
                self.model.resetPagination()
                let results = await self.model.fetch(
                    scope: newValue,
                    searchText: self.model.searchText,
                    maxResults: self.model.resultsLimit
                )
                self.model.searchResults = results
                self.model.updatePaginationState(resultCount: results.count)
            }
        })
    }

    private var shouldShowResultsFooter: Bool {
        !model.searchText.isEmpty && !model.searchResults.isEmpty
    }

    private func loadMoreIfNeeded(for word: DataMuseWord) {
        guard !model.searchText.isEmpty else { return }
        guard word.id == model.filteredSearchResults.last?.id else { return }

        Task(priority: .userInitiated) {
            let results = await model.loadMore(scope: model.searchScope, searchText: model.searchText)
            if !results.isEmpty {
                self.model.searchResults = results
            }
        }
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
