//
//  PrimaryButtonModifier.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), #available(macOS 26.0, *) {
            content
                .buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.borderedProminent)
        }
    }
}