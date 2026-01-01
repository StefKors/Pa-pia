//
//  SettingsView.swift
//  Pápia
//
//  Created by Cursor on 29/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("enable-bongo-dictionary") private var enableBongoDictionary: Bool = true
    @AppStorage("enable-scrabble-english") private var enableScrabbleEnglish: Bool = true
    @AppStorage("enable-wordle-dictionary") private var enableWordleDictionary: Bool = true

    var body: some View {
        Form {
            Section {
                DictionaryToggleRow(
                    imageName: "Bongo",
                    title: "Bongo Dictionary",
                    description: "Common words used in the Bongo word game",
                    isEnabled: $enableBongoDictionary
                )
            } header: {
                DictionarySectionHeader(imageName: "Bongo", title: "Bongo")
            }

            Section {
                DictionaryToggleRow(
                    imageName: "Scrabble",
                    title: "Scrabble English Dictionary",
                    description: "Official Scrabble word list (SOWPODS)",
                    isEnabled: $enableScrabbleEnglish
                )
            } header: {
                DictionarySectionHeader(imageName: "Scrabble", title: "Scrabble")
            }

            Section {
                DictionaryToggleRow(
                    imageName: "Wordle",
                    title: "Wordle Dictionary",
                    description: "5-letter words used in Wordle",
                    isEnabled: $enableWordleDictionary
                )
            } header: {
                DictionarySectionHeader(imageName: "Wordle", title: "Wordle")
            }
        }
        .navigationTitle("Settings")
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
