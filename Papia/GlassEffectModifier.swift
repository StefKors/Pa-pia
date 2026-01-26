//
//  GlassEffectModifier.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), #available(macOS 26.0, *) {
            content
                .glassEffect()
        } else {
            content
                .background(.quinary, in: Capsule(style: .continuous))
        }
    }
}
