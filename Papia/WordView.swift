//
//  WordView.swift
//  Papia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI

struct WordView: View {
    let word: DataMuseWord
    @AppStorage("scrabble-icon-style") private var scrabbleIconStyle: String = ScrabbleIconStyle.scrabble.rawValue

    var body: some View {
        HStack {
            Text(word.word.capitalized)
            Spacer()
            if word.isWordle {
                Image(.wordle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20, alignment: .leadingLastTextBaseline)
            }

            if word.isScrabble {
                Image(scrabbleIconStyle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20, alignment: .leadingLastTextBaseline)
            }

            if word.isCommonBongo {
                Image(.bongo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20, alignment: .leadingLastTextBaseline)
            }
        }
    }
}

#Preview {
    WordView(word: .preview)
}
