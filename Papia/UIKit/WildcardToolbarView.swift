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
final class WildcardToolbarView: UIView {

    /// The text field to insert characters into (the search bar's text field).
    weak var targetTextField: UITextField?

    /// Called when a button is long-pressed with the explainer string.
    var onLongPress: ((String) -> Void)?

    // MARK: - Button Definitions

    private struct WildcardButton {
        let label: String
        let shortExplainer: String
        let explainer: String
    }

    private let wildcardButtons: [WildcardButton] = [
        WildcardButton(
            label: "*",
            shortExplainer: "many",
            explainer: "The asterisk (*) matches any number of letters. An asterisk can match zero letters, too."
        ),
        WildcardButton(
            label: "@",
            shortExplainer: "any vowel",
            explainer: "The at-sign (@) matches any English vowel (including \"y\"). For example, the query abo@t finds the word \"about\" but not \"abort\"."
        ),
        WildcardButton(
            label: "?",
            shortExplainer: "any letter",
            explainer: "The question mark (?) matches exactly one letter. That means that you can use it as a placeholder for a single letter or symbol."
        ),
        WildcardButton(
            label: ",",
            shortExplainer: "combine",
            explainer: "The comma (,) lets you combine multiple patterns into one."
        ),
        WildcardButton(
            label: "-",
            shortExplainer: "exclude",
            explainer: "A minus sign (-) followed by some letters at the end of a pattern means \"exclude these letters\"."
        ),
        WildcardButton(
            label: "+",
            shortExplainer: "restrict",
            explainer: "A plus sign (+) followed by some letters at the end of a pattern means \"restrict to these letters\"."
        ),
        WildcardButton(
            label: "//",
            shortExplainer: "unscramble",
            explainer: "Use double-slashes (//) before a group of letters to unscramble them (that is, find anagrams.)"
        ),
    ]

    // MARK: - UI

    private let stackView = UIStackView()
    private let explainerLabel = UILabel()
    private let containerStack = UIStackView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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

        // Explainer label (hidden by default)
        explainerLabel.font = .preferredFont(forTextStyle: .footnote)
        explainerLabel.textColor = .secondaryLabel
        explainerLabel.numberOfLines = 0
        explainerLabel.textAlignment = .center
        explainerLabel.isHidden = true
        containerStack.addArrangedSubview(explainerLabel)

        // Buttons row
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        containerStack.addArrangedSubview(stackView)

        for (index, def) in wildcardButtons.enumerated() {
            let button = makeButton(def: def, tag: index)
            stackView.addArrangedSubview(button)
        }
    }

    private static let buttonSize: CGFloat = 36

    private func makeButton(def: WildcardButton, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(def.label, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.6
        button.tag = tag

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Self.buttonSize),
            button.heightAnchor.constraint(equalToConstant: Self.buttonSize),
        ])
        button.layer.cornerRadius = Self.buttonSize / 2
        button.clipsToBounds = true
        if #available(iOS 26.0, *) {
            button.configuration = .glass()
        } else {
            button.backgroundColor = UIColor.tertiarySystemFill
        }

        // Tap gesture (requires long press to fail first)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        button.addGestureRecognizer(longPress)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.require(toFail: longPress)
        button.addGestureRecognizer(tap)

        return button
    }

    // MARK: - Actions

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended,
              let button = gesture.view as? UIButton else { return }
        let def = wildcardButtons[button.tag]
        insertText(def.label)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let button = gesture.view as? UIButton else { return }
        let def = wildcardButtons[button.tag]

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Toggle explainer
        UIView.animate(withDuration: 0.2) {
            if self.explainerLabel.text == def.explainer && !self.explainerLabel.isHidden {
                self.explainerLabel.isHidden = true
            } else {
                self.explainerLabel.text = def.explainer
                self.explainerLabel.isHidden = false
            }
            self.layoutIfNeeded()
        }

        onLongPress?(def.explainer)
    }

    /// Insert text at the current caret position in the target text field,
    /// or append to the end if there's no selection.
    private func insertText(_ text: String) {
        guard let textField = targetTextField else { return }

        if let selectedRange = textField.selectedTextRange {
            textField.replace(selectedRange, withText: text)
        } else {
            // Fallback: append to end
            textField.text = (textField.text ?? "") + text
            // Notify delegate of the change
            textField.sendActions(for: .editingChanged)
        }
    }
}
#endif
