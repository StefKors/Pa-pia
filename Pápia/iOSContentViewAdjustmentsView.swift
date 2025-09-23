//
//  iOSContentViewAdjustmentsView.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

struct iOSContentViewAdjustmentsView: ViewModifier {
    let searchResultsCount: Int
    let searchText: String
    let searchIsFocused: FocusState<Bool>.Binding
    let searchHistoryItems: [DataMuseWord]
    func body(content: Content) -> some View {
#if os(macOS)
        content
#else
        content
            .navigationBarTitleDisplayMode(.large)
            .searchContentUnavailableView(
                searchResultsCount: searchResultsCount,
                searchText: searchText,
                searchIsFocused: searchIsFocused,
                searchHistoryItems: searchHistoryItems
            )
#endif
    }
}
