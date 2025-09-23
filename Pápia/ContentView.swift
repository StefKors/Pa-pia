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

    // macOS Search Focus
    @FocusState private var searchFocused: Bool

    /// For macOS search suggestions
    private var filteredSearchHistory: [String] {
        if model.searchText.isEmpty {
            return state.searchHistory.map { $0.word }
        }

        return state.searchHistory.filter { $0.word.contains(model.searchText) }.map { $0.word }
    }

    private var macOSContentView: some View {
#if os(macOS)
        NavigationSplitView {
            List(model.searchResults, selection: $state.selection) { word in
                WordView(word: word)
                    .tag(word)
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
                    searchResultsCount: model.searchResults.count,
                    searchText: model.searchText,
                    searchIsFocused: $searchIsFocused
                )
            }
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "Find words...")
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
                searchResultsCount: model.searchResults.count,
                searchText: model.searchText,
                searchIsFocused: $searchIsFocused,
                searchHistoryItems: state.searchHistory
            )
        )
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

    // iOS search focus
    @FocusState private var searchIsFocused: Bool

    private var iOSContentView: some View {
#if os(iOS)
        NavigationStack(path: $state.navigation) {
            VStack(spacing: 0) {
                List {
                    ForEach(model.searchResults) { word in
                        NavigationLink(value: word) {
                            WordView(word: word)
                        }
                        .accessibilityLabel("word-list-word-view")
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .navigationDestination(for: DataMuseWord.self, destination: { word in
                    WordDetailView(word: word)
                })

                .contentMargins(.vertical, 140, for: .scrollContent)
                .modifier(
                    iOSContentViewAdjustmentsView(
                        searchResultsCount: model.searchResults.count,
                        searchText: model.searchText,
                        searchIsFocused: $searchIsFocused,
                        searchHistoryItems: state.navigationHistory
                    )
                )
                .modifier(ScrollEdgeEffectModifier())
            }
            .scrollDismissesKeyboard(.immediately)
            .background(backgroundColor)
            .overlay(alignment: .top) {
                VStack {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .imageScale(.medium)
                                .foregroundStyle(.tertiary)

                            if #available(iOS 17.0, *) {
                                TextField("Find words...", text: $model.searchText)
                                    .focused($searchIsFocused)
                                    .environmentObject(model)
                                    .defaultFocus($searchIsFocused, true)
                                    .accessibilityLabel("search-input")
                            } else {
                                TextField("Find words...", text: $model.searchText)
                                    .focused($searchIsFocused)
                                    .environmentObject(model)
                                    .accessibilityLabel("search-input")
                            }
                        }
                        .padding(6)
                        .modifier(GlassEffectModifier())
                        .overlay(alignment: .trailing, content: {
                            if showClearButton {
                                Button {
                                    self.model.searchText = ""
                                    //                                    withAnimation(.smooth(duration: 0.3)) {
                                    //                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.secondary)
                                        .padding(6)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .layoutPriority(1)
                                .transition(.scale(scale: 0.7).combined(with: .opacity))
                            }
                        })
                        .onAppear {
                            searchIsFocused = true
                        }
                        .task {
                            searchIsFocused = true
                        }

                        if showCancelButton {
                            Text(searchIsFocused ? "Cancel" : "Clear")
                                .onTapGesture {
                                    if searchIsFocused {
                                        withAnimation(.smooth(duration: 0.3)) {
                                            searchIsFocused = false
                                        }
                                    } else {
                                        withAnimation(.smooth(duration: 0.3)) {
                                            self.model.searchText = ""
                                        }
                                    }
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .foregroundStyle(.tint)
                                .animation(.smooth(duration: 0.3), value: searchIsFocused)
                        }
                    }
                    .font(.body)
                    .animation(.smooth(duration: 0.3), value: showClearButton)
                    .animation(.smooth(duration: 0.3), value: showCancelButton)

                    ToolbarButtonsGroup()

                    if !model.searchResults.isEmpty {
                        if #available(iOS 26.0, *), #available(macOS 26.0, *) {
                            // Content in bottom overlay
                            EmptyView()
                        } else {
                            Picker("Search Scope", selection: $model.searchScope) {
                                ForEach(model.globalSearchScopes) { scope in
                                    Text(scope.label)
                                        .tag(scope)
                                }
                            }.pickerStyle(.segmented)
                        }
                    }
                }
                .scenePadding(.horizontal)
                .scenePadding(.vertical)
            }
            .overlay(alignment: .bottom) {
                if !model.searchResults.isEmpty {
                    if #available(iOS 26.0, *), #available(macOS 26.0, *) {
                        Picker("Search Scope", selection: $model.searchScope) {
                            ForEach(model.globalSearchScopes) { scope in
                                Text(scope.label)
                                    .tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .glassEffect()
                        .scenePadding()
                    }
                }
            }
            .environmentObject(model)
        }
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
        .task(id: model.searchText) {
            if model.searchText.isEmpty {
                self.model.searchResults = []
                return
            }

            self.model.searchResults = await self.model.fetch(scope: self.model.searchScope, searchText: self.model.searchText)
        }
        .task(id: model.searchScope) {
            if model.searchText.isEmpty {
                self.model.searchResults = []
                return
            }
            self.model.searchResults = await self.model.fetch(scope: self.model.searchScope, searchText: self.model.searchText)
        }
    }
}

#Preview {
    ContentView()
}
