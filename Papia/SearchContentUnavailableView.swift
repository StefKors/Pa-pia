//
//  SearchContentUnavailableView.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI
import SwiftData

extension View {
    func searchContentUnavailableView(
        searchResultsCount: Int,
        totalResultsCount: Int,
        searchText: String,
        searchIsFocused: FocusState<Bool>.Binding,
        searchHistoryItems: [DataMuseWord],
        hasActiveFilters: Bool,
        onClearFilters: @escaping () -> Void,
        showSettings: Binding<Bool>
    ) -> some View {
        modifier(
            SearchContentUnavailableViewModifier(
                searchResultsCount: searchResultsCount,
                totalResultsCount: totalResultsCount,
                searchText: searchText,
                searchIsFocused: searchIsFocused,
                searchHistoryItems: searchHistoryItems,
                hasActiveFilters: hasActiveFilters,
                onClearFilters: onClearFilters,
                showSettings: showSettings
            )
        )
    }
}

struct SearchContentUnavailableViewModifier: ViewModifier {
    let searchResultsCount: Int
    let totalResultsCount: Int
    let searchText: String
    let searchIsFocused: FocusState<Bool>.Binding
    let searchHistoryItems: [DataMuseWord]
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    @Binding var showSettings: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                SearchContentUnavailableView(
                    searchResultsCount: searchResultsCount,
                    totalResultsCount: totalResultsCount,
                    searchText: searchText,
                    searchIsFocused: searchIsFocused,
                    searchHistoryItems: searchHistoryItems,
                    hasActiveFilters: hasActiveFilters,
                    onClearFilters: onClearFilters,
                    showSettings: $showSettings
                )
            }
    }
}

/// TODO: sort and filter to most recent x couple
/// TODO: open on button click
struct SearchContentUnavailableView: View {
    let searchResultsCount: Int
    let totalResultsCount: Int
    let searchText: String
    let searchIsFocused: FocusState<Bool>.Binding
    let searchHistoryItems: [DataMuseWord]
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    @Binding var showSettings: Bool

    @State private var isDragging = false
    @State private var ignoreDragging = false
    @State private var translation: CGSize = .zero
    private var pullToSearch: some Gesture {
        DragGesture()
            .onChanged { data in
                withAnimation {
                    self.isDragging = true
                    if !self.ignoreDragging {
                        // calculate height
                        let height = data.translation.height
                        if abs(height) > 100 {
                            // focus search if positive height, unfocus search if negative height
                            self.searchIsFocused.wrappedValue = height > 0
                            self.ignoreDragging = true
                            self.translation = .zero
                        } else {
                            self.translation = data.translation
                        }
                    }
                }
            }
            .onEnded { _ in
                withAnimation {
                    self.isDragging = false
                    self.ignoreDragging = false
                    translation = .zero
                }
            }
    }

    var body: some View {
        if searchResultsCount == 0 {
            if !searchText.isEmpty {
                /// In case there aren't any search results, we can
                /// show the new content unavailable view.
                if #available(iOS 17.0, *) {
                    ContentUnavailableView {
                        Label("No results for \"\(searchText)\"", systemImage: "magnifyingglass")
                    } description: {
                        if shouldShowClearFilters {
                            Text("Your filters hide matching results.")
                        }
                    } actions: {
                        if shouldShowClearFilters {
                            Button("Clear filters") {
                                onClearFilters()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    Text("No results for: \(searchText)")
                    if shouldShowClearFilters {
                        Button("Clear filters") {
                            onClearFilters()
                        }
                        .buttonStyle(.bordered)
                    }
                    // Fallback on earlier versions
                }
            } else {
                Group {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView {
                            Label("Search Pápia...", systemImage: "bird.fill")
                        } description: {
                            Text("Start your search, then filter your query")
                        } actions: {
                            VStack {
                                WrappingHStack(alignment: .center) {
                                    ForEach(Array(Set(searchHistoryItems)), id: \.id) { word in
                                        NavigationLink(value: word) {
                                            Text(word.word.capitalized)
                                        }
                                        .id(word)
                                        .buttonStyle(NavigationButtonStyle())
                                    }
                                }
                                
                                Button {
                                    showSettings = true
                                } label: {
                                    Label("Settings", systemImage: "gearshape")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        VStack {
                            Label("Search Pápia...", systemImage: "bird.fill")
                            Text("Start your search, then filter your query")
                        }
                    }
                }
                .contentShape(.interaction, Rectangle(), eoFill: .init())
                .gesture(pullToSearch, name: "PullToSearch", isEnabled: true)
                .offset(y: translation.height)
                .sensoryFeedback(trigger: translation) { old, new in
                    return .impact(weight: .heavy, intensity: min((new.height / 150.0), 1.0))
                }
            }
        }
    }

    private var shouldShowClearFilters: Bool {
        totalResultsCount > 0 && hasActiveFilters
    }
}
