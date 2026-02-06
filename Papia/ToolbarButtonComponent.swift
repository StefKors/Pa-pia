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
        .frame(width: 36, height: 36)
        .modifier(PrimaryButtonModifier())
        .accessibilityIdentifier("\(label) \(shortexplainer)")
        .help(explainer)
    }
    
    private func insertLabel() {
        guard !model.searchText.isEmpty else {
            model.searchText = label
            let endIndex = model.searchText.endIndex
            model.searchTextSelection = TextSelection(insertionPoint: endIndex)
            return
        }

        if let selection = model.searchTextSelection {
            let range: Range<String.Index>? = {
                switch selection.indices {
                case .selection(let r): return r
                case .multiSelection(let rs): return rs.ranges.last
                @unknown default: return nil
                }
            }()

            if let range,
               range.lowerBound >= model.searchText.startIndex,
               range.upperBound <= model.searchText.endIndex {
                let offset = model.searchText.distance(from: model.searchText.startIndex, to: range.lowerBound)
                model.searchText.replaceSubrange(range, with: label)
                let newIndex = model.searchText.index(model.searchText.startIndex, offsetBy: offset + label.count)
                model.searchTextSelection = TextSelection(insertionPoint: newIndex)
            } else {
                model.searchText += label
                let endIndex = model.searchText.endIndex
                model.searchTextSelection = TextSelection(insertionPoint: endIndex)
            }
        } else {
            model.searchText += label
            let endIndex = model.searchText.endIndex
            model.searchTextSelection = TextSelection(insertionPoint: endIndex)
        }
    }
}

// MARK: - Platform Button

#if canImport(UIKit)
struct PlatformButton: UIViewRepresentable {
    let label: String
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    private static let buttonSize: CGFloat = 36
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(label, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.6
        
        // Fixed circular size
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Self.buttonSize),
            button.heightAnchor.constraint(equalToConstant: Self.buttonSize)
        ])
        
        // Make it circular
        button.layer.cornerRadius = Self.buttonSize / 2
        button.clipsToBounds = true
        button.configuration = .glass()

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
        button.font = NSFont.preferredFont(forTextStyle: .body)
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
