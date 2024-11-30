//
//  WordDetailView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import Foundation
import SwiftUI

struct WordDetailInformation: Identifiable {
    let scope: DataMuseViewModel.SearchScope
    let words: [DataMuseWord]

    var id: String {
        self.scope.id
    }

    static let preview = WordDetailInformation(scope: .preview, words: [.preview, .preview2])
}

#if os(macOS)

/// TODO: Add bookmark button
/// TODO: Support definitions with: https://api.datamuse.com/words?sl=jirraf&md=dpsr
struct WordDetailView: View {
    let word: DataMuseWord

    @State private var information: [DataMuseViewModel.SearchScope: [DataMuseWord]] = [:]
    @StateObject private var model = DataMuseViewModel()
    @State private var results: [WordDetailInformation] = []
    @State private var definitions: [DataMuseDefinition] = []

    @EnvironmentObject private var state: InterfaceState

    var body: some View {

        ScrollView {
            VStack(alignment: .leading) {
                ForEach(definitions) { definition in
                    DefinitionView(def: definition)
                }

                ForEach(results) { info in
                    WordDetailSectionView(info: info)
                }
            }
            .scenePadding()
        }
        .navigationTitle(word.word.capitalized)
        .task(id: word) {
            self.results = []
            for scope in model.relatedScopes {
                let words = await model.fetch(scope: scope, searchText: word.word)
                results.append(WordDetailInformation(scope: scope, words: words))
            }
        }
        .task(id: word) {
            self.definitions = await model.definitions(search: word.word)
        }
    }
}

#else

struct PillTag: View {
    let label: String
    let isSelected: Bool

    init(label: String, isSelected: Bool) {
        self.label = label
        self.isSelected = isSelected
    }

    init(scope: DataMuseViewModel.SearchScope, isSelected: Bool) {
        self.label = String(scope.label.trimmingPrefix("Related: "))
        self.isSelected = isSelected
    }

    var body: some View {
        Text(label)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .font(.callout)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), in: .capsule(style: .continuous))
    }
}

#Preview {
    HStack {
        PillTag(scope: .preview, isSelected: true)
        PillTag(scope: .preview, isSelected: false)
        PillTag(scope: .preview, isSelected: false)
        PillTag(scope: .preview, isSelected: false)
    }
    .scenePadding()
}


struct WordDetailView: View {
    let word: DataMuseWord

    @State private var information: [DataMuseViewModel.SearchScope: [DataMuseWord]] = [:]
    @StateObject private var model = DataMuseViewModel()
    @State private var results: [WordDetailInformation] = []
    @State private var definitions: [DataMuseDefinition] = []

    @Environment(\.dismiss) private var dismiss

    @State private var selectedScope: DataMuseViewModel.SearchScope? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "chevron.left")
                    .bold()
                    .font(.title3)

                Text(word.word.capitalized)
                    .font(.title)
                    .bold()
                if word.isWordle {
                    Image(.wordle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20, alignment: .leadingLastTextBaseline)
                }
                //
                //                if word.isWordle {
                //                    Image(.scrabble)
                //                        .resizable()
                //                        .aspectRatio(contentMode: .fit)
                //                        .frame(width: 20, height: 20, alignment: .leadingLastTextBaseline)
                //                }

                Spacer()
            }
            .scenePadding(.horizontal)
            .onTapGesture {
                dismiss()
            }


            ScrollViewReader { value in
                ScrollView(.horizontal) {
                    HStack {
                        PillTag(label: "Definition", isSelected: selectedScope == nil)
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.1)) {
                                    selectedScope = nil
                                }
                            }
                            .id(DataMuseViewModel.SearchScope.none)

                        ForEach(model.relatedScopes) { scope in
                            PillTag(scope: scope, isSelected: selectedScope == scope)
                                .onTapGesture {
                                    withAnimation(.snappy(duration: 0.1)) {
                                        selectedScope = scope
                                    }
                                }
                                .id(scope)
                        }
                    }
                    .onChange(of: selectedScope, perform: { newValue in
                        withAnimation(.snappy(duration: 0.1)) {
                            if newValue == nil {
                                value.scrollTo(DataMuseViewModel.SearchScope.none, anchor: .leading)
                            } else {
                                value.scrollTo(newValue, anchor: .leading)
                            }
                        }
                    })
                    .modifier(ScrollClipOptional(outside: false))
                }
                .modifier(ScrollClipOptional(outside: true))
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }

            if #available(iOS 17.0, *) {
                ModernPagedWordDetailView(
                    selectedScope: $selectedScope,
                    definitions: definitions,
                    word: word
                )
                .environmentObject(model)
                .sensoryFeedback(.impact, trigger: selectedScope)
            } else {
                OldPagedWordDetailView(
                    selectedScope: $selectedScope,
                    definitions: definitions,
                    word: word
                )
                .environmentObject(model)
            }
        }
        .navigationTitle(word.word)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: word) {
            self.definitions = await model.definitions(search: word.word)
        }
    }
}



