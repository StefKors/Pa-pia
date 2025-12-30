//
//  Pa_piaApp.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI

@main
struct Pa_piaApp: App {
    init() {
        // Initialize the word list database on app launch
        Task {
            do {
                try await WordListDatabase.shared.initialize()
            } catch {
                print("Failed to initialize WordListDatabase: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
