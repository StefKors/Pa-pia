//
//  SearchContentUnavailableView.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI
import SwiftData

extension View {
    func searchContentUnavailableView(searchResultsCount: Int, searchText: String) -> some View {
        modifier(
            SearchContentUnavailableViewModifier(
                searchResultsCount: searchResultsCount,
                searchText: searchText
            )
        )
    }
}

struct SearchContentUnavailableViewModifier: ViewModifier {
    let searchResultsCount: Int
    let searchText: String

    func body(content: Content) -> some View {
        content
            .overlay {
                SearchContentUnavailableView(
                    searchResultsCount: searchResultsCount,
                    searchText: searchText
                )
            }
    }
}

/// TODO: sort and filter to most recent x couple
/// TODO: open on button click
struct SearchContentUnavailableView: View {
    let searchResultsCount: Int
    let searchText: String

    var body: some View {
        if searchResultsCount == 0 {
            if !searchText.isEmpty {
                /// In case there aren't any search results, we can
                /// show the new content unavailable view.
                if #available(iOS 17.0, *) {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    Text("No results for: \(searchText)")
                    // Fallback on earlier versions
                }
            } else {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView {
                        Label("Search Pápia...", systemImage: "bird.fill")
                    } description: {
                        Text("Start your search, then filter your query")
                    } actions: {
                        //                    WrappingHStack {
                        //                        ForEach(searchHistoryItems) { item in
                        //                            Button {
                        //                                /// todo: open
                        //                            } label: {
                        //                                WordView(label: item.word.word)
                        //                            }
                        //                            .foregroundStyle(.primary)
                        //                            .padding(.horizontal, 12)
                        //                            .padding(.vertical, 4)
                        //                            .background(.tint, in: Capsule())
                        //                        }
                        //                    }
                    }
                } else {
                    VStack {
                        Label("Search Pápia...", systemImage: "bird.fill")
                        Text("Start your search, then filter your query")
                    }
                }
            }
        }
    }
}

#Preview {
    Text("Hello, world!")
        .searchContentUnavailableView(searchResultsCount: 0, searchText: "")
}
