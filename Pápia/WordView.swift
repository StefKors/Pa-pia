//
//  WordView.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI

struct WordView: View {
    let label: String
    var body: some View {
        Text(label.capitalized)
    }
}

#Preview {
    WordView(label: "Apple")
}
