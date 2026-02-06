//
//  SettingsView.swift
//  Pápia
//
//  Created by Cursor on 29/09/2025.
//

import SwiftUI
import os

private let logger = Logger(subsystem: "com.stefkors.Papia", category: "Settings")

struct SettingsView: View {
    @AppStorage("enable-bongo-dictionary") private var enableBongoDictionary: Bool = true
    @AppStorage("enable-scrabble-english") private var enableScrabbleEnglish: Bool = true
    @AppStorage("enable-wordle-dictionary") private var enableWordleDictionary: Bool = true

    @AppStorage("selected-scrabble-dictionary") private var selectedDictionary: String = ScrabbleDictionary.default.rawValue

    /// True while the word‑list database is being rebuilt after a dictionary change.
    @State private var isRebuilding = false

    private var selectedScrabbleDictionary: ScrabbleDictionary {
        ScrabbleDictionary(rawValue: selectedDictionary) ?? .default
    }

    var body: some View {
        Form {
            Section {
                DictionaryToggleRow(
                    imageName: "Bongo",
                    title: "Bongo Dictionary",
                    description: "Common words used in the Bongo word game",
                    isEnabled: $enableBongoDictionary
                )
                DictionaryToggleRow(
                    imageName: "Scrabble",
                    title: "Scrabble English Dictionary",
                    description: selectedScrabbleDictionary.subtitle,
                    isEnabled: $enableScrabbleEnglish
                )
                DictionaryToggleRow(
                    imageName: "Wordle",
                    title: "Wordle Dictionary",
                    description: "5-letter words used in Wordle",
                    isEnabled: $enableWordleDictionary
                )
            }

            Section {
                Picker("Scrabble Dictionary", selection: $selectedDictionary) {
                    ForEach(ScrabbleDictionaryRegion.allCases) { region in
                        Section(region.rawValue) {
                            ForEach(ScrabbleDictionary.allCases.filter { $0.region == region }) { dict in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dict.label)
                                    Text(dict.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .tag(dict.rawValue)
                            }
                        }
                    }
                }
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif

                if isRebuilding {
                    HStack(spacing: 8) {
                        ProgressView()
                            #if os(macOS)
                            .controlSize(.small)
                            #endif
                        Text("Rebuilding word list…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Scrabble Word List")
            } footer: {
                Text("Changing the dictionary will rebuild the local word database. This may take a moment.")
            }
        }
        .navigationTitle("Settings")
        .onChange(of: selectedDictionary) {
            rebuildDatabase()
        }
    }

    private func rebuildDatabase() {
        isRebuilding = true
        Task {
            do {
                try await WordListDatabase.shared.rebuildIfNeeded()
            } catch {
                logger.error("Failed to rebuild word list database: \(error)")
            }
            await MainActor.run {
                isRebuilding = false
            }
        }
    }
}

// MARK: - Dictionary Toggle Row

struct DictionaryToggleRow: View {
    let imageName: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 12) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.accentColor)
    }
}

// MARK: - Dictionary Section Header

struct DictionarySectionHeader: View {
    let imageName: String
    let title: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
            Text(title)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
