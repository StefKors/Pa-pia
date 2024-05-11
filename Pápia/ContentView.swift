//
//  ContentView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI
import SwiftData
import Get


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

    var iOSContentView: some View {
        NavigationView {
            List(model.searchResults) { word in
                NavigationLink {
                    WordDetailView(word: word)
                } label: {
                    WordView(word: word)
                }
            }
            .searchable(text: $model.searchText, placement: .sidebar, prompt: "Find words...")
            .scrollDismissesKeyboard(.immediately)
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
        .searchScopes($model.searchScope, activation: .onSearchPresentation) {
            ForEach(model.globalSearchScopes) { scope in
                Text(scope.label)
                    .tag(scope)
            }
        }
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
