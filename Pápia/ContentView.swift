//
//  ContentView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI
import SwiftData
import Get

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable private var model = DataMuseViewModel()

    var iOSContentView: some View {
        NavigationStack {
            List {
                ForEach(model.searchResults) { searchResult in
                    NavigationLink {
                        WordDetailView(word: searchResult)

                    } label: {
                        WordView(label: searchResult.word)
                    }
                }
            }
//            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Search...")
        }
        .searchable(text: $model.searchText, prompt: "Find words...")
        .searchScopes($model.searchScope, activation: .onSearchPresentation) {
            ForEach(model.globalSearchScopes) { scope in
                Text(scope.label)
                    .tag(scope)
            }
        }
        .searchContentUnavailableView(
            searchResultsCount: model.searchResults.count,
            searchText: model.searchText
        )
        .onChange(of: model.searchScope, { oldValue, newValue in
            model.autocomplete()
            model.search()
        })
        .onChange(of: model.searchText, { oldValue, newValue in
            model.autocomplete()
            model.search()
        })


    }
//https://developer.apple.com/documentation/swiftui/environmentvalues/issearching
    var MacOSContentView: some View {
        NavigationStack {
            List {
                ForEach(model.searchResults) { searchResult in
                    NavigationLink(value: searchResult) {
                        WordView(label: searchResult.word)
                    }
                }
            }
            .searchable(text: $model.searchText, prompt: "Find words...")
            .navigationDestination(for: DataMuseWord.self, destination: { word in
                WordDetailView(word: word)
            })
            .navigationTitle("Search...")
            .toolbar {
                ToolbarItem {
                    Button("test") {

                    }
                }
            }
        }

        .navigationSplitViewStyle(.prominentDetail)
        //        .searchSuggestions() {
        //            ForEach(model.suggestedSearches) { suggestion in
        //                Text(suggestion.word)
        //                    .searchCompletion(suggestion.word)
        //            }
        //        }
        .searchScopes($model.searchScope, activation: .onSearchPresentation) {
            ForEach(model.globalSearchScopes) { scope in
                Text(scope.label)
                    .tag(scope)
            }
        }
        .onChange(of: model.searchScope, { oldValue, newValue in
            model.autocomplete()
            model.search()
        })
        .onChange(of: model.searchText, { oldValue, newValue in
            model.autocomplete()
            model.search()
        })
        .overlay {
            //            if model.searchResults.isEmpty, !model.searchText.isEmpty {
            if model.searchResults.isEmpty {
                if !model.searchText.isEmpty {
                    /// In case there aren't any search results, we can
                    /// show the new content unavailable view.
                    ContentUnavailableView.search(text: model.searchText)
                } else {
                    ContentUnavailableView {
                        Label("Search Pápia...", systemImage: "bird.fill")
                    } description: {
                        Text("Start your search, then filter your query")
                    } actions: {
                        WrappingHStack {

                            /// TODO: sort and filter to most recent x couple
                            ForEach(searchHistoryItems) { item in
                                Button {
                                    withAnimation(.smooth) {
                                        model.searchText = item.word.word
                                    }
                                } label: {
                                    WordView(label: item.word.word)
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.tint, in: Capsule())
                            }
                        }
                    }

                }
            }
        }
    }


    var body: some View {
#if os(macOS)
        MacOSContentView
#else
        iOSContentView
#endif
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
