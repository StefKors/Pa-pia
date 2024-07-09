//
//  ContentView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI
import SwiftData
import Get
import Glur

struct iOSContentViewAdjustmentsView: ViewModifier {
    let searchResultsCount: Int
    let searchText: String

    func body(content: Content) -> some View {
#if os(macOS)
        content
#else
        content
            .navigationBarTitleDisplayMode(.large)
            .searchContentUnavailableView(
                searchResultsCount: searchResultsCount,
                searchText: searchText
            )
#endif
    }
}

class InterfaceState: ObservableObject {
    @Published var selection: DataMuseWord?  // Nothing selected by default.
    @Published var navigationPath: NavigationPath = NavigationPath()
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

    var macOSContentView: some View {
        NavigationSplitView {
            List(model.searchResults, selection: $state.selection) { word in
                NavigationLink(value: word) {
                    WordView(word: word)
                }
            }
            .searchable(text: $model.searchText, placement: .sidebar, prompt: "Find words...")
        } detail: {
            if let word = state.selection {
                WordDetailView(word: word)
                    .id(state.selection)
            } else {
                SearchContentUnavailableView(
                    searchResultsCount: model.searchResults.count,
                    searchText: model.searchText
                )
            }
        }
        .modifier(
            iOSContentViewAdjustmentsView(
                searchResultsCount: model.searchResults.count,
                searchText: model.searchText
            )
        )
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
        NavigationView {
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .imageScale(.medium)
                                .foregroundStyle(.tertiary)

                            if #available(iOS 17.0, *) {
                                TextField("Find words...", text: $model.searchText)
                                    .focused($searchIsFocused)
                                    .searchToolbar()
                                    .environmentObject(model)
                                    .defaultFocus($searchIsFocused, true)
                            } else {
                                TextField("Find words...", text: $model.searchText)
                                    .focused($searchIsFocused)
                                    .searchToolbar()
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
                        .background(.quinary, in: RoundedRectangle(cornerRadius: 6))

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

                    Picker("Search Scope", selection: $model.searchScope) {
                        ForEach(model.globalSearchScopes) { scope in
                            Text(scope.label)
                                .tag(scope)
                        }
                    }.pickerStyle(.segmented)
                }
                .scenePadding(.horizontal)
                .scenePadding(.top)

                List(model.searchResults) { word in
                    NavigationLink {
                        WordDetailView(word: word)
                    } label: {
                        WordView(word: word)
                    }
                }
                .overlay(alignment: .top) {
                    LinearGradient(stops: [
                        .init(color: backgroundColor.opacity(0.8), location: 0.5),
                        .init(color: .clear, location: 0.8)
                    ], startPoint: .top, endPoint: .bottom)
                        .frame(height: 60)
                        .glur(radius: 32.0, offset: 0.3, interpolation: 0.5)
                        .allowsHitTesting(false)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .background(backgroundColor)
        }
        .modifier(
            iOSContentViewAdjustmentsView(
                searchResultsCount: model.searchResults.count,
                searchText: model.searchText
            )
        )
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
