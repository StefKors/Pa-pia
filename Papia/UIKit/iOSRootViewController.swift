//
//  iOSRootViewController.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

#if os(iOS)
import UIKit
import os

private let logger = Logger(subsystem: "com.stefkors.Papia", category: "iOSRoot")

/// The root view controller on iOS. Owns the shared `DataMuseViewModel`
/// and `InterfaceState` instances and wraps a `UINavigationController`
/// containing the `SearchListViewController`.
final class iOSRootViewController: UIViewController {

    // MARK: - Shared State

    let viewModel = DataMuseViewModel()
    let interfaceState = InterfaceState()

    // MARK: - Child Controllers

    private lazy var searchListVC: SearchListViewController = {
        SearchListViewController(viewModel: viewModel, interfaceState: interfaceState)
    }()

    private lazy var navigationController_: UINavigationController = {
        let nav = UINavigationController(rootViewController: searchListVC)
        nav.navigationBar.prefersLargeTitles = false
        // Hide the navigation bar on the root screen — the search bar
        // lives in the bottom area, not in the navigation bar.
        nav.setNavigationBarHidden(true, animated: false)
        return nav
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(navigationController_)
        view.addSubview(navigationController_.view)
        navigationController_.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationController_.view.topAnchor.constraint(equalTo: view.topAnchor),
            navigationController_.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationController_.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationController_.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        navigationController_.didMove(toParent: self)

        // Initialize the word list database
        Task {
            do {
                try await WordListDatabase.shared.initialize()
            } catch {
                logger.error("Failed to initialize WordListDatabase: \(error)")
            }
        }
    }
}
#endif
