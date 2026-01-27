//
//  DataMuseWord.swift
//  Papia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation

struct DataMuseWord: Identifiable, Codable, Hashable {
    let word: String
    let score: Int

    var isWordle: Bool = false
    var isScrabble: Bool = false
    var isCommonBongo: Bool = false

    var id: String {
        self.word + "-" + self.score.description
    }

    init(word: String, score: Int) {
        self.word = word
        self.score = score
    }

    init(word: String, score: Int, isWordle: Bool, isScrabble: Bool, isCommonBongo: Bool) {
        self.word = word
        self.score = score
        self.isWordle = isWordle
        self.isScrabble = isScrabble
        self.isCommonBongo = isCommonBongo
    }

    enum CodingKeys: CodingKey {
        case word
        case score
    }

    init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<DataMuseWord.CodingKeys> = try decoder.container(keyedBy: DataMuseWord.CodingKeys.self)

        self.word = try container.decode(String.self, forKey: DataMuseWord.CodingKeys.word)
        self.score = try container.decode(Int.self, forKey: DataMuseWord.CodingKeys.score)

    }

    func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<DataMuseWord.CodingKeys> = encoder.container(keyedBy: DataMuseWord.CodingKeys.self)

        try container.encode(self.word, forKey: DataMuseWord.CodingKeys.word)
        try container.encode(self.score, forKey: DataMuseWord.CodingKeys.score)
    }
}

extension DataMuseWord {
    static let preview = DataMuseWord(word: "apple", score: 7840)
    static let preview2 = DataMuseWord(word: "angle", score: 3014)
}
