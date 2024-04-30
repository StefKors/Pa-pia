//
//  WordDetailListSectionView.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI

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
