//
//  SearchListViewController.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

#if os(iOS)
import UIKit
import SwiftUI
import Combine
import os

private let logger = Logger(subsystem: "com.stefkors.Papia", category: "SearchList")

/// The main search screen on iOS. Owns:
/// - UISearchController with a real UITextField
/// - UICollectionView with diffable data source (hosting SwiftUI WordView cells)
/// - Scope segmented control + filter bar at the top
/// - Wildcard toolbar at the bottom
/// - Empty state (hosted SwiftUI SearchContentUnavailableView)
final class SearchListViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: DataMuseViewModel
    private let interfaceState: InterfaceState
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init(viewModel: DataMuseViewModel, interfaceState: InterfaceState) {
        self.viewModel = viewModel
        self.interfaceState = interfaceState
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI Components

    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Find words..."
        sc.searchBar.delegate = self
        sc.searchBar.showsScopeBar = false
        return sc
    }()

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, DataMuseWord>!

    private lazy var filterBar: FilterBarView = {
        FilterBarView(viewModel: viewModel)
    }()

    private lazy var scopeControl: UISegmentedControl = {
        let scopes = viewModel.globalSearchScopes
        let control = UISegmentedControl(items: scopes.map(\.label))
        if let index = scopes.firstIndex(of: viewModel.searchScope) {
            control.selectedSegmentIndex = index
        }
        control.addAction(UIAction { [weak self] action in
            guard let self,
                  let control = action.sender as? UISegmentedControl else { return }
            let scopes = self.viewModel.globalSearchScopes
            guard control.selectedSegmentIndex < scopes.count else { return }
            self.viewModel.searchScope = scopes[control.selectedSegmentIndex]
        }, for: .valueChanged)
        return control
    }()

    /// Combined container for the scope picker, filter buttons, and wildcard toolbar.
    private lazy var headerContainerView: UIView = {
        let container = UIView()
        container.backgroundColor = .systemGroupedBackground

        // Scope control should fill the width
        scopeControl.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [scopeControl, filterBar, wildcardToolbar])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])

        return container
    }()

    private lazy var wildcardToolbar: WildcardToolbarView = {
        let toolbar = WildcardToolbarView()
        toolbar.resolveTextField = { [weak self] in
            self?.searchController.searchBar.searchTextField
        }
        return toolbar
    }()

    private lazy var emptyStateHost: UIHostingController<EmptyStateWrapper> = {
        let host = UIHostingController(rootView: EmptyStateWrapper(
            viewModel: viewModel,
            interfaceState: interfaceState,
            onSettings: { [weak self] in self?.presentSettings() },
            onHistoryTap: { [weak self] query in self?.searchFromHistory(query) }
        ))
        host.view.backgroundColor = .clear
        return host
    }()

    private lazy var footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
        elementKind: UICollectionView.elementKindSectionFooter
    ) { [weak self] supplementaryView, elementKind, indexPath in
        guard let self else { return }
        let count = self.viewModel.searchResults.count
        let isMax = self.viewModel.isAtMaxResultsLimit
        supplementaryView.contentConfiguration = UIHostingConfiguration {
            ResultsFooterView(resultsCount: count, showsMax: isMax)
        }
    }

    // MARK: - Collection View Types

    private enum Section { case main }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        setupCollectionView()
        setupHeaderView()
        setupEmptyState()
        bindViewModel()

        // Activate search immediately so the keyboard appears on launch
        DispatchQueue.main.async {
            self.searchController.isActive = true
            self.searchController.searchBar.searchTextField.becomeFirstResponder()

        }
    }

    // MARK: - Collection View Setup

    private func setupCollectionView() {
        var listConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        listConfig.showsSeparators = true
        let layout = UICollectionViewCompositionalLayout.list(using: listConfig)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Cell registration using UIHostingConfiguration to render SwiftUI WordView
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, DataMuseWord> { cell, indexPath, word in
            cell.contentConfiguration = UIHostingConfiguration {
                WordView(word: word)
            }
            // Disclosure indicator for navigation
            cell.accessories = [.disclosureIndicator()]
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, word in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: word)
        }
    }

    // MARK: - Header View Setup (scope picker + filter buttons)

    private func setupHeaderView() {
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainerView)

        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Push collection view content below the header
        // We'll update this once layout is known; use a reasonable estimate
        collectionView.contentInset.top = 90
        collectionView.verticalScrollIndicatorInsets.top = 90
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update collection view inset to match actual header height
        let headerHeight = headerContainerView.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        if collectionView.contentInset.top != headerHeight {
            collectionView.contentInset.top = headerHeight
            collectionView.verticalScrollIndicatorInsets.top = headerHeight
        }
    }

    // (Wildcard toolbar is now part of the headerContainerView stack)

    // MARK: - Empty State Setup

    private func setupEmptyState() {
        addChild(emptyStateHost)
        view.addSubview(emptyStateHost.view)
        emptyStateHost.view.translatesAutoresizingMaskIntoConstraints = false

        let bottom = emptyStateHost.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottom.priority = .defaultHigh  // avoid fighting with header intrinsic size

        NSLayoutConstraint.activate([
            emptyStateHost.view.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            emptyStateHost.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateHost.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom,
        ])
        emptyStateHost.didMove(toParent: self)
        emptyStateHost.view.isHidden = false
    }

    // MARK: - Combine Bindings

    private func bindViewModel() {
        // Update collection view when filtered results change
        viewModel.$filteredSearchResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.applySnapshot(results: results)
                self?.updateEmptyState()
            }
            .store(in: &cancellables)

        // Trigger fetch on search text or scope change (with debounce)
        viewModel.$searchText
            .combineLatest(viewModel.$searchScope)
            .debounce(for: .milliseconds(120), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText, scope in
                self?.performSearch(text: searchText, scope: scope)
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(results: [DataMuseWord]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, DataMuseWord>()
        snapshot.appendSections([.main])
        snapshot.appendItems(results, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateEmptyState() {
        let hasResults = !viewModel.filteredSearchResults.isEmpty
        emptyStateHost.view.isHidden = hasResults
        collectionView.isHidden = !hasResults
    }

    private func performSearch(text: String, scope: DataMuseViewModel.SearchScope) {
        // Cancel previous search
        searchTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewModel.searchResults = []
            return
        }

        searchTask = Task { @MainActor in
            let results = await viewModel.fetch(scope: scope, searchText: text)
            guard !Task.isCancelled else { return }
            viewModel.searchResults = results
        }
    }

    /// Set the search bar text from a history item and trigger a search.
    private func searchFromHistory(_ query: String) {
        searchController.searchBar.text = query
        searchController.isActive = true
        viewModel.searchText = query
    }

    // MARK: - Navigation

    private func pushWordDetail(_ word: DataMuseWord) {
        interfaceState.navigation.append(word)
        let detailView = WordDetailView(word: word)
            .environmentObject(viewModel)
            .environmentObject(interfaceState)
        let host = UIHostingController(rootView: detailView)
        navigationController?.pushViewController(host, animated: true)
    }

    private func presentSettings() {
        let settingsView = NavigationStack {
            SettingsView()
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { [weak self] in
                            self?.dismiss(animated: true)
                        }
                    }
                }
        }
        let host = UIHostingController(rootView: settingsView)
        host.modalPresentationStyle = .formSheet
        present(host, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension SearchListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text ?? ""
    }
}

