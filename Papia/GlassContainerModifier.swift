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
        if #available(iOS 26.0, *)  {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}
