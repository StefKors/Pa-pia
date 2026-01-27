//
//  ToolbarButtonsGroup.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

// The asterisk (*) matches any number of letters. That means that you can use it as a placeholder for any part of a word or phrase. For example, if you enter blueb* you'll get all the terms that start with "blueb"; if you enter *bird you'll get all the terms that end with "bird"; if you enter *lueb* you'll get all the terms that contain the sequence "lueb", and so forth. An asterisk can match zero letters, too.

// The question mark (?) matches exactly one letter. That means that you can use it as a placeholder for a single letter or symbol. The query l?b?n?n,  for example, will find the word "Lebanon".

// The number-sign (#) matches any English consonant. For example, the query tra#t finds the word "tract" but not "trait".

// The at-sign (@) matches any English vowel (including "y"). For example, the query abo@t finds the word "about" but not "abort".

// NEW! The comma (,) lets you combine multiple patterns into one. For example, the query ?????,*y* finds 5-letter words that contain a "y" somewhere, such as "happy" and "rhyme".

// NEW! Use double-slashes (//) before a group of letters to unscramble them (that is, find anagrams.) For example, the query //soulbeat will find "absolute" and "bales out", and re//teeprsn will find "represent" and "repenters". You can use another double-slash to end the group and put letters you're sure of to the right of it. For example, the query //blabrcs//e will find "scrabble". Question marks can signify unknown letters as usual; for example, //we??? returns 5-letter words that contain a W and an E, such as "water" and "awake".

// NEW! A minus sign (-) followed by some letters at the end of a pattern means "exclude these letters". For example, the query sp???-ei finds 5-letter words that start with "sp" but do not contain an "e"or an "i", such as "spoon" and "spray".

// NEW! A plus sign (+) followed by some letters at the end of a pattern means "restrict to these letters". For example, the query *+ban finds "banana".

// On OneLook's main search or directly on OneLook Thesaurus, you can combine patterns and thesaurus lookups by putting a colon (:) after a pattern and then typing a description of the word, as in ??lon:synthetic fabric and the other examples above.

struct ToolbarButtonsGroup: View {
    @State private var presentedExplainer: String?

    private func showExplainer(_ text: String) {
        withAnimation {
            // Toggle off if same explainer is tapped again
            if presentedExplainer == text {
                presentedExplainer = nil
            } else {
                presentedExplainer = text
            }
        }
    }
    
    var body: some View {
        VStack {
            if let presentedExplainer {
                Text(presentedExplainer)
                    .scenePadding()
                    .glassEffect(in: RoundedRectangle(cornerRadius: 18))
                    .modifier(GlassContainerModifier(spacing: 18))
                    .transition(.scale.combined(with: .opacity).combined(with: .blurReplace))
            }

            HStack(alignment: .center, spacing: 4) {
//                Spacer()
                ToolbarButtonComponent(
                    label: "*",
                    shortexplainer: "many",
                    explainer: "The asterisk (*) matches any number of letters. An asterisk can match zero letters, too.",
                    onLongPress: showExplainer
                )
                ToolbarButtonComponent(
                    label: "@",
                    shortexplainer: "any vowel",
                    explainer: "The at-sign (@) matches any English vowel (including \"y\"). For example, the query abo@t finds the word \"about\" but not \"abort\".",
                    onLongPress: showExplainer
                )
                ToolbarButtonComponent(
                    label: "?",
                    shortexplainer: "any letter",
                    explainer: "The question mark (?) matches exactly one letter. That means that you can use it as a placeholder for a single letter or symbol. The query l?b?n?n,  for example, will find the word \"Lebanon\".",
                    onLongPress: showExplainer
                )
                ToolbarButtonComponent(
                    label: ",",
                    shortexplainer: "combine",
                    explainer: "The comma (,) lets you combine multiple patterns into one. For example, the query ?????,*y* finds 5-letter words that contain a \"y\" somewhere, such as \"happy\" and \"rhyme\".",
                    onLongPress: showExplainer
                )
                ToolbarButtonComponent(
                    label: "-",
                    shortexplainer: "exclude",
                    explainer: "A minus sign (-) followed by some letters at the end of a pattern means \"exclude these letters\".",
                    onLongPress: showExplainer
                )
                ToolbarButtonComponent(
                    label: "+",
                    shortexplainer: "restrict",
                    explainer: "A plus sign (+) followed by some letters at the end of a pattern means \"restrict to these letters\".",
                    onLongPress: showExplainer
                )
                ToolbarButtonComponent(
                    label: "//",
                    shortexplainer: "unscramble",
                    explainer: "Use double-slashes (//) before a group of letters to unscramble them (that is, find anagrams.)",
                    onLongPress: showExplainer
                )
//                Spacer()
            }
            .modifier(GlassContainerModifier(spacing: 28))
        }
    }
}

#Preview {
    ToolbarButtonsGroup()
        .scenePadding()
}
