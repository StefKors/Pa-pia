//
//  ScrollEdgeEffectModifier.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct ScrollEdgeEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(visionOS)
        content
        #else
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            content
        }
        #endif
    }
}
