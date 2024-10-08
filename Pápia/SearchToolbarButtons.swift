//
//  SearchToolbarButtons.swift
//  Pápia
//
//  Created by Stef Kors on 06/06/2024.
//

import SwiftUI

// Conform to `PrimitiveButtonStyle` for custom interaction behaviour

struct SupportsLongPress: PrimitiveButtonStyle {

    /// An action to execute on long press
    let longPressAction: () -> ()

    /// Whether the button is being pressed
    @State var isPressed: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.6)
                .padding(2)
                .frame(width: 28, height: 25.2, alignment: .center)
                .background(Color(red: 0.21, green: 0.42, blue: 0.2))
                .cornerRadius(5.6)

            VStack(alignment: .center, spacing: 2.8) {
                configuration.label
                    .font(Font.system(size: 14, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
            .padding(2)
            .frame(width: 28, height: 25.2, alignment: .center)
            .background(Color(red: 0.35, green: 0.67, blue: 0.34))
            .cornerRadius(5.6)
            .offset(y: self.isPressed ? 0 : -2)
            .onTapGesture {
                // Run the "action" as specified
                // when declaring the button
                configuration.trigger()
            }
            .onLongPressGesture(
                perform: {
                    // Run the action specified
                    // when using this style
                    self.longPressAction()
                },
                onPressingChanged: { pressing in
                    // Use "pressing" to infer whether the button
                    // is being pressed
                    self.isPressed = pressing
                }
            )
        }
    }
}

/// A modifier that applies the `SupportsLongPress` style to buttons
struct SupportsLongPressModifier: ViewModifier {
    let longPressAction: () -> ()
    func body(content: Content) -> some View {
        content.buttonStyle(SupportsLongPress(longPressAction: self.longPressAction))
    }
}

/// Extend the View protocol for a SwiftUI-like shorthand version
extension View {
    func supportsLongPress(longPressAction: @escaping () -> ()) -> some View {
        modifier(SupportsLongPressModifier(longPressAction: longPressAction))
    }
}


struct ToolbarButtonComponent: View {
    let label: String

    @EnvironmentObject private var model: DataMuseViewModel
    @State private var isLongPressed: Bool = false

    var body: some View {
        Button(
            action: {
                print("You've tapped me!")
            },
            label: {
                Text(label)
            }
        )
        .supportsLongPress {
            isLongPressed.toggle()
        }
        .overlay(alignment: .bottomLeading, content: {
            if isLongPressed {
                Text("Use double-slashes (//) before a group of letters to unscramble them (that is, find anagrams.)")
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
                    .frame(width: 200)
                    .font(.footnote)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.background)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 6)
                    .offset(y: -50)
                    .transition(.opacity.combined(with: .scale).combined(with: .move(edge: .bottom)).animation(.snappy(duration: 0.1)))
            }
        })
        .animation(.snappy, value: isLongPressed)
    }
}

// The asterisk (*) matches any number of letters. That means that you can use it as a placeholder for any part of a word or phrase. For example, if you enter blueb* you'll get all the terms that start with "blueb"; if you enter *bird you'll get all the terms that end with "bird"; if you enter *lueb* you'll get all the terms that contain the sequence "lueb", and so forth. An asterisk can match zero letters, too.

// The question mark (?) matches exactly one letter. That means that you can use it as a placeholder for a single letter or symbol. The query l?b?n?n,  for example, will find the word "Lebanon".

// The number-sign (#) matches any English consonant. For example, the query tra#t finds the word "tract" but not "trait".

// The at-sign (@) matches any English vowel (including "y"). For example, the query abo@t finds the word "about" but not "abort".

// NEW! The comma (,) lets you combine multiple patterns into one. For example, the query ?????,*y* finds 5-letter words that contain a "y" somewhere, such as "happy" and "rhyme".

// NEW! Use double-slashes (//) before a group of letters to unscramble them (that is, find anagrams.) For example, the query //soulbeat will find "absolute" and "bales out", and re//teeprsn will find "represent" and "repenters". You can use another double-slash to end the group and put letters you're sure of to the right of it. For example, the query //blabrcs//e will find "scrabble". Question marks can signify unknown letters as usual; for example, //we??? returns 5-letter words that contain a W and an E, such as "water" and "awake".

// NEW! A minus sign (-) followed by some letters at the end of a pattern means "exclude these letters". For example, the query sp???-ei finds 5-letter words that start with "sp" but do not contain an "e"or an "i", such as "spoon" and "spray".

// NEW! A plus sign (+) followed by some letters at the end of a pattern means "restrict to these letters". For example, the query *+ban finds "banana".

// On OneLook's main search or directly on OneLook Thesaurus, you can combine patterns and thesaurus lookups by putting a colon (:) after a pattern and then typing a description of the word, as in ??lon:synthetic fabric and the other examples above.


struct SearchToolbar: ViewModifier {
    @EnvironmentObject private var model: DataMuseViewModel

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        ToolbarButtonComponent(label: "?")
                        ToolbarButtonComponent(label: "*")
                        ToolbarButtonComponent(label: "@")
                        ToolbarButtonComponent(label: ",")
                        ToolbarButtonComponent(label: "//")
                        ToolbarButtonComponent(label: "-")
                        ToolbarButtonComponent(label: "+")
                        ToolbarButtonComponent(label: ":")
                    }
                }
            }
    }
}

struct ToolbarButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.6)
                .padding(2)
                .frame(width: 28, height: 25.2, alignment: .center)
                .background(Color(red: 0.21, green: 0.42, blue: 0.2))
                .cornerRadius(5.6)

            VStack(alignment: .center, spacing: 2.8) {
                configuration.label
                    .font(Font.system(size: 14, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
            .padding(2)
            .frame(width: 28, height: 25.2, alignment: .center)
            .background(Color(red: 0.35, green: 0.67, blue: 0.34))
            .cornerRadius(5.6)
            .offset(y: configuration.isPressed ? 0 : -2)
        }


    }
}

struct FullSizePapiaIcon: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .center, spacing: 10) {
                Text("w")
                    .font(Font.system(size: 64, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
            .padding(0)
            .frame(width: 100, height: 90, alignment: .center)
            .background(Color(red: 0.35, green: 0.67, blue: 0.34))
            .cornerRadius(20)
        }
        .padding(.horizontal, 0)
        .padding(.top, 0)
        .padding(.bottom, 10)
        .background(Color(red: 0.21, green: 0.42, blue: 0.2))
        .cornerRadius(20)
    }
}

#Preview {
    FullSizePapiaIcon()
}


#Preview {
    Text("Hello, world!")
        .modifier(SearchToolbar())
}

extension View {
    func searchToolbar() -> some View {
        modifier(SearchToolbar())
    }
}
