//
//  WordListDatabase.swift
//  Pápia
//
//  Created by Stef Kors on 30/12/2024.
//

import Foundation
import GRDB
import os

private let logger = Logger(subsystem: "com.stefkors.Papia", category: "WordListDatabase")

/// A singleton database manager for word list lookups using SQLite
actor WordListDatabase {
    static let shared = WordListDatabase()
    
    private var dbQueue: DatabaseQueue?
    private var isInitialized = false
    
    /// The scrabble dictionary that was used to build the current database.
    private var loadedDictionary: ScrabbleDictionary?
    
    /// Separate database for user data (search history) that survives
    /// word-list rebuilds.
    private var userDbQueue: DatabaseQueue?
    
    private init() {}
    
    /// Initialize the database and load word lists if needed.
    func initialize() async throws {
        let selected = Self.selectedScrabbleDictionary
        guard !isInitialized || loadedDictionary != selected else { return }
        
        let dbQueue = try await setupDatabase()
        self.dbQueue = dbQueue
        self.isInitialized = true
        self.loadedDictionary = selected
    }
    
    /// Re‑initialize the database when the user changes the scrabble dictionary.
    func rebuildIfNeeded() async throws {
        let selected = Self.selectedScrabbleDictionary
        guard loadedDictionary != selected else { return }
        isInitialized = false
        try await initialize()
    }
    
    /// Read the user's preferred scrabble dictionary from UserDefaults.
    static var selectedScrabbleDictionary: ScrabbleDictionary {
        guard let raw = UserDefaults.standard.string(forKey: "selected-scrabble-dictionary"),
              let dict = ScrabbleDictionary(rawValue: raw) else {
            return .default
        }
        return dict
    }
    
    /// Check if a word exists in the wordle list
    func isWordle(_ word: String) async -> Bool {
        guard let dbQueue else { return false }
        let lowercased = word.lowercased()
        
        return (try? await dbQueue.read { db in
            try WordEntry
                .filter(Column("word") == lowercased && Column("isWordle") == true)
                .fetchCount(db) > 0
        }) ?? false
    }
    
    /// Check if a word exists in the scrabble list
    func isScrabble(_ word: String) async -> Bool {
        guard let dbQueue else { return false }
        let lowercased = word.lowercased()
        
        return (try? await dbQueue.read { db in
            try WordEntry
                .filter(Column("word") == lowercased && Column("isScrabble") == true)
                .fetchCount(db) > 0
        }) ?? false
    }
    
    /// Check if a word exists in the common bongo list
    func isCommonBongo(_ word: String) async -> Bool {
        guard let dbQueue else { return false }
        let lowercased = word.lowercased()
        
        return (try? await dbQueue.read { db in
            try WordEntry
                .filter(Column("word") == lowercased && Column("isCommonBongo") == true)
                .fetchCount(db) > 0
        }) ?? false
    }
    
    /// Batch lookup for multiple words - returns a dictionary of word -> flags
    func lookupWords(_ words: [String]) async -> [String: WordFlags] {
        guard let dbQueue else { return [:] }
        
        let lowercasedWords = words.map { $0.lowercased() }
        
        return (try? await dbQueue.read { db in
            let entries = try WordEntry
                .filter(lowercasedWords.contains(Column("word")))
                .fetchAll(db)
            
            var result: [String: WordFlags] = [:]
            for entry in entries {
                let existing = result[entry.word] ?? WordFlags()
                result[entry.word] = WordFlags(
                    isWordle: existing.isWordle || entry.isWordle,
                    isScrabble: existing.isScrabble || entry.isScrabble,
                    isCommonBongo: existing.isCommonBongo || entry.isCommonBongo
                )
            }
            return result
        }) ?? [:]
    }
    
    // MARK: - Search History (separate database, survives word-list rebuilds)

    /// Ensure the user database (search history) is set up.
    private func ensureUserDatabase() async throws -> DatabaseQueue {
        if let userDbQueue { return userDbQueue }

        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let papiaDirectory = appSupportURL.appendingPathComponent("Papia", isDirectory: true)
        try fileManager.createDirectory(at: papiaDirectory, withIntermediateDirectories: true)

        let dbURL = papiaDirectory.appendingPathComponent("user_data.sqlite")
        let db = try DatabaseQueue(path: dbURL.path)

        try await db.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS search_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    query TEXT NOT NULL UNIQUE,
                    timestamp REAL NOT NULL
                )
            """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_search_history_timestamp
                ON search_history(timestamp)
            """)
        }

        self.userDbQueue = db
        return db
    }

    /// Add or update a search history entry with the current timestamp.
    func addSearchHistoryEntry(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let db = try? await ensureUserDatabase() else { return }
        let now = Date().timeIntervalSince1970

        try? await db.write { db in
            // INSERT OR REPLACE to upsert — updates timestamp for existing queries
            try db.execute(
                sql: """
                    INSERT INTO search_history (query, timestamp) VALUES (?, ?)
                    ON CONFLICT(query) DO UPDATE SET timestamp = excluded.timestamp
                """,
                arguments: [trimmed, now]
            )
        }
    }

    /// Fetch recent search history, pruning entries older than `maxAgeDays`.
    func fetchSearchHistory(limit: Int = 50, maxAgeDays: Int = 30) async -> [String] {
        guard let db = try? await ensureUserDatabase() else { return [] }

        let cutoff = Date().timeIntervalSince1970 - Double(maxAgeDays * 86400)

        // Prune old entries
        try? await db.write { db in
            try db.execute(
                sql: "DELETE FROM search_history WHERE timestamp < ?",
                arguments: [cutoff]
            )
        }

        // Fetch most recent entries
        return (try? await db.read { db in
            try String.fetchAll(db, sql: """
                SELECT query FROM search_history
                WHERE timestamp >= ?
                ORDER BY timestamp DESC
                LIMIT ?
            """, arguments: [cutoff, limit])
        }) ?? []
    }

    // MARK: - Private
    
    private func setupDatabase() async throws -> DatabaseQueue {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        // Create app-specific subdirectory
        let papiaDirectory = appSupportURL.appendingPathComponent("Papia", isDirectory: true)
        try fileManager.createDirectory(at: papiaDirectory, withIntermediateDirectories: true)
        
        let dbURL = papiaDirectory.appendingPathComponent("wordlists.sqlite")
        
        // Encode both a schema version AND the selected dictionary into the
        // version string so the database is rebuilt whenever either changes.
        let schemaVersion = 3 // Increment when the DB schema or bundled files change
        let selected = Self.selectedScrabbleDictionary
        let currentVersionTag = "\(schemaVersion)-\(selected.rawValue)"
        let versionURL = papiaDirectory.appendingPathComponent("db_version.txt")
        let existingVersionTag = try? String(contentsOf: versionURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if fileManager.fileExists(atPath: dbURL.path) && existingVersionTag == currentVersionTag {
            // Database exists and is up to date
            logger.info("Using existing database")
            return try DatabaseQueue(path: dbURL.path)
        }
        
        // Remove old database if it exists
        if fileManager.fileExists(atPath: dbURL.path) {
            try fileManager.removeItem(at: dbURL)
        }
        
        logger.info("Creating new database with scrabble dictionary: \(selected.rawValue)")
        let dbQueue = try DatabaseQueue(path: dbURL.path)
        
        try await dbQueue.write { db in
            // Create table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS words (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    word TEXT NOT NULL,
                    isWordle INTEGER NOT NULL DEFAULT 0,
                    isScrabble INTEGER NOT NULL DEFAULT 0,
                    isCommonBongo INTEGER NOT NULL DEFAULT 0
                )
            """)
            
            // Create index for fast lookups
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_word ON words(word)")
        }
        
        // Load word lists
        try await loadWordLists(into: dbQueue, scrabbleDictionary: selected)
        
        // Save version tag
        try currentVersionTag.write(to: versionURL, atomically: true, encoding: .utf8)
        
        logger.info("Database created successfully")
        return dbQueue
    }
    
    private func loadWordLists(into dbQueue: DatabaseQueue, scrabbleDictionary: ScrabbleDictionary) async throws {
        // Collect all words with their flags
        var wordFlags: [String: WordFlags] = [:]
        
        // Load Wordle words (5-letter words)
        if let url = Bundle.main.url(forResource: "wordle-La", withExtension: "txt") {
            let content = try String(contentsOf: url, encoding: .utf8)
            for line in content.components(separatedBy: .newlines) {
                let word = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !word.isEmpty {
                    var flags = wordFlags[word] ?? WordFlags()
                    flags.isWordle = true
                    wordFlags[word] = flags
                }
            }
        }
        
        // Load Scrabble words using the user's selected dictionary.
        // Word list formats vary:
        //   - sowpods.txt / twl06.txt: one word per line
        //   - NWL*.txt:  "WORD definition [tags]"
        //   - CSW*.txt:  "WORD (origin) definition [tags]" with # comment header
        // We extract just the first whitespace-delimited token as the word.
        if let url = Bundle.main.url(forResource: scrabbleDictionary.resourceName, withExtension: "txt") {
            let content = try String(contentsOf: url, encoding: .utf8)
            for line in content.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // Skip empty lines and comment lines
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                // Extract the first token (the word itself)
                let word = trimmed.split(separator: " ", maxSplits: 1).first
                    .map { String($0).lowercased() } ?? ""
                if !word.isEmpty {
                    var flags = wordFlags[word] ?? WordFlags()
                    flags.isScrabble = true
                    wordFlags[word] = flags
                }
            }
            logger.info("Loaded scrabble dictionary: \(scrabbleDictionary.label) (\(scrabbleDictionary.resourceName).txt)")
        } else {
            logger.warning("Scrabble dictionary not found in bundle: \(scrabbleDictionary.resourceName).txt")
        }
        
        // Load Bongo common words
        if let url = Bundle.main.url(forResource: "bongo-commonWords", withExtension: "txt") {
            let content = try String(contentsOf: url, encoding: .utf8)
            for line in content.components(separatedBy: .newlines) {
                let word = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !word.isEmpty {
                    var flags = wordFlags[word] ?? WordFlags()
                    flags.isCommonBongo = true
                    wordFlags[word] = flags
                }
            }
        }
        
        // Batch insert all words
        let allWordFlags = wordFlags // capture as let for Sendable safety
        try await dbQueue.write { db in
            // Use a prepared statement for efficiency
            let insertSQL = "INSERT INTO words (word, isWordle, isScrabble, isCommonBongo) VALUES (?, ?, ?, ?)"
            
            for (word, flags) in allWordFlags {
                try db.execute(
                    sql: insertSQL,
                    arguments: [word, flags.isWordle, flags.isScrabble, flags.isCommonBongo]
                )
            }
        }
    }
}

// MARK: - Models

struct WordFlags {
    var isWordle: Bool = false
    var isScrabble: Bool = false
    var isCommonBongo: Bool = false
}

/// GRDB record for word entries
struct WordEntry: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "words"
    
    var id: Int64?
    var word: String
    var isWordle: Bool
    var isScrabble: Bool
    var isCommonBongo: Bool
}

