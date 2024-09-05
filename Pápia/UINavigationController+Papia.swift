//
//  UINavigationController+Papia.swift
//  Pápia
//
//  Created by Stef Kors on 09/07/2024.
//
#if os(iOS)
import UIKit

/// Fix swiftUI back navigation swipe gesture
/// source: https://stackoverflow.com/questions/59921239/hide-navigation-bar-without-losing-swipe-back-gesture-in-swiftui

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
#endif
