//
//  WordDetailListSectionView.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI

struct NavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.tint, in: Capsule())
        
        //            .background(configuration.isPressed ? Color.blue : Color.pink)
    }
}

struct WordDetailListSectionView: View {
    let scope: DataMuseViewModel.SearchScope
    let word: DataMuseWord

    @State private var info: WordDetailInformation?

    @EnvironmentObject private var model: DataMuseViewModel

    var body: some View {
        Group {
            if let info {
                WordDetailSectionView(info: info)
            } else {
                WordDetailSectionView(info: .preview)
                    .redacted(reason: .placeholder)
            }
        }
        .task(id: scope) {
            let words = await model.fetch(scope: scope, searchText: word.word)
            withAnimation(.smooth) {
                self.info = WordDetailInformation(scope: scope, words: words)
            }
        }
    }
}

#Preview {
    WordDetailListSectionView(scope: .preview, word: .preview)
}


struct WordDetailSectionView: View {
    let info: WordDetailInformation
    private var markdownText: LocalizedStringKey {
        "\(info.scope.description)"
    }

    @State private var expandDescription: Bool = false
    @State private var isExpanded: Bool = false
    @EnvironmentObject private var state: InterfaceState

    var body: some View {
        GroupBox(info.scope.label) {
            Text(markdownText)
                .lineLimit(expandDescription ? 1000 : 2)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    withAnimation(.smooth) {
                        expandDescription.toggle()
                    }
                }

            HStack(alignment: .lastTextBaseline) {
                VStack {
                    WrappingHStack(alignment: .topLeading) {
                        ForEach(info.words) { word in
                            NavigationLink {
                                WordDetailView(word: word)
                            } label: {
                                WordView(label: word.word)
                            }
                            .buttonStyle(NavigationButtonStyle())
                            .id(word)
                            //                    Button {
                            //                        state.selection = word // macOS
                            //                        state.navigationPath.append(word) // iOS
                            //                    } label: {
                            //                        WordView(label: word.word)
                            //                    }

                        }
                    }
                    //                            .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    WordDetailSectionView(info: .preview)
}
