//
//  ContentView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI
import SwiftData
import Get

@propertyWrapper
public struct CodableAppStorage<Value: Codable>: DynamicProperty {
    @AppStorage
    private var value: Data

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) {
        _value = .init(wrappedValue: try! encoder.encode(wrappedValue), key, store: store)
    }

    public var wrappedValue: Value {
        get { try! decoder.decode(Value.self, from: value) }
        nonmutating set { value = try! encoder.encode(newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

struct iOSContentViewAdjustmentsView: ViewModifier {
    let searchResultsCount: Int
    let searchText: String
    let searchIsFocused: FocusState<Bool>.Binding
    func body(content: Content) -> some View {
#if os(macOS)
        content
#else
        content
            .navigationBarTitleDisplayMode(.large)
            .searchContentUnavailableView(
                searchResultsCount: searchResultsCount,
                searchText: searchText,
                searchIsFocused: searchIsFocused
            )
#endif
    }
}

class InterfaceState: ObservableObject {
    // Nothing selected by default.
    @Published var selection: DataMuseWord?
    @CodableAppStorage("search-history") var searchHistory: [String] = []
    @Published var navigationHistory: [DataMuseWord] = []
    @Published var navigation: [DataMuseWord] = [] {
        didSet {
            if let latest = navigation.last {
                navigationHistory.append(latest)
            }
        }
    }
}

struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), #available(macOS 26.0, *) {
            content
                .glassEffect()
        } else {
            content
                .background(.quinary, in: Capsule(style: .continuous))
        }
    }
}


struct ScrollEdgeEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), #available(macOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectStyle(.hard, for: .bottom)
        } else {
            content
        }
    }
}

#Preview {
    Text("Hello, world!")
        .padding()
        .modifier(GlassEffectModifier())
}


// TODO: add search progress @Environment(\.isSearching) private var isSearching
// TODO: add indicator if the word exists in the wordle dictionary
// TODO: add buttons to insert wild card character for complex searches
// TODO: add indicator if the word exists in the scrabble dictionary
// TODO: show word also in Dutch and Greek
// TODO: lazy load the Word Detail List Sections so they are loaded as you scroll, most are out of view anyways
// TODO: add feature to favourite words
struct ContentView: View {

    @StateObject private var model = DataMuseViewModel()

    @StateObject var state = InterfaceState()

    @FocusState private var searchFocused: Bool

    var filteredSearchHistory: [String] {
        if model.searchText.isEmpty {
            return state.searchHistory
        }

        return state.searchHistory.filter { $0.contains(model.searchText) }
    }

    var macOSContentView: some View {
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
                searchIsFocused: $searchIsFocused
            )
        )
#else
        EmptyView()
#endif
    }

    var showClearButton: Bool {
        !model.searchText.isEmpty
    }

    var showCancelButton: Bool {
        showClearButton || searchIsFocused
    }

    var backgroundColor: Color {
#if os(macOS)
        Color(nsColor: NSColor.windowBackgroundColor)
#else
        Color(uiColor: UIColor.secondarySystemBackground)
#endif
    }

    @FocusState private var searchIsFocused: Bool

    var iOSContentView: some View {
#if os(iOS)
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(model.searchResults) { word in
                        NavigationLink {
                            WordDetailView(word: word)
                        } label: {
                            WordView(word: word)
                        }
                    }
                }

                .contentMargins(.vertical, 140, for: .scrollContent)
                .modifier(
                    iOSContentViewAdjustmentsView(
                        searchResultsCount: model.searchResults.count,
                        searchText: model.searchText,
                        searchIsFocused: $searchIsFocused
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
                                //                                    .searchToolbar()
                                    .environmentObject(model)
                                    .defaultFocus($searchIsFocused, true)
                            } else {
                                TextField("Find words...", text: $model.searchText)
                                    .focused($searchIsFocused)
                                //                                    .searchToolbar()
                                    .environmentObject(model)
                            }

                            if showClearButton {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.secondary)
                                    .onTapGesture {
                                        withAnimation(.smooth(duration: 0.3)) {
                                            self.model.searchText = ""
                                        }
                                    }
                                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                            }

                        }
                        .padding(6)
                        .modifier(GlassEffectModifier())

                        if showCancelButton {
                            Text("Cancel")
                                .onTapGesture {
                                    withAnimation(.smooth(duration: 0.3)) {
                                        searchIsFocused.toggle()
                                    }
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .foregroundStyle(.tint)
                        }
                    }
                    .font(.body)
                    .animation(.smooth(duration: 0.3), value: showClearButton)
                    .animation(.smooth(duration: 0.3), value: showCancelButton)

                    ToolbarButtonsGroup()

                    if #available(iOS 26.0, *), #available(macOS 26.0, *) {

                    } else {
                        Picker("Search Scope", selection: $model.searchScope) {
                            ForEach(model.globalSearchScopes) { scope in
                                Text(scope.label)
                                    .tag(scope)
                            }
                        }.pickerStyle(.segmented)
                    }


                }
                .scenePadding(.horizontal)
                .scenePadding(.vertical)
            }
            .overlay(alignment: .bottom) {
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
            self.model.searchResults = await self.model.fetch(scope: self.model.searchScope, searchText: self.model.searchText)
        }
        .task(id: model.searchScope) {
            self.model.searchResults = await self.model.fetch(scope: self.model.searchScope, searchText: self.model.searchText)
        }
    }
}

#Preview {
    ContentView()
}
