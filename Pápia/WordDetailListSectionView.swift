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
    @Environment(InterfaceState.self) private var state

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
                        state.selection = word
                    } label: {
                        WordView(label: word.word)
                    }
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.tint, in: Capsule())
                }
            }
        }
    }
}

#Preview {
    WordDetailListSectionView(info: .preview)
}
