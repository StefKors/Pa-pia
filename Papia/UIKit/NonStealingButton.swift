//
//  NonStealingButton.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

#if os(iOS)
import UIKit

/// A UIButton subclass that never becomes first responder,
/// so tapping it does not resign the search text field's keyboard.
final class NonStealingButton: UIButton {
    override var canBecomeFirstResponder: Bool { false }
    override var canBecomeFocused: Bool { false }
}
#endif
