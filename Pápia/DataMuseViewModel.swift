//
//  DataMuseAPI.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation
import Get
import Observation

let memoryCapacity = 1024 * 1024 * 1024 // 1 GB
let diskCapacity = 2 * 1024 * 1024 * 1024 // 2 GB


/// https://api.datamuse.com/words?ml=tree&qe=ml&md=dpfcy&max=1&rif=1&k=olthes_r4
/// get defintions: https://api.datamuse.com/words?ml=tree&qe=ml&md=dp&max=1
class DataMuseViewModel: ObservableObject {
    @Published var searchText: String = ""
    /// TODO: don't hardcode?
    @Published var searchScope: SearchScope = SearchScope(
        queryParam: "sp",
        label: "Spelled like",
        description: """
require that the results are spelled similarly to this string of characters, or that they match this wildcard pattern. A pattern can include any combination of alphanumeric characters and the symbols described on that page.
- The asterisk (*) matches any number of letters.
- The question mark (?) matches exactly one letter.
- The number-sign (#) matches any English consonant.
- The at-sign (@) matches any English vowel (including "y").
- The comma (,) lets you combine multiple patterns into one. For example, the query ?????,*y* finds 5-letter words that contain a "y" somewhere, such as "happy" and "rhyme".
- Use double-slashes (//) before a group of letters to unscramble them (that is, find anagrams.) For example, the query //soulbeat will find "absolute" and "bales out", and re//teeprsn will find "represent" and "repenters".
- A minus sign (-) followed by some letters at the end of a pattern means "exclude these letters".
- A plus sign (+) followed by some letters at the end of a pattern means "restrict to these letters".
"""
    )

    @Published var searchResults: [DataMuseWord] = []
    @Published var suggestedSearches: [DataMuseWord] = []

