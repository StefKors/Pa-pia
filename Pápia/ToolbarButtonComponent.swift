//
//  ToolbarButtonComponent.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ToolbarButtonComponent: View {
    let label: String
    let shortexplainer: String
    let explainer: String
    var onLongPress: ((String) -> Void)? = nil

    @EnvironmentObject private var model: DataMuseViewModel
    
    var body: some View {
        PlatformButton(
            label: label,
            onTap: { insertLabel() },
            onLongPress: { onLongPress?(explainer) }
        )
        .font(.callout)
        .modifier(PrimaryButtonModifier())
        .fixedSize()
        .help(explainer)
    }
    
    private func insertLabel() {
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
    }
}

// MARK: - Platform Button

#if canImport(UIKit)
struct PlatformButton: UIViewRepresentable {
    let label: String
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(label, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.configuration = .clearGlass()

        // Tap gesture - requires long press to fail first
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.require(toFail: context.coordinator.longPressGesture)
        button.addGestureRecognizer(tapGesture)
        
        // Long press gesture
        context.coordinator.longPressGesture.minimumPressDuration = 0.4
        button.addGestureRecognizer(context.coordinator.longPressGesture)
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.setTitle(label, for: .normal)
        context.coordinator.onTap = onTap
        context.coordinator.onLongPress = onLongPress
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap, onLongPress: onLongPress)
    }
    
    class Coordinator: NSObject {
        var onTap: () -> Void
        var onLongPress: () -> Void
        let longPressGesture: UILongPressGestureRecognizer
        
        init(onTap: @escaping () -> Void, onLongPress: @escaping () -> Void) {
            self.onTap = onTap
            self.onLongPress = onLongPress
            self.longPressGesture = UILongPressGestureRecognizer()
            super.init()
            self.longPressGesture.addTarget(self, action: #selector(handleLongPress))
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if gesture.state == .ended {
                onTap()
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                // Haptic feedback on long press
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onLongPress()
            }
        }
    }
}

#elseif canImport(AppKit)
struct PlatformButton: NSViewRepresentable {
    let label: String
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: label, target: context.coordinator, action: #selector(Coordinator.handleTap))
        button.bezelStyle = .inline
        button.isBordered = false
        button.font = NSFont.preferredFont(forTextStyle: .callout)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        
        // Long press gesture
        let longPressGesture = NSPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        longPressGesture.minimumPressDuration = 0.4
        button.addGestureRecognizer(longPressGesture)
        
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: Context) {
        nsView.title = label
        context.coordinator.onTap = onTap
        context.coordinator.onLongPress = onLongPress
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap, onLongPress: onLongPress)
    }
    
    class Coordinator: NSObject {
        var onTap: () -> Void
        var onLongPress: () -> Void
        
        init(onTap: @escaping () -> Void, onLongPress: @escaping () -> Void) {
            self.onTap = onTap
            self.onLongPress = onLongPress
            super.init()
        }
        
        @objc func handleTap() {
            onTap()
        }
        
        @objc func handleLongPress(_ gesture: NSPressGestureRecognizer) {
            if gesture.state == .began {
                onLongPress()
            }
        }
    }
}
#endif

