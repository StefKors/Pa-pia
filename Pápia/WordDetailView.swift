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

#if os(macOS)

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
            for scope in model.relatedScopes {
                let words = await model.fetch(scope: scope, searchText: word.word)
                results.append(WordDetailInformation(scope: scope, words: words))
            }
        }
        .task(id: word) {
            self.definitions = await model.definitions(search: word.word)
        }
    }
}

#else

struct PillTag: View {
    let label: String
    let isSelected: Bool

    init(label: String, isSelected: Bool) {
        self.label = label
        self.isSelected = isSelected
    }

    init(scope: DataMuseViewModel.SearchScope, isSelected: Bool) {
        self.label = String(scope.label.trimmingPrefix("Related: "))
        self.isSelected = isSelected
    }

    var body: some View {
        Text(label)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .font(.callout)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), in: .capsule(style: .continuous))
    }
}

#Preview {
    HStack {
        PillTag(scope: .preview, isSelected: true)
        PillTag(scope: .preview, isSelected: false)
        PillTag(scope: .preview, isSelected: false)
        PillTag(scope: .preview, isSelected: false)
    }
    .scenePadding()
}


struct WordDetailView: View {
    let word: DataMuseWord

    @State private var information: [DataMuseViewModel.SearchScope: [DataMuseWord]] = [:]
    @StateObject private var model = DataMuseViewModel()
    @State private var results: [WordDetailInformation] = []
    @State private var definitions: [DataMuseDefinition] = []

    @Environment(\.dismiss) private var dismiss

    @State private var selectedScope: DataMuseViewModel.SearchScope? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "chevron.left")
                    .bold()
                    .font(.title3)

                Text(word.word.capitalized)
                    .font(.title)
                    .bold()
                if word.isWordle {
                    Image(.wordle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20, alignment: .leadingLastTextBaseline)
                }
//
//                if word.isWordle {
//                    Image(.scrabble)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 20, height: 20, alignment: .leadingLastTextBaseline)
//                }

                Spacer()
            }
                .scenePadding(.horizontal)
                .onTapGesture {
                    dismiss()
                }


            ScrollView(.horizontal) {
                HStack {
                    PillTag(label: "Definition", isSelected: selectedScope == nil)
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.1)) {
                                selectedScope = nil
                            }
                        }
                    ForEach(model.relatedScopes) { scope in
                        PillTag(scope: scope, isSelected: selectedScope == scope)
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.1)) {
                                    selectedScope = scope
                                }
                            }
                    }
                }
                .padding()
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)

            ScrollView {
                VStack {
                    if selectedScope == nil {
                        ForEach(definitions) { definition in
                            DefinitionView(def: definition)
                        }
                    } else if let selectedScope {
                        WordDetailListSectionView(scope: selectedScope, word: word)
                            .id(selectedScope)
                    }
                }
                .environmentObject(model)
                .scenePadding(.horizontal)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationTitle(word.word)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: word) {
            self.definitions = await model.definitions(search: word.word)
        }
    }
}

#endif

#Preview {
    WordDetailView(word: .preview)
}
