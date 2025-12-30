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
                if let searchTextSelection = model.searchTextSelection {
                    let indices = searchTextSelection.indices
                    switch indices {
                    case .selection(let range):
                        // Calculate insertion position as integer offset before mutation
                        let insertionOffset = self.model.searchText.distance(from: self.model.searchText.startIndex, to: range.lowerBound)
                        self.model.searchText.replaceSubrange(range, with: self.label)
                        // Position cursor after the inserted text
                        let newCursorOffset = insertionOffset + self.label.count
                        let newCursorIndex = self.model.searchText.index(self.model.searchText.startIndex, offsetBy: newCursorOffset)
                        model.searchTextSelection = TextSelection(insertionPoint: newCursorIndex)
                    case .multiSelection(let rangeSet):
                        if let range = rangeSet.ranges.last {
                            let insertionOffset = self.model.searchText.distance(from: self.model.searchText.startIndex, to: range.lowerBound)
                            self.model.searchText.replaceSubrange(range, with: self.label)
                            let newCursorOffset = insertionOffset + self.label.count
                            let newCursorIndex = self.model.searchText.index(self.model.searchText.startIndex, offsetBy: newCursorOffset)
                            model.searchTextSelection = TextSelection(insertionPoint: newCursorIndex)
                        }
                    @unknown default:
                        self.model.searchText += self.label
                    }
                } else {
                    self.model.searchText += self.label
                }
            },
            label: {
                Text(label)
                    .padding(4)
            }
        )
        .help(explainer)
        .font(.callout)
        .modifier(PrimaryButtonModifier())
        .fixedSize()
    }
}
