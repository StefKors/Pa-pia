//
//  UIKitBridge.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

#if os(iOS)
import SwiftUI

/// Wraps the UIKit root view controller so it can be embedded in the
/// SwiftUI `WindowGroup` on iOS.
struct iOSRootView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> iOSRootViewController {
        iOSRootViewController()
    }

    func updateUIViewController(_ uiViewController: iOSRootViewController, context: Context) {}
}
#endif
