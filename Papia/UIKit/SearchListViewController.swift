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
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Find words..."
        sc.searchBar.delegate = self
        // Scope bar via the search bar
        sc.searchBar.scopeButtonTitles = viewModel.globalSearchScopes.map(\.label)
        sc.searchBar.showsScopeBar = true
        return sc
    }()

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, DataMuseWord>!

    private lazy var filterBar: FilterBarView = {
        FilterBarView(viewModel: viewModel)
    }()

    private lazy var wildcardToolbar: WildcardToolbarView = {
        let toolbar = WildcardToolbarView()
        toolbar.targetTextField = searchController.searchBar.searchTextField
        return toolbar
    }()

    private lazy var emptyStateHost: UIHostingController<EmptyStateWrapper> = {
        let host = UIHostingController(rootView: EmptyStateWrapper(viewModel: viewModel, interfaceState: interfaceState, onSettings: { [weak self] in
            self?.presentSettings()
        }))
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
        title = "Pápia"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        setupCollectionView()
        setupFilterBar()
        setupWildcardToolbar()
        setupEmptyState()
        bindViewModel()

        // Select the default scope in the search bar
        if let index = viewModel.globalSearchScopes.firstIndex(of: viewModel.searchScope) {
            searchController.searchBar.selectedScopeButtonIndex = index
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

    // MARK: - Filter Bar Setup

    private func setupFilterBar() {
        filterBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterBar)

        NSLayoutConstraint.activate([
            filterBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filterBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterBar.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            filterBar.heightAnchor.constraint(equalToConstant: 36),
        ])

        // Push collection view content below filter bar
        collectionView.contentInset.top = 44
        collectionView.verticalScrollIndicatorInsets.top = 44
    }

    // MARK: - Wildcard Toolbar Setup

    private func setupWildcardToolbar() {
        wildcardToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wildcardToolbar)

        NSLayoutConstraint.activate([
            wildcardToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wildcardToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wildcardToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
        ])

        // Push collection view content above wildcard toolbar
        collectionView.contentInset.bottom = 60
        collectionView.verticalScrollIndicatorInsets.bottom = 60
    }

    // MARK: - Empty State Setup

    private func setupEmptyState() {
        addChild(emptyStateHost)
        view.addSubview(emptyStateHost.view)
        emptyStateHost.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateHost.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            emptyStateHost.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateHost.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateHost.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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

        // Update the hosted SwiftUI view
        emptyStateHost.rootView = EmptyStateWrapper(
            viewModel: viewModel,
            interfaceState: interfaceState,
            onSettings: { [weak self] in self?.presentSettings() }
        )
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

    // MARK: - Navigation

    private func pushWordDetail(_ word: DataMuseWord) {
        interfaceState.navigation.append(word)
        let detailView = WordDetailView(word: word)
            .environmentObject(viewModel)
            .environmentObject(interfaceState)
        let host = UIHostingController(rootView: detailView)
        host.title = word.word.capitalized
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

// MARK: - UISearchBarDelegate

extension SearchListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let scopes = viewModel.globalSearchScopes
        guard selectedScope < scopes.count else { return }
        viewModel.searchScope = scopes[selectedScope]
    }

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

/// A lightweight SwiftUI wrapper for the empty/no-results state,
/// bridging to the existing SearchContentUnavailableView.
private struct EmptyStateWrapper: View {
    let viewModel: DataMuseViewModel
    let interfaceState: InterfaceState
    let onSettings: () -> Void

    @FocusState private var searchIsFocused: Bool

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
