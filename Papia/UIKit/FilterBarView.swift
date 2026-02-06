//
//  FilterBarView.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

#if os(iOS)
import UIKit
import Combine

/// A horizontal bar of capsule-shaped glass filter buttons (Wordle / Scrabble / Bongo).
final class FilterBarView: UIView {

    // MARK: - Properties

    private let viewModel: DataMuseViewModel
    private var cancellables = Set<AnyCancellable>()
    private var buttons: [WordFilter: NonStealingButton] = [:]

    // MARK: - Init

    init(viewModel: DataMuseViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        bindViewModel()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI Setup

    private static let barHeight: CGFloat = 32

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.barHeight),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        for filter in WordFilter.allCases {
            let button = makeFilterButton(for: filter)
            buttons[filter] = button
            stack.addArrangedSubview(button)
        }
    }

    private func makeFilterButton(for filter: WordFilter) -> NonStealingButton {
        let icon = UIImage(named: filter.imageName)?
            .withRenderingMode(.alwaysOriginal)
            .resized(to: CGSize(width: 16, height: 16))

        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            config = .glass()
        } else {
            config = .plain()
            config.background.backgroundColor = UIColor.tertiarySystemFill
        }
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        config.imagePadding = 4
        config.image = icon
        config.title = filter.label
        config.baseForegroundColor = .secondaryLabel
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .caption1)
            return out
        }

        let button = NonStealingButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.viewModel.toggleFilter(filter)
        }, for: .touchUpInside)

        button.configurationUpdateHandler = { btn in
            let active = btn.isSelected
            let tint = btn.tintColor ?? .systemBlue
            btn.configuration?.baseForegroundColor = active ? tint : .secondaryLabel
            if #unavailable(iOS 26.0) {
                btn.configuration?.background.backgroundColor = active ? tint.withAlphaComponent(0.12) : UIColor.tertiarySystemFill
            }
        }

        return button
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$activeFilters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeFilters in
                guard let self else { return }
                for filter in WordFilter.allCases {
                    self.buttons[filter]?.isSelected = activeFilters.contains(filter)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - UIImage Resize Helper

private extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
#endif
