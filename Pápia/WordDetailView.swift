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

// https://api.datamuse.com/words?ml=tree&qe=ml&md=dp&max=1
struct DefinitionView: View {
    let def: DataMuseDefinition

    private let first: String
    private let others: [String]

    @State private var showAll: Bool = false

    init(def: DataMuseDefinition) {
        self.def = def
        var definitions = def.defs.map {
            $0.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.first = definitions.removeFirst()
        self.others = definitions
    }

    var body: some View {
        Section {
            HStack {
                if def.isNoun {
                    Text("noun")
                        .padding(.horizontal, 4)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 4))
                }

                if def.isVerb {
                    Text("verb")
                        .padding(.horizontal, 4)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 4))
                }

                if def.isAdjective {
                    Text("adjective")
                        .padding(.horizontal, 4)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 4))
                }
            }
            .font(.footnote)


            VStack(alignment: .leading, spacing: 12) {
                Text(first)

                if showAll {
                    ForEach(others, id: \.self) { definition in
                        Divider()

                        Text(definition)
                    }
                }
            }
            .lineLimit(nil)
            .font(.body)
            .italic()
        }
        .foregroundStyle(.secondary)
        .onTapGesture {
            showAll.toggle()
        }
    }


}

#Preview {
    DefinitionView(def: .preview)
}


/// TODO: Add bookmark button
/// TODO: Support definitions with: https://api.datamuse.com/words?sl=jirraf&md=dpsr
struct WordDetailView: View {
    let word: DataMuseWord

    @State private var information: [DataMuseViewModel.SearchScope: [DataMuseWord]] = [:]
    @Bindable private var model = DataMuseViewModel()
    @State private var results: [WordDetailInformation] = []
    @State private var definitions: [DataMuseDefinition] = []
    var body: some View {
        VStack {
            List {
                ForEach(definitions) { definition in
                    DefinitionView(def: definition)
                }

                ForEach(results) { info in
                    WordDetailListSectionView(info: info)
                }
            }
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
