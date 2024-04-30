//
//  LargeNavigationBarTitleDisplayMode.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI

extension View {
    func largeNavigationBarTitleDisplayMode() -> some View {
        modifier(LargeNavigationBarTitleDisplayMode())
    }
}

struct LargeNavigationBarTitleDisplayMode: ViewModifier {
    func body(content: Content) -> some View {
#if os(macOS)
        content
#else
        content
            .navigationBarTitleDisplayMode(.large)
#endif
    }
}

#Preview {
    Text("Hello, world!")
        .largeNavigationBarTitleDisplayMode()
}
