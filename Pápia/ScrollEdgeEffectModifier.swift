//
//  ScrollEdgeEffectModifier.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct ScrollEdgeEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), #available(macOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            content
        }
    }
}
