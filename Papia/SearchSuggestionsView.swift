//
//  SearchSuggestionsView.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI

struct SearchSuggestionsView: ViewModifier {
    let suggestedSearches: [DataMuseWord] = []

    func body(content: Content) -> some View {
        content
            .searchSuggestions() {
                ForEach(suggestedSearches) { suggestion in
                    Text(suggestion.word)
                        .searchCompletion(suggestion.word)
                }
            }
    }
}

extension View {
    func searchSuggestions() -> some View {
        modifier(SearchSuggestionsView())
    }
}

#Preview {
    Text("Hello, world!")
        .searchSuggestions()
}
