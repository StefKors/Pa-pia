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
    @State private var randomScrabbleWord: String?
    @State private var randomScrabbleDefinition: DataMuseDefinition?
    @State private var isRandomScrabbleLoading: Bool = false

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
                bananagramRow
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
                bananagramRow
                ForEach(model.filteredSearchResults) { word in
                    NavigationLink(value: word) {
                        WordView(word: word)
                    }
                    .accessibilityLabel("word-list-word-view")
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
                    totalResultsCount: model.searchResults.count,
                    searchText: model.searchText,
                    searchIsFocused: $searchIsFocused,
                    searchHistoryItems: state.navigationHistory,
                    hasActiveFilters: !model.activeFilters.isEmpty,
                    onClearFilters: {
                        model.clearFilters()
                    },
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
                self.model.searchResults = []
                return
            }

            self.model.searchResults = await self.model.fetch(
                scope: self.model.searchScope,
                searchText: self.model.searchText
            )
        }
        .onChange(of: model.searchScope, initial: true, { oldValue, newValue in
            if model.searchText.isEmpty {
                self.model.searchResults = []
                return
            }
            Task(priority: .userInitiated) {
                self.model.searchResults = await self.model.fetch(
                    scope: newValue,
                    searchText: self.model.searchText
                )
            }
        })
    }

    private var bananagramRow: some View {
        BananagramShowcaseCard(
            word: randomScrabbleWord,
            definition: randomScrabbleDefinition,
            isLoading: isRandomScrabbleLoading,
            onDraw: {
                Task { await drawRandomScrabbleWord() }
            }
        )
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @MainActor
    private func drawRandomScrabbleWord() async {
        guard !isRandomScrabbleLoading else { return }

        isRandomScrabbleLoading = true
        randomScrabbleDefinition = nil

        do {
            try await WordListDatabase.shared.initialize()
        } catch {
            isRandomScrabbleLoading = false
            return
        }

        guard let word = await WordListDatabase.shared.randomScrabbleWord() else {
            isRandomScrabbleLoading = false
            return
        }

        randomScrabbleWord = word
        randomScrabbleDefinition = await model.definition(for: word)
        isRandomScrabbleLoading = false
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

private struct BananagramShowcaseCard: View {
    let word: String?
    let definition: DataMuseDefinition?
    let isLoading: Bool
    let onDraw: () -> Void

    @State private var glowPhase = false
    @State private var rotateBeams = false
    @State private var revealTiles = false
    @State private var hasStartedAnimations = false

    var body: some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: 12) {
                header
                wordSection
                definitionSection
            }
            .padding(16)
        }
        .onAppear {
            startAnimations()
            if hasWord {
                triggerReveal()
            }
        }
        .onChange(of: word ?? "") { _, newValue in
            if !newValue.isEmpty {
                triggerReveal()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bananagram Showdown")
                    .font(.headline)
                Text("Random Scrabble word and definition")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button(action: onDraw) {
                Label("Draw Scrabble Word", systemImage: "sparkles")
                    .font(.callout.weight(.semibold))
            }
            .modifier(PrimaryButtonModifier())
            .disabled(isLoading)
            .opacity(isLoading ? 0.7 : 1)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.orange.opacity(glowPhase ? 0.8 : 0.3), lineWidth: 1)
            )
            .scaleEffect(glowPhase ? 1.02 : 1.0)
        }
    }

    private var wordSection: some View {
        Group {
            if hasWord, let word {
                BananagramTilesView(word: word, reveal: revealTiles, glowPhase: glowPhase)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                Text("Tap draw to pull a word from the Scrabble list.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
    }

    private var definitionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Shuffling tiles...")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else if let definitionText {
                if !partOfSpeechTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(partOfSpeechTags, id: \.self) { tag in
                            BananagramTagView(label: tag)
                        }
                    }
                }

                Text(definitionText)
                    .font(.callout)
                    .foregroundStyle(.primary)
            } else if hasWord {
                Text("No definition available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Draw a word to reveal its definition.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.yellow.opacity(0.18))
            .overlay(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.yellow.opacity(0.4),
                        Color.orange.opacity(0.2),
                        Color.yellow.opacity(0.4)
                    ]),
                    center: .center
                )
                .rotationEffect(.degrees(rotateBeams ? 360 : 0))
                .blendMode(.screen)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
            )
            .shadow(
                color: Color.orange.opacity(glowPhase ? 0.35 : 0.18),
                radius: glowPhase ? 18 : 10,
                x: 0,
                y: 6
            )
    }

    private var hasWord: Bool {
        if let word, !word.isEmpty {
            return true
        }
        return false
    }

    private var definitionText: String? {
        guard let definition, let rawDefinition = definition.defs.first else { return nil }
        let trimmed = String(rawDefinition.dropFirst(1)).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var partOfSpeechTags: [String] {
        guard let definition else { return [] }
        var tags: [String] = []

        if definition.isNoun { tags.append("noun") }
        if definition.isVerb { tags.append("verb") }
        if definition.isAdjective { tags.append("adjective") }
        if tags.isEmpty, definition.isNoPartOfSpeach { tags.append("unknown") }

        return tags
    }

    private func triggerReveal() {
        revealTiles = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            revealTiles = true
        }
    }

    private func startAnimations() {
        guard !hasStartedAnimations else { return }
        hasStartedAnimations = true

        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            rotateBeams = true
        }

        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            glowPhase = true
        }
    }
}

private struct BananagramTilesView: View {
    let word: String
    let reveal: Bool
    let glowPhase: Bool

    var body: some View {
        WrappingHStack(alignment: .center, horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Array(word.uppercased().enumerated()), id: \.offset) { index, letter in
                BananagramTileView(
                    letter: String(letter),
                    index: index,
                    reveal: reveal,
                    glowPhase: glowPhase
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BananagramTileView: View {
    let letter: String
    let index: Int
    let reveal: Bool
    let glowPhase: Bool

    var body: some View {
        Text(letter)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.85))
            .frame(width: 42, height: 46)
            .background(tileBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(
                color: Color.orange.opacity(glowPhase ? 0.5 : 0.25),
                radius: glowPhase ? 10 : 5,
                x: 0,
                y: 4
            )
            .scaleEffect(reveal ? 1 : 0.2)
            .rotationEffect(.degrees(reveal ? 0 : (index.isMultiple(of: 2) ? -12 : 12)))
            .offset(y: reveal ? 0 : 8)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.65, blendDuration: 0)
                    .delay(Double(index) * 0.05),
                value: reveal
            )
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange.opacity(0.85)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

private struct BananagramTagView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.08), in: Capsule(style: .continuous))
    }
}

#Preview {
    ContentView()
}
