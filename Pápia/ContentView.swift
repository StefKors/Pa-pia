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
                    searchIsFocused: $searchIsFocused,
                    searchHistoryItems: []
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
                searchHistoryItems: []
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
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                        }
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
            .overlay(alignment: .bottom) {
                VStack(alignment: .trailing) {
                    ToolbarButtonsGroup()
                        .environmentObject(model)

                    HStack {
                        GlassEffectContainer {
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
                            //                    .padding(.horizontal, 6)

                            .padding()
                        }
                        .glassEffect(.regular, in: .capsule(style: .continuous))

                        if showClearButton {
                            GlassEffectContainer {
                                Button {
                                    self.model.searchText = ""
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color.secondary)
                                        .imageScale(.medium)
                                        .padding()
                                }
                                .layoutPriority(1)
                                .transition(.scale(scale: 0.7).combined(with: .opacity))
                            }
                            .glassEffect(.regular, in: .capsule(style: .continuous))

                        }
                    }
                }
                .padding(.horizontal)
            }
//            .searchable(text: $model.searchText, placement: .navigationBarDrawer)
//            .searchToolbarBehavior(.automatic)
//            Button {
//                showSettings = true
//            } label: {
//                Image(systemName: "gearshape")
//            }
//            .accessibilityLabel("open-settings")

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
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
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
