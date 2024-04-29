//
//  SearchProgress.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI

struct SearchProgress: View {
    let searches: [DataMuseViewModel.Search]
    var showLabel: Bool = true

    private var searchString: String {
        Array(Set(searches.map { search in
            search.scope.label
        })).joined(separator: ", ")
    }
    var body: some View {
        HStack {
            if showLabel {
                Text("Searching \(searchString)...")
            }
            ProgressIcon()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 10)
    }
}

#Preview {
    SearchProgress(searches: [DataMuseViewModel.Search.preview])
}
