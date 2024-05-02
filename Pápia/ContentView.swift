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
}

struct ContentView: View {

    @StateObject private var model = DataMuseViewModel()

    @StateObject var state = InterfaceState()

    var macOSContentView: some View {
        NavigationSplitView {
            List(model.searchResults, selection: $state.selection) { word in
                NavigationLink(value: word) {
                    WordView(label: word.word)
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
        NavigationSplitView {
            List(model.searchResults, selection: $state.selection) { word in
                NavigationLink(value: word) {
                    WordView(label: word.word)
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
