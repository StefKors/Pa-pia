//
//  ToolbarButtonComponent.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct ToolbarButtonComponent: View {
    let label: String
    let shortexplainer: String
    let explainer: String
    
    @EnvironmentObject private var model: DataMuseViewModel
    @State private var isLongPressed: Bool = false
    
    var body: some View {
        Button(
            action: {
                self.model.searchText.append(self.label)
            },
            label: {
                Text(label) + Text(" ") +
                Text(shortexplainer)
                    .foregroundStyle(.secondary)
                
            }
        )
        .help(explainer)
        .font(.caption)
        .modifier(PrimaryButtonModifier())
        .fixedSize()
    }
}