//
//  SettingsView.swift
//  Pápia
//
//  Created by Cursor on 29/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("enable-wordle-dictionary") private var enableWordleDictionary: Bool = true
    @AppStorage("enable-scrabble-english") private var enableScrabbleEnglish: Bool = true
    @AppStorage("enable-scrabble-other") private var enableScrabbleOtherLanguages: Bool = false

    var body: some View {
        Form {
            Section("Wordle") {
                Toggle("Enable Wordle dictionary", isOn: $enableWordleDictionary)
            }

            Section("Scrabble") {
                Toggle("Enable Scrabble English dictionaries", isOn: $enableScrabbleEnglish)
                Toggle("Enable Scrabble other languages", isOn: $enableScrabbleOtherLanguages)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}


