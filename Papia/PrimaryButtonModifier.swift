//
//  PrimaryButtonModifier.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
#if os(macOS) || os(iOS)
        content
            .buttonStyle(.glass)
#else
        content
            .buttonStyle(.borderedProminent)
#endif
    }
}
