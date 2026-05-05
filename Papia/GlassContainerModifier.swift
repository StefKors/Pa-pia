//
//  GlassContainerModifier.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct GlassContainerModifier: ViewModifier {
    let spacing: CGFloat
    func body(content: Content) -> some View {
#if os(macOS) || os(iOS)
        GlassEffectContainer(spacing: spacing) {
            content
        }
#else
        content
#endif
    }
}
