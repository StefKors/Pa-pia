//
//  GlassEffectModifier.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
#if os(macOS) || os(iOS)
        
        content
            .glassEffect()
#else
        content
            .background(.quinary, in: Capsule(style: .continuous))
#endif
    }
}
