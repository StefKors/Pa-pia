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

@Observable class InterfaceState {
    var selection: DataMuseWord?  // Nothing selected by default.
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable private var model = DataMuseViewModel()

    @Bindable private var state = InterfaceState()

    var body: some View {
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
        .environment(state)
        .modifier(
            iOSContentViewAdjustmentsView(
                searchResultsCount: model.searchResults.count,
                searchText: model.searchText
            )
        )
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

    private func addItem(word: DataMuseWord) {
        withAnimation {
            let newItem = SearchHistoryItem(timestamp: Date(), word: word)
            modelContext.insert(newItem)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SearchHistoryItem.self, inMemory: true)
}
