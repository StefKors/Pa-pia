//
//  DataMuseDefinition.swift
//  Papia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation

struct DataMuseDefinition: Identifiable, Codable, Hashable {
    let word: String
    let score: Int
    /// "n" means noun, "v" means verb, "adj" means adjective, "adv" means adverb, and "u" means that the part of speech is none of these or cannot be determined.
    let tags: [String]
    let defs: [String]

    var isNoun: Bool {
        tags.contains { $0 == "n" }
    }

    var isVerb: Bool {
        tags.contains { $0 == "v" }
    }

    var isAdjective: Bool {
        tags.contains { $0 == "adj" }
    }

    var isNoPartOfSpeach: Bool {
        tags.contains { $0 == "u" }
    }

    var id: String {
        self.word + "-" + self.score.description
    }
}

extension DataMuseDefinition {
    static let preview = DataMuseDefinition(
        word: "apple",
        score: 7840,
        tags: ["query", "n", "v"],
        defs: [
            "n\tA common, round fruit produced by the tree Malus domestica, cultivated in temperate climates. ",
            "n\tAny fruit or vegetable, or any other thing produced by a plant such as a gall or cone, especially if produced by a tree and similar to the fruit of Malus domestica; also (with qualifying words) used to form the names of specific fruits such as custard apple, rose apple, thorn apple etc. ",
            "n\tSomething which resembles the fruit of Malus domestica, such as a globe, ball, or breast. ",
            "n\t(baseball, slang, obsolete) The ball in baseball. ",
            "n\t(informal) When smiling, the round, fleshy part of the cheeks between the eyes and the corners of the mouth. ",
            "n\tThe Adam's apple. ",
            "n\t(Christianity) The fruit of the Tree of Knowledge, eaten by Adam and Eve according to modern Christian tradition; the forbidden fruit. ",
            "n\tA tree of the genus Malus, especially one cultivated for its edible fruit; the apple tree. ",
            "n\tThe wood of the apple tree. ",
            "n\t(derogatory, ethnic slur) A Native American or redskinned person who acts or thinks like a white (Caucasian) person. ",
            "n\t(ice hockey, slang) An assist. ",
            "n\t(slang) A CB radio enthusiast. ",
            "v\t(transitive, intransitive) To make or become apple-like. ",
            "v\t(obsolete) To form buds, bulbs, or fruit. ",
            "n\t(with \"the\") A nickname for New York City, usually “the Big Apple”. ",
            "n\t(trademark) A company/corporation. ",
            "n\tThe company Apple Inc., formerly Apple Computer, that produces computers and other digital devices, and sells and produces multimedia content. ",
            "n\tA multimedia corporation (Apple Corps) and record company (Apple Records) founded by the Beatles. ",
            "n\t(rare, countable) A female given name from English. ",
            "n\t(countable) A surname. ",
            "n\tA computer produced by the company Apple Inc. ",
            "n\t(in the plural, Cockney rhyming slang) Short for apples and pears (“stairs”). [(Cockney rhyming slang) stairs] "
        ]
    )
    static let preview2 = DataMuseDefinition(
        word: "tree",
        score: 3014,
        tags: ["query", "n", "v"],
        defs: [
            "n\tA perennial woody plant taller and larger than a bush with a wooden trunk and, at some distance from the ground, leaves and branches. ",
            "n\tAny plant that is reminiscent of the above but not classified as a tree (in any botanical sense). ",
            "n\tAn object made from a tree trunk and having multiple hooks or storage platforms. ",
            "n\tA device used to hold or stretch a shoe open. ",
            "n\tThe structural frame of a saddle. ",
            "n\t(graph theory) A connected graph with no cycles or, if the graph is finite, equivalently a connected graph with n vertices and n−1 edges. ",
            "n\t(computing theory) A recursive data structure in which each node has zero or more nodes as children. ",
            "n\t(graphical user interface) A display or listing of entries or elements such that there are primary and secondary entries shown, usually linked by drawn lines or by indenting to the right. ",
            "n\tAny structure or construct having branches representing divergence or possible choices. ",
            "n\tThe structure or wooden frame used in the construction of a saddle used in horse riding. ",
            "n\t(in the plural, slang) Marijuana. ",
            "n\t(obsolete) A cross or gallows. ",
            "n\t(chemistry) A mass of crystals, aggregated in arborescent forms, obtained by precipitation of a metal from solution. ",
            "n\t(cartomancy) The fifth Lenormand card. ",
            "v\t(transitive) To chase (an animal or person) up a tree. ",
            "v\t(transitive) To place in a tree. ",
            "v\t(transitive) To place upon a tree; to fit with a tree; to stretch upon a tree. ",
            "v\t(intransitive) To take refuge in a tree. ",
            "n\t(mathematics) An extremely fast-growing function based on Kruskal's tree theorem. ",
            "n\tA surname. ",
            "n\t(uncountable, mathematics) Alternative letter-case form of TREE. [(mathematics) An extremely fast-growing function based on Kruskal's tree theorem.] ",
            "n\t(mathematics) Alternative letter-case form of TREE [(mathematics) An extremely fast-growing function based on Kruskal's tree theorem.] "
        ]
    )
}
