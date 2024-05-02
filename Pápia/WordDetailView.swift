//
//  WordDetailView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation
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
    @StateObject private var model = DataMuseViewModel()
    @State private var results: [WordDetailInformation] = []
    @State private var definitions: [DataMuseDefinition] = []
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(definitions) { definition in
                    DefinitionView(def: definition)
                }

                ForEach(results) { info in
                    WordDetailListSectionView(info: info)
                }
            }
            .scenePadding()
        }
        .navigationTitle(word.word.capitalized)
        .task(id: word) {
            self.results = []
            for scope in model.searchScopes {
                let words = await model.fetch(scope: scope, searchText: word.word)
                results.append(WordDetailInformation(scope: scope, words: words))
            }
        }
        .task(id: word) {
            self.definitions = await model.definitions(search: word.word)
        }
    }
}

#Preview {
    WordDetailView(word: .preview)
}