// MARK: - UISearchControllerDelegate

extension SearchListViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        // Re-activate immediately so the navigation bar layout never changes
        // and the header/filter bar don't jump.
        searchController.isActive = true
    }
}

// MARK: - UISearchBarDelegate

extension SearchListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !text.isEmpty {
            interfaceState.appendSearchHistory(text)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension SearchListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let word = dataSource.itemIdentifier(for: indexPath) else { return }
        pushWordDetail(word)
    }
}

// MARK: - Empty State SwiftUI Wrapper

/// A lightweight SwiftUI wrapper for the empty/no-results state.
/// Uses @ObservedObject so it reacts to changes in search history,
/// search results, and active filters.
private struct EmptyStateWrapper: View {
    @ObservedObject var viewModel: DataMuseViewModel
    @ObservedObject var interfaceState: InterfaceState
    let onSettings: () -> Void
    var onHistoryTap: ((String) -> Void)?

    var body: some View {
        Group {
            if viewModel.filteredSearchResults.isEmpty {
                if !viewModel.searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No results for \"\(viewModel.searchText)\"", systemImage: "magnifyingglass")
                    } description: {
                        if !viewModel.activeFilters.isEmpty && !viewModel.searchResults.isEmpty {
                            Text("Your filters hide matching results.")
                        }
                    } actions: {
                        if !viewModel.activeFilters.isEmpty && !viewModel.searchResults.isEmpty {
                            Button("Clear filters") {
                                viewModel.clearFilters()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Search Pápia...", systemImage: "bird.fill")
                    } description: {
                        Text("Start your search, then filter your query")
                    } actions: {
                        if !interfaceState.searchHistory.isEmpty {
                            WrappingHStack(alignment: .center) {
                                ForEach(interfaceState.searchHistory.prefix(10), id: \.self) { query in
                                    Button {
                                        onHistoryTap?(query)
                                    } label: {
                                        Text(query)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.secondary)
                                }
                            }
                        }

                        Button {
                            onSettings()
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}
#endif
