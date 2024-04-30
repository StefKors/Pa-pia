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

struct WordDetailListSectionView: View {
    let info: WordDetailInformation

    private var markdownText: LocalizedStringKey {
        "\(info.scope.description)"
    }

    @State private var showMore: Bool = false
    var body: some View {
        Section(info.scope.label) {
            Text(markdownText)
                .lineLimit(showMore ? 1000 : 2)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    withAnimation(.smooth) {
                        showMore.toggle()
                    }
                }

            WrappingHStack(alignment: .topLeading) {
                ForEach(info.words) { word in
                    Button {
//                        withAnimation(.smooth) {
//                            model.searchText = item.word.word
//                        }
                    } label: {
                        WordView(label: word.word)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.tint, in: Capsule())
                    //                            Text(word.word)
                    //                            NavigationLink {
                    //                                WordDetailView(word: word)
                    //                            } label: {
                    //
                    //                            }
                }
            }
        }
    }
}

#Preview {
    WordDetailListSectionView(info: .preview)
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
