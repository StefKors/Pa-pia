//
//  DataMuseWord.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation

struct DataMuseWord: Identifiable, Codable {
    let word: String
    let score: Int

    var id: String {
        self.word + "-" + self.score.description
    }
}

extension DataMuseWord {
    static let preview = DataMuseWord(word: "apple", score: 7840)
    static let preview2 = DataMuseWord(word: "angle", score: 3014)
}
