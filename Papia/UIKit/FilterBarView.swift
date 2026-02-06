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
/// Observes the view model's `activeFilters` via Combine and updates visuals
/// using `configurationUpdateHandler` for reliable button state rendering.
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
        ])

        for filter in WordFilter.allCases {
            let button = makeFilterButton(for: filter)
            buttons[filter] = button
            stack.addArrangedSubview(button)
        }
    }

    private func makeFilterButton(for filter: WordFilter) -> UIButton {
        let icon = UIImage(named: filter.imageName)?
            .withRenderingMode(.alwaysOriginal)
            .resized(to: CGSize(width: 16, height: 16))

        let button = UIButton(type: .custom)
        button.tag = WordFilter.allCases.firstIndex(of: filter) ?? 0
        button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)

        // Use configurationUpdateHandler so UIKit calls us whenever
        // button.isSelected changes — no manual layer manipulation needed.
        button.configurationUpdateHandler = { btn in
            var config = UIButton.Configuration.plain()
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            config.imagePadding = 4
            config.image = icon
            config.title = filter.label
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = UIFont.preferredFont(forTextStyle: .caption1)
                return out
            }

            let tint = btn.tintColor ?? .systemBlue

            if btn.isSelected {
                config.baseForegroundColor = tint
                config.background.backgroundColor = tint.withAlphaComponent(0.12)
                config.background.strokeColor = tint
                config.background.strokeWidth = 1
            } else {
                config.baseForegroundColor = .secondaryLabel
                config.background.backgroundColor = .clear
                config.background.strokeColor = UIColor.secondaryLabel.withAlphaComponent(0.3)
                config.background.strokeWidth = 1
            }

            btn.configuration = config
        }

        // Trigger initial configuration
        button.isSelected = false
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
                        button.isSelected = activeFilters.contains(filter)
                    }
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
