//
//  HighlightAttribute.swift
//  Papia
//
//  Created by Stef Kors on 29/01/2025.
//  from: https://alexanderweiss.dev/blog/2024-06-24-using-textrenderer-to-create-highlighted-text

import SwiftUI

extension String {
    /// Find all ranges of the given substring
    ///
    /// - Parameters:
    ///   - substring: The substring to find ranges for
    ///   - options: Compare options
    ///   - locale: Locale used for finding
    /// - Returns: Array of all ranges of the substring
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let range = range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale) {
            ranges.append(range)
        }
        return ranges
    }


    /// Find all remaining ranges given `ranges`
    ///
    /// - Parameters:
    ///   - ranges: A set of ranges
    /// - Returns: All the ranges that are not part of `ranges`
    func remainingRanges(from ranges: [Range<Index>]) -> [Range<Index>] {
        var result = [Range<Index>]()

        // Sort the input ranges to process them in order
        let sortedRanges = ranges.sorted { $0.lowerBound < $1.lowerBound }

        // Start from the beginning of the string
        var currentIndex = self.startIndex

        for range in sortedRanges {
            if currentIndex < range.lowerBound {
                // Add the range from currentIndex to the start of the current range
                result.append(currentIndex..<range.lowerBound)
            }

            // Move currentIndex to the end of the current range
            currentIndex = range.upperBound
        }

        // If there's remaining text after the last range, add it as well
        if currentIndex < self.endIndex {
            result.append(currentIndex..<self.endIndex)
        }

        return result
    }
}

extension Text.Layout {
    /// A helper function for easier access to all runs in a layout.
    var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
        self.flatMap { line in
            line
        }
    }
}

struct HighlightAttribute: TextAttribute {}

struct HighlightTextRenderer: TextRenderer {

    // MARK: - Private Properties
    private let style: any ShapeStyle

    // MARK: - Initializer
    init(style: any ShapeStyle = .yellow) {
        self.style = style
    }

    // MARK : - TextRenderer
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for run in layout.flattenedRuns {
            if run[HighlightAttribute.self] != nil {

                // The rect of the current run
                let rect = run.typographicBounds.rect
                // with a little spacing for style
                    .insetBy(dx: -2, dy: 0)

                // Make a copy of the context so that individual slices
                // don't affect each other.
                let copy = context

                // Shape of the highlight, can be customised
                let shape = RoundedRectangle(cornerRadius: 4, style: .continuous).path(in: rect)

                // Style the shape
                copy.fill(shape, with: .style(style))

                // Draw
                copy.draw(run)
            } else {
                let copy = context
                copy.draw(run)
            }
        }
    }
}

struct HighlightedText: View {

    // MARK: - Private Properties
    private let text: String
    private let highlightedText: String?
    private let shapeStyle: (any ShapeStyle)?

    // MARK: - Initializer
    init(text: String, highlightedText: String? = nil, shapeStyle: (any ShapeStyle)? = nil) {
        self.text = text
        self.highlightedText = highlightedText
        self.shapeStyle = shapeStyle
    }

    // MARK: - Body
    var body: some View {
        if let highlightedText, !highlightedText.isEmpty {
            let text = highlightedTextComponent(from: highlightedText).reduce(Text("")) { partialResult, component in
                return partialResult + component.text
            }
            text.textRenderer(HighlightTextRenderer(style: shapeStyle ?? .yellow))
        } else {
            Text(text)
        }
    }

    /// Extract the highlighted text components
    ///
    /// - Parameters
    ///     - highlight: The part to highlight
    /// - Returns: Array of highlighted text components
    private func highlightedTextComponent(from highlight: String) -> [HighlightedTextComponent] {
        let highlightRanges: [HighlightedTextComponent] = text
            .ranges(of: highlight, options: .caseInsensitive)
            .map { HighlightedTextComponent(text: Text(text[$0]).customAttribute(HighlightAttribute()), range: $0)  }

        let remainingRanges = text
            .remainingRanges(from: highlightRanges.map(\.range))
            .map { HighlightedTextComponent(text: Text(text[$0]), range: $0)  }

        return (highlightRanges + remainingRanges).sorted(by: { $0.range.lowerBound < $1.range.lowerBound  } )
    }
}

fileprivate struct HighlightedTextComponent {
    let text: Text
    let range: Range<String.Index>
}

#Preview {
    HighlightedText(text: "Hello World", highlightedText: "World", shapeStyle: .blue)
        .scenePadding()
}

#Preview {
    let highlight = Text("World")
        .customAttribute(HighlightAttribute())
    Text("Hello \(highlight)").textRenderer(HighlightTextRenderer())
        .scenePadding()
}


#Preview {
    let highlight = Text("World")
        .customAttribute(HighlightAttribute())
    Text("Editor Hello \(highlight)").textRenderer(HighlightTextRenderer(style: .tint))

    TextField("Input", text: .constant("testing"))
        .textRenderer(HighlightTextRenderer(style: .tint))
        .scenePadding()
}
