//
//  ResultsFooterView.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//

import SwiftUI

struct ResultsFooterView: View {
    let resultsCount: Int
    let showsMax: Bool

    var body: some View {
        Text(footerText)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }

    private var footerText: String {
        return "Returned \(resultsCount) results\(showsMax ? " (max 1000)" : "")"
    }
}

#Preview {
    ResultsFooterView(resultsCount: 250, showsMax: false)
}
