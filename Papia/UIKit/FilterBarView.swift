//
//  FilterBarView.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

#if os(iOS)
import UIKit
import Combine

/// A horizontal bar of capsule-shaped filter buttons (Wordle / Scrabble / Bongo).
/// Observes the view model's `activeFilters` via Combine and updates visuals.
final class FilterBarView: UIView {

    // MARK: - Properties

    private let viewModel: DataMuseViewModel
    private var cancellables = Set<AnyCancellable>()
    private var buttons: [WordFilter: UIButton] = [:]

    // MARK: - Init

    init(viewModel: DataMuseViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        bindViewModel()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI Setup

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            // Don't pin trailing — let the stack determine its natural width
        ])

        for filter in WordFilter.allCases {
            let button = makeFilterButton(for: filter)
            buttons[filter] = button
            stack.addArrangedSubview(button)
        }
    }

    private func makeFilterButton(for filter: WordFilter) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        config.imagePadding = 4
        config.image = UIImage(named: filter.imageName)?
            .withRenderingMode(.alwaysOriginal)
            .resized(to: CGSize(width: 16, height: 16))
        config.title = filter.label
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .caption1)
            return out
        }

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        button.tag = WordFilter.allCases.firstIndex(of: filter) ?? 0
        updateButtonAppearance(button, isActive: false)
        return button
    }

    // MARK: - Actions

    @objc private func filterTapped(_ sender: UIButton) {
        let filter = WordFilter.allCases[sender.tag]
        viewModel.toggleFilter(filter)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$activeFilters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeFilters in
                guard let self else { return }
                for filter in WordFilter.allCases {
                    if let button = self.buttons[filter] {
                        self.updateButtonAppearance(button, isActive: activeFilters.contains(filter))
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func updateButtonAppearance(_ button: UIButton, isActive: Bool) {
        let tintColor = tintColor ?? .systemBlue
        button.layer.cornerRadius = button.bounds.height / 2
        button.layer.borderWidth = 1
        button.layer.borderColor = isActive ? tintColor.cgColor : UIColor.secondaryLabel.withAlphaComponent(0.3).cgColor
        button.backgroundColor = isActive ? tintColor.withAlphaComponent(0.1) : .clear
        button.tintColor = isActive ? tintColor : .secondaryLabel
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Refresh border radius after layout
        for filter in WordFilter.allCases {
            if let button = buttons[filter] {
                button.layer.cornerRadius = button.bounds.height / 2
            }
        }
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
