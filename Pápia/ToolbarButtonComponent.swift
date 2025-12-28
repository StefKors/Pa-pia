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
    let alignment: HorizontalAlignment

    @EnvironmentObject private var model: DataMuseViewModel
    @State private var isLongPressed: Bool = false
    
    var body: some View {
        Button(
            action: {
                if let searchTextSelection = model.searchTextSelection {
                    let indices = searchTextSelection.indices
                    print("searchTextSelection \(searchTextSelection)")
                    switch indices {
                    case .selection(let range):
                        // TODO: move selection correctly to after the newly inserted text
                        self.model.searchText.replaceSubrange(range, with: self.label)
                        model.searchTextSelection = TextSelection(insertionPoint: range.upperBound)
                    case .multiSelection(let rangeSet):
                        if let range = rangeSet.ranges.last {
                            self.model.searchText.replaceSubrange(range, with: self.label)
                        }
                    @unknown default:
                        self.model.searchText += self.label
                    }
                } else {
                    self.model.searchText += self.label
                }

//                self.model.searchText.append(self.label)
            },
            label: {
                if alignment == .leading {
                    HStack {
                        Text(label)
                        Text(shortexplainer)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }

                if alignment == .trailing {
                    HStack {
                        Text(shortexplainer)
                            .foregroundStyle(.secondary)
                        Text(label)
                    }
                    .padding(4)
                }
            }
        )
        .help(explainer)
//        .font(.caption)
        .font(.callout)
        .modifier(PrimaryButtonModifier())
        .fixedSize()
    }
}
