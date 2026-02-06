//
//  WildcardToolbarView.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

#if os(iOS)
import UIKit

/// A horizontal row of wildcard character buttons (*, @, ?, etc.)
/// that insert characters into a target `UITextField` at the caret position.
///
/// Uses raw UIViews with tap gesture recognizers — NOT UIButton or UIControl —
/// so there is zero interference with the responder chain. The search text
/// field stays first responder at all times.
final class WildcardToolbarView: UIView {

    /// Closure that resolves the *current* search text field.
    /// UISearchController replaces its text field when it becomes active,
    /// so a stored weak reference goes stale. This closure always returns
    /// the live text field.
    var resolveTextField: (() -> UITextField?)?

    /// Convenience accessor.
    private var targetTextField: UITextField? { resolveTextField?() }

    // MARK: - Button Definitions

    private struct WildcardDef {
        let label: String
        let explainer: String
    }

    private static let defs: [WildcardDef] = [
        .init(label: "*",  explainer: "The asterisk (*) matches any number of letters. An asterisk can match zero letters, too."),
        .init(label: "@",  explainer: "The at-sign (@) matches any English vowel (including \"y\")."),
        .init(label: "?",  explainer: "The question mark (?) matches exactly one letter."),
        .init(label: ",",  explainer: "The comma (,) lets you combine multiple patterns into one."),
        .init(label: "-",  explainer: "A minus sign (-) followed by some letters means \"exclude these letters\"."),
        .init(label: "+",  explainer: "A plus sign (+) followed by some letters means \"restrict to these letters\"."),
        .init(label: "//", explainer: "Use double-slashes (//) before letters to unscramble them (find anagrams)."),
    ]

    // MARK: - UI

    private let buttonsStack = UIStackView()
    private let explainerLabel = UILabel()
    private let containerStack = UIStackView()
    private static let keySize: CGFloat = 36

    /// Saved caret position — captured in touchesBegan before the gesture
    /// recognizer fires and the text field potentially loses first responder.
    private var savedSelectedRange: UITextRange?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup

    private func setupUI() {
        containerStack.axis = .vertical
        containerStack.alignment = .center
        containerStack.spacing = 8
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Explainer (hidden by default)
        explainerLabel.font = .preferredFont(forTextStyle: .footnote)
        explainerLabel.textColor = .secondaryLabel
        explainerLabel.numberOfLines = 0
        explainerLabel.textAlignment = .center
        explainerLabel.isHidden = true
        containerStack.addArrangedSubview(explainerLabel)

        // Buttons row
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 4
        buttonsStack.alignment = .center
        buttonsStack.distribution = .fillEqually
        containerStack.addArrangedSubview(buttonsStack)

        for (index, def) in Self.defs.enumerated() {
            let keyView = makeKeyView(def: def, tag: index)
            buttonsStack.addArrangedSubview(keyView)
        }
    }

    private func makeKeyView(def: WildcardDef, tag: Int) -> NonStealingButton {
        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            config = .glass()
        } else {
            config = .plain()
            config.background.backgroundColor = UIColor.tertiarySystemFill
        }
        config.cornerStyle = .capsule
        config.title = def.label
        config.baseForegroundColor = .label
        config.contentInsets = .zero
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .body)
            return out
        }

        let button = NonStealingButton(configuration: config)
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
        let w = button.widthAnchor.constraint(equalToConstant: Self.keySize)
        let h = button.heightAnchor.constraint(equalToConstant: Self.keySize)
        w.priority = .defaultHigh
        h.priority = .defaultHigh
        NSLayoutConstraint.activate([w, h])

        // Tap action
        button.addAction(UIAction { [weak self] action in
            guard let btn = action.sender as? UIView else { return }
            self?.animatePress(btn)
            self?.insertTextAtCaret(def.label)
        }, for: .touchUpInside)

        // Long press for explainer
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(keyLongPressed(_:)))
        longPress.minimumPressDuration = 0.4
        button.addGestureRecognizer(longPress)

        return button
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Capture the caret position *before* the gesture recognizer fires
        // and the UISearchController potentially resigns the text field.
        savedSelectedRange = targetTextField?.selectedTextRange
        super.touchesBegan(touches, with: event)
    }

    // MARK: - Actions

    @objc private func keyLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let keyView = gesture.view else { return }
        let def = Self.defs[keyView.tag]

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIView.animate(withDuration: 0.2) {
            if self.explainerLabel.text == def.explainer && !self.explainerLabel.isHidden {
                self.explainerLabel.isHidden = true
            } else {
                self.explainerLabel.text = def.explainer
                self.explainerLabel.isHidden = false
            }
            self.layoutIfNeeded()
        }
    }

    // MARK: - Text Insertion

    private func insertTextAtCaret(_ text: String) {
        guard let tf = targetTextField, tf.isFirstResponder else {
            // If the text field isn't first responder, make it so first,
            // then insert on the next run loop tick after the keyboard is up.
            targetTextField?.becomeFirstResponder()
            let textToInsert = text
            DispatchQueue.main.async { [weak self] in
                self?.doInsert(textToInsert)
            }
            return
        }

        doInsert(text)
    }

    private func doInsert(_ text: String) {
        guard let tf = targetTextField else { return }

        // Restore the caret position that was saved in touchesBegan.
        if let savedRange = savedSelectedRange {
            tf.selectedTextRange = savedRange
            savedSelectedRange = nil
        }

        // UITextInput.insertText inserts at the current caret position.
        tf.insertText(text)

        // Notify UISearchController of the change
        tf.sendActions(for: .editingChanged)
    }

    // MARK: - Visual Feedback

    private func animatePress(_ view: UIView) {
        UIView.animate(withDuration: 0.08, animations: {
            view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            view.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.08) {
                view.transform = .identity
                view.alpha = 1.0
            }
        }
    }
}
#endif
