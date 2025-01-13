//
//  SearchContentUnavailableView.swift
//  Pápia
//
//  Created by Stef Kors on 30/04/2024.
//

import SwiftUI
import SwiftData

extension View {
  func searchContentUnavailableView(searchResultsCount: Int, searchText: String, searchIsFocused: FocusState<Bool>.Binding) -> some View {
    modifier(
      SearchContentUnavailableViewModifier(
        searchResultsCount: searchResultsCount,
        searchText: searchText,
        searchIsFocused: searchIsFocused
      )
    )
  }
}

struct SearchContentUnavailableViewModifier: ViewModifier {
  let searchResultsCount: Int
  let searchText: String
  let searchIsFocused: FocusState<Bool>.Binding

  func body(content: Content) -> some View {
    content
      .overlay {
        SearchContentUnavailableView(
          searchResultsCount: searchResultsCount,
          searchText: searchText,
          searchIsFocused: searchIsFocused
        )
      }
  }
}

/// TODO: sort and filter to most recent x couple
/// TODO: open on button click
struct SearchContentUnavailableView: View {
  let searchResultsCount: Int
  let searchText: String
  let searchIsFocused: FocusState<Bool>.Binding

  @State private var isDragging = false
  @State private var ignoreDragging = false
  @State private var translation: CGSize = .zero
  private var pullToSearch: some Gesture {
    DragGesture()
      .onChanged { data in
        withAnimation {
          self.isDragging = true
          if !self.ignoreDragging {
            if data.translation.height > 100 {
              self.searchIsFocused.wrappedValue = true
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
          ContentUnavailableView.search(text: searchText)
        } else {
          Text("No results for: \(searchText)")
          // Fallback on earlier versions
        }
      } else {
        Group {
          if #available(iOS 17.0, *) {
            ContentUnavailableView {
              Label("Search Pápia...", systemImage: "bird.fill")
            } description: {
              Text("Start your search, then filter your query")
            } actions: {
              //                    WrappingHStack {
              //                        ForEach(searchHistoryItems) { item in
              //                            Button {
              //                                /// todo: open
              //                            } label: {
              //                                WordView(label: item.word.word)
              //                            }
              //                            .foregroundStyle(.primary)
              //                            .padding(.horizontal, 12)
              //                            .padding(.vertical, 4)
              //                            .background(.tint, in: Capsule())
              //                        }
              //                    }
            }
          } else {
            VStack {
              Label("Search Pápia...", systemImage: "bird.fill")
              Text("Start your search, then filter your query")
            }
          }
        }
        .contentShape(.interaction, Rectangle(), eoFill: .init())
        .border(.red)
        .gesture(pullToSearch, name: "PullToSearch", isEnabled: true)
        .offset(y: translation.height)
        .sensoryFeedback(trigger: translation) { old, new in
            return .impact(weight: .heavy, intensity: min((new.height / 150.0), 1.0))
        }
      }
    }
  }
}
