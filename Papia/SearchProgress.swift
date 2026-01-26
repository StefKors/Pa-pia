//
//  SearchProgress.swift
//  Papia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI

struct SearchProgress: View {
    var showLabel: Bool = true

    @Environment(\.isSearching) private var isSearching

    var body: some View {
        VStack {
            if isSearching {
                HStack {
                    if showLabel {
                        Text("Searching...")
                    }
                    ProgressIcon()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: Capsule())
                .shadow(radius: 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy.delay(0.3), value: isSearching)

    }
}

struct searchProgressIndicator: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                SearchProgress()
            }
    }
}

#Preview {
    Text("Hello, world!")
        .modifier(searchProgressIndicator())
}

#Preview {
    SearchProgress()
}
