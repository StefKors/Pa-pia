//
//  Pa_piaApp.swift
//  Papia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI
import os

private let logger = Logger(subsystem: "com.stefkors.Papia", category: "App")

@main
struct Pa_piaApp: App {
    init() {
#if os(macOS)
        // Initialize the word list database on app launch (macOS only;
        // on iOS the iOSRootViewController handles this).
        Task {
            do {
                try await WordListDatabase.shared.initialize()
            } catch {
                logger.error("Failed to initialize WordListDatabase: \(error)")
            }
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
#if os(macOS)
            ContentView()
#else
            iOSRootView()
                .ignoresSafeArea()
#endif
        }
    }
}
