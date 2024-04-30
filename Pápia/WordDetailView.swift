//
//  WordDetailView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI

struct WordDetailInformation: Identifiable {
    let scope: DataMuseViewModel.SearchScope
    let words: [DataMuseWord]

    var id: String {
        self.scope.id
    }

    static let preview = WordDetailInformation(scope: .preview, words: [.preview, .preview2])
}

/// TODO: Add bookmark button
/// TODO: Support definitions with: https://api.datamuse.com/words?sl=jirraf&md=dpsr
struct WordDetailView: View {
    let word: DataMuseWord

    @State private var information: [DataMuseViewModel.SearchScope: [DataMuseWord]] = [:]
    @Bindable private var model = DataMuseViewModel()
    @State private var results: [WordDetailInformation] = []

    var body: some View {
        List(results) { info in
            WordDetailListSectionView(info: info)
        }
//        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(word.word.capitalized)
        .task {
            Task {
                for scope in model.searchScopes {
                    let words = await model.fetch(scope: scope, searchText: word.word)
                    results.append(WordDetailInformation(scope: scope, words: words))
                }
            }
        }
    }
}

#Preview {
    WordDetailView(word: .preview)
}
