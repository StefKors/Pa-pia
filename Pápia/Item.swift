//
//  Item.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation
import SwiftData

@Model
final class SearchHistoryItem {
    var timestamp: Date
    var word: DataMuseWord

    init(timestamp: Date, word: DataMuseWord) {
        self.timestamp = timestamp
        self.word = word
    }
}