struct OldPagedWordDetailView: View {
    @Binding var selectedScope: DataMuseViewModel.SearchScope?
    let definitions: [DataMuseDefinition]
    let word: DataMuseWord

    var body: some View {
        ScrollView {
            VStack {
                if selectedScope == nil {
                    ForEach(definitions) { definition in
                        DefinitionView(def: definition)
                    }
                } else if let selectedScope {
                    WordDetailListSectionView(scope: selectedScope, word: word)
                        .id(selectedScope)
                }
            }
            .scenePadding(.horizontal)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    OldPagedWordDetailView(selectedScope: .constant(.preview), definitions: [], word: .preview)
}

/// https://www.appcoda.com/scrollview-paging/

@available(iOS 17.0, *)
struct ModernPagedWordDetailView: View {
    @Binding var selectedScope: DataMuseViewModel.SearchScope?
    let definitions: [DataMuseDefinition]
    let word: DataMuseWord

    @EnvironmentObject private var model: DataMuseViewModel

    @State var scrolledID: DataMuseViewModel.SearchScope?

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack {
                        ForEach(definitions) { definition in
                            DefinitionView(def: definition)
                                .id(definition)
                        }
                    }
                    //                    .scenePadding(.horizontal)
                }
                .ignoresSafeArea(.all, edges: .bottom)
                .scrollBounceBehavior(.basedOnSize)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 8)
                .id(DataMuseViewModel.SearchScope.none)
                .modifier(BookFlipScrollTransition())

                ForEach(model.relatedScopes) { scope in
                    ScrollView(.vertical) {
                        VStack {
                            WordDetailListSectionView(scope: scope, word: word)

                        }
                        //                        .scenePadding(.horizontal)
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                    .scrollBounceBehavior(.basedOnSize)
                    //                    .containerRelativeFrame(.horizontal)
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 8)
                    .id(scope)
                    .modifier(BookFlipScrollTransition())
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .scrollTargetLayout()
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolledID)
        .scrollBounceBehavior(.basedOnSize)
        .scenePadding(.horizontal)
        .scrollClipDisabled()
        /// Trigger update when swiping
        .onChange(of: scrolledID) { oldValue, newValue in
            if (newValue == DataMuseViewModel.SearchScope.none) {
                withAnimation(.snappy) {
                    selectedScope = nil
                }
            } else {
                withAnimation(.snappy) {
                    selectedScope = newValue
                }
            }
        }
        /// Trigger update when selecting different tab pill
        .onChange(of: selectedScope) { oldValue, newValue in
            if (newValue == nil) {
                withAnimation(.snappy) {
                    scrolledID = DataMuseViewModel.SearchScope.none
                }
            } else {
                withAnimation(.snappy) {
                    scrolledID = newValue
                }
            }
        }
    }
}

/// use both inside and outside of scroll view
/// the fallback for ios16 adds inside padding
/// whilte the ios 17 one should add outside padding
struct ScrollClipOptional: ViewModifier {
    let outside: Bool

    func body(content: Content) -> some View {
        if outside {
            if #available(iOS 17.0, *) {
                content
                    .padding()
                    .scrollClipDisabled()
            } else {
                content
            }
        } else {
            if #available(iOS 17.0, *) {
                content
            } else {
                content
                    .padding()
            }
        }
    }
}


struct BookFlipScrollTransition: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .scrollTransition { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0)
                        .scaleEffect(phase.isIdentity ? 1 : 0.75)
                        .blur(radius: phase.isIdentity ? 0 : 10)
                }
        } else {
            content
        }
    }
}

#Preview {
    Text("Hello, world!")
        .modifier(BookFlipScrollTransition())
}

#Preview {
    if #available(iOS 17.0, *) {
        ModernPagedWordDetailView(selectedScope: .constant(.preview), definitions: [], word: .preview)
            .environmentObject(DataMuseViewModel())
    } else {
        // Fallback on earlier versions
        Text("see: OldPagedWordDetailView()")
    }
}
#endif

#Preview {
    WordDetailView(word: .preview)
}
