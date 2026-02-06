//
//  DataMuseAPI.swift
//  Papia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation
import Get
import Observation
import SwiftUI
import os

private let logger = Logger(subsystem: "com.stefkors.Papia", category: "DataMuse")

private enum DataMuseClient {
    static let memoryCapacity = 32 * 1024 * 1024 // 32 MB
    static let diskCapacity = 128 * 1024 * 1024 // 128 MB
    static let cache = URLCache(
        memoryCapacity: memoryCapacity,
        diskCapacity: diskCapacity,
        diskPath: "papia_url_cache"
    )
    static let client = APIClient(baseURL: URL(string: "https://api.datamuse.com")) {
        $0.sessionConfiguration.urlCache = cache
    }
}

/// Filter options for word results
enum WordFilter: String, CaseIterable, Identifiable, Codable {
    case wordle = "wordle"
    case scrabble = "scrabble"
    case bongo = "bongo"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .wordle: return "Wordle"
        case .scrabble: return "Scrabble"
        case .bongo: return "Bongo"
        }
    }
    
    var imageName: String {
        switch self {
        case .wordle: return "Wordle"
        case .scrabble: return "Scrabble"
        case .bongo: return "Bongo"
        }
    }
}

/// https://api.datamuse.com/words?ml=tree&qe=ml&md=dpfcy&max=1&rif=1&k=olthes_r4
/// get defintions: https://api.datamuse.com/words?ml=tree&qe=ml&md=dp&max=1
@MainActor
class DataMuseViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchTextSelection: TextSelection? = nil

    /// Active filters for word results
    @Published var activeFilters: Set<WordFilter> = [] {
        didSet { recomputeFilteredResults() }
    }
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

    @Published var searchResults: [DataMuseWord] = [] {
        didSet { recomputeFilteredResults() }
    }

    /// Composite key that changes when either the search text or scope changes.
    /// Used as the `.task(id:)` identity so SwiftUI cancels and restarts the
    /// fetch whenever the user types or switches scope.
    var searchQuery: String {
        "\(searchText)\0\(searchScope.queryParam)"
    }

    var isAtMaxResultsLimit: Bool {
        searchResults.count >= maxResultsLimit
    }

    /// Filtered search results, updated whenever `searchResults` or `activeFilters` change.
    @Published private(set) var filteredSearchResults: [DataMuseWord] = []

    private func recomputeFilteredResults() {
        guard !activeFilters.isEmpty else {
            filteredSearchResults = searchResults
            return
        }

        filteredSearchResults = searchResults.filter { word in
            for filter in activeFilters {
                switch filter {
                case .wordle:
                    if !word.isWordle { return false }
                case .scrabble:
                    if !word.isScrabble { return false }
                case .bongo:
                    if !word.isCommonBongo { return false }
                }
            }
            return true
        }
    }
    
    /// Toggle a filter on or off
    func toggleFilter(_ filter: WordFilter) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
    }
    
    /// Check if a filter is active
    func isFilterActive(_ filter: WordFilter) -> Bool {
        activeFilters.contains(filter)
    }

    /// Clear all active filters
    func clearFilters() {
        activeFilters.removeAll()
    }

    private let client = DataMuseClient.client

    private let maxResultsLimit = 1000
    private let wordsMax = 1000

    func fetch(scope: SearchScope, searchText: String) async -> [DataMuseWord] {
        let list = await query(
            "/words",
            scope: scope,
            search: searchText,
            maxResults: wordsMax
        )
        return await addWordInfo(list: list)
    }

    func addWordInfo(list: [DataMuseWord]) async -> [DataMuseWord] {
        guard !list.isEmpty else {
            return list
        }

        // Use SQLite database for fast batch lookup
        let words = list.map { $0.word }
        let wordFlags = await WordListDatabase.shared.lookupWords(words)

        // Map results with all flags
        let result = list.map { word -> DataMuseWord in
            let lowercased = word.word.lowercased()
            
            if let flags = wordFlags[lowercased] {
                return DataMuseWord(
                    word: word.word,
                    score: word.score,
                    isWordle: flags.isWordle,
                    isScrabble: flags.isScrabble,
                    isCommonBongo: flags.isCommonBongo
                )
            }
            return word
        }

        return result
    }

    func definitions(search: String) async -> [DataMuseDefinition] {
        let path = "/words"

        // Normalize: trim whitespace and lowercase before sending
        let normalizedSearch = search
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // filter out empty queries
        if normalizedSearch.isEmpty {
            return []
        }

        var result: [DataMuseDefinition] = []
        do {
            result = try await client.send(
                Request(
                    path: path,
                    query: [
                        ("ml", normalizedSearch),
                        ("qe", "ml"),
                        ("md", "dp"),
                        ("max", "1"),
                    ]
                )
            ).value
        } catch is CancellationError {
            // Task was cancelled, this is expected.
        } catch {
            logger.error("Failed to fetch definitions: \(error.localizedDescription)")
        }

        return result
    }

    private func query(
        _ path: String,
        scope: SearchScope,
        search: String,
        maxResults: Int
    ) async -> [DataMuseWord] {
        // Normalize: trim whitespace and lowercase before sending
        let normalizedSearch = search
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // filter out empty queries
        if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        if scope.queryParam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        if normalizedSearch.isEmpty {
            return []
        }

        let clampedMax = min(max(maxResults, 1), maxResultsLimit)

        var result: [DataMuseWord] = []
        do {
            result = try await client.send(
                Request(
                    path: path,
                    query: [("max", String(clampedMax)), (scope.queryParam, normalizedSearch)]
                )
            ).value
        } catch is CancellationError {
            // Task was cancelled (e.g. user typed a new character), this is expected.
        } catch {
            logger.error("Query failed for \(path) with scope \(scope.queryParam): \(error.localizedDescription)")
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

        /// used as 'none' value when the ui needs an value. Often used as the id for the definition view
        static let none = SearchScope(
            queryParam: "",
            label: "empty for ui",
            description: "used as 'none' value when the ui needs an value. Often used as the id for the definition view"
        )
    }

    var globalSearchScopes: [SearchScope] {
        self.searchScopes.filter { scope in
            return !scope.queryParam.contains("rel_")
        }
    }

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
            label: "Related: Synonyms",
            description: "Synonyms (words contained within the same WordNet synset)"
        ),
        SearchScope(
            queryParam: "rel_trg",
            label: "Related: Triggers",
            description: "\"Triggers\" (words that are statistically associated with the query word in the same piece of text.)"
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

    /// Synonyms scope - displayed inline with definitions, not as a separate tab.
    /// Uses a shorter label than the one in `searchScopes` ("Related: Synonyms").
    let synonymsScope = SearchScope(
        queryParam: "rel_syn",
        label: "Synonyms",
        description: "Synonyms (words contained within the same WordNet synset)"
    )

    /// Related scopes shown as separate tabs (excludes synonyms which are shown inline).
    /// Derived from `searchScopes` to avoid duplicating definitions.
    private static let relatedScopeParams: Set<String> = [
        "rel_jja", "rel_jjb", "rel_ant", "rel_hom"
    ]

    var relatedScopes: [SearchScope] {
        searchScopes.filter { Self.relatedScopeParams.contains($0.queryParam) }
    }

}