    private let client = APIClient(baseURL: URL(string: "https://api.datamuse.com")) {
        $0.sessionConfiguration.urlCache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "papia_url_cache"
        )
    }

    func fetch(scope: SearchScope, searchText: String) async -> [DataMuseWord] {
        return await query("/words", scope: scope, search: searchText)
    }

    func autocomplete() {
        Task {
            self.suggestedSearches = await query("/sug", scope: autocompleteScope, search: searchText)
        }
    }

    func definitions(search: String) async -> [DataMuseDefinition] {
        let path = "/words"

        // filter out empty queries
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        print("Query Definition for:", search)
        var result: [DataMuseDefinition] = []
        do {
            result = try await client.send(
                Request(
                    path: path,
                    query: [
                        ("ml", search),
                        ("qe", "ml"),
                        ("md", "dp"),
                        ("max", "1"),
                    ]
                )
            ).value
        } catch {
            print(error.localizedDescription)
        }

        return result
    }

    private func query(_ path: String, scope: SearchScope, search: String) async -> [DataMuseWord] {
        // filter out empty queries
        if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        if scope.queryParam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        print("Query:", path, scope.queryParam, search)
        var result: [DataMuseWord] = []
        do {
            result = try await client.send(
                Request(
                    path: path,
                    query: [(scope.queryParam, search)]
                )
            ).value
        } catch {
            print(error.localizedDescription)
        }

        return result
    }

    struct Search: Identifiable, Equatable {
        let path: String
        let scope: SearchScope
        let searchText: String
        let id: UUID = UUID()
    
        static let preview = Search(
            path: "/words",
            scope: .preview,
            searchText: "apple"
        )
    }

    struct SearchScope: Identifiable, Codable, Hashable, Equatable {
        let queryParam: String
        let label: String
        let description: String

        var id: String {
            self.queryParam
        }

        static let preview = SearchScope(
            queryParam: "ml",
            label: "Means like",
            description: "require that the results have a meaning related to this string value, which can be any word or sequence of words."
        )
    }

    var globalSearchScopes: [SearchScope] {
        self.searchScopes.filter { scope in
            return !scope.queryParam.contains("rel_")
        }
    }

    let autocompleteScope = SearchScope(
        queryParam: "s",
        label: "Autocomplete",
        description: "It provides word suggestions given a partially-entered query using a combination of the operations described in the “/words” resource above. The suggestions perform live spelling correction and intelligently fall back to choices that are phonetically or semantically similar when an exact prefix match can't be found."
    )

    let searchScopes: [SearchScope] = [
        // TODO: Please be sure that your parameters are properly URL encoded when you form your request.
        SearchScope(
            queryParam: "sp",
            label: "Spelled like",
            description: """
require that the results are spelled similarly to this string of characters, or that they match this wildcard pattern. A pattern can include any combination of alphanumeric characters and the symbols described on that page.
- The asterisk (*) matches any number of letters.
- The question mark (?) matches exactly one letter.
- The number-sign (#) matches any English consonant.
- The at-sign (@) matches any English vowel (including "y").
- The comma (,) lets you combine multiple patterns into one. For example, the query ?????,*y* finds 5-letter words that contain a "y" somewhere, such as "happy" and "rhyme".
- Use double-slashes (//) before a group of letters to unscramble them (that is, find anagrams.) For example, the query //soulbeat will find "absolute" and "bales out", and re//teeprsn will find "represent" and "repenters".
- A minus sign (-) followed by some letters at the end of a pattern means "exclude these letters".
- A plus sign (+) followed by some letters at the end of a pattern means "restrict to these letters".
"""
        ),
        SearchScope(
            queryParam: "ml",
            label: "Means like",
            description: "require that the results have a meaning related to this string value, which can be any word or sequence of words."
        ),
        SearchScope(
            queryParam: "sl",
            label: "Sounds like",
            description: "require that the results are pronounced similarly to this string of characters. (If the string of characters doesn't have a known pronunciation, the system will make its best guess using a text-to-phonemes algorithm.) "
        ),
        SearchScope(
            queryParam: "rel_jja",
            label: "Related: Nouns",
            description: "Popular nouns modified by the given adjective, per Google Books Ngrams"
        ),
        SearchScope(
            queryParam: "rel_jjb",
            label: "Related: Adjectives",
            description: "Popular adjectives used to modify the given noun, per Google Books Ngrams"
        ),
        SearchScope(
            queryParam: "rel_syn",
            label: "Related: Synoyms",
            description: "Synonyms (words contained within the same WordNet synset)"
        ),
        SearchScope(
            queryParam: "rel_trg",
            label: "Related: Triggers",
            description: "\"Triggers]\" (words that are statistically associated with the query word in the same piece of text.)"
        ),
        SearchScope(
            queryParam: "rel_ant",
            label: "Related: Antonyms",
            description: "Antonyms (per WordNet)"
        ),
        SearchScope(
            queryParam: "rel_spc",
            label: "Related: \"Kind of\"",
            description: "\"Kind of\" (direct hypernyms, per WordNet)"
        ),
        SearchScope(
            queryParam: "rel_gen",
            label: "Related: \"More general than\"",
            description: "\"More general than\" (direct hyponyms, per WordNet)"
        ),
        SearchScope(
            queryParam: "rel_com",
            label: "Related: \"Comprises\"",
            description: "\"Comprises\" (direct holonyms, per WordNet)"
        ),
        SearchScope(
            queryParam: "rel_par",
            label: "Related: \"Part of\"",
            description: "\"Part of\" (direct meronyms, per WordNet)"
        ),
        SearchScope(
            queryParam: "rel_bga",
            label: "Related: Frequent followers",
            description: "Frequent followers (w′ such that P(w′|w) ≥ 0.001, per Google Books Ngrams)"
        ),
        SearchScope(
            queryParam: "rel_bgb",
            label: "Related: Frequent predecessors",
            description: "Frequent predecessors (w′ such that P(w|w′) ≥ 0.001, per Google Books Ngrams)"
        ),
        SearchScope(
            queryParam: "rel_hom",
            label: "Related: Homophones",
            description: "Homophones (sound-alike words)"
        ),
        SearchScope(
            queryParam: "rel_cns",
            label: "Related: Consonant match",
            description: "Consonant match"
        ),
    ]

}

