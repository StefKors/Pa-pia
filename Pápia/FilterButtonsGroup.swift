//
//  FilterButtonsGroup.swift
//  Pápia
//
//  Created by Cursor on 01/01/2026.
//

import SwiftUI

struct FilterButtonsGroup: View {
    @EnvironmentObject private var model: DataMuseViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(WordFilter.allCases) { filter in
                FilterButton(filter: filter)
            }
        }
    }
}

struct FilterButton: View {
    let filter: WordFilter
    @EnvironmentObject private var model: DataMuseViewModel
    
    private var isActive: Bool {
        model.isFilterActive(filter)
    }

    private var labelContent: some View {
        HStack(spacing: 4) {
            Image(filter.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
            Text(filter.label)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var glassyLabel: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            labelContent
                .glassEffect(.regular, in: .capsule(style: .continuous))
        } else {
            labelContent
                .background(.quinary, in: Capsule(style: .continuous))
        }
    }
    
    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.16)) {
                model.toggleFilter(filter)
            }
        } label: {
            glassyLabel
                .overlay {
                    if isActive {
                        Capsule(style: .continuous)
                            .fill(.tint)
                            .opacity(0.2)
                    }
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary.opacity(0.3)),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? .primary : .secondary)
        .accessibilityLabel("\(filter.label) filter")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

#Preview {
    FilterButtonsGroup()
        .environmentObject(DataMuseViewModel())
        .padding()
}
