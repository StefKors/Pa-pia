//
//  IndeterminateProgressView.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//  source: https://matthewcodes.uk/articles/indeterminate-linear-progress-view/

import SwiftUI

struct CustomProgressView: View {
    @State var progress: CGFloat = 0

    private var animation: Animation {
        .easeInOut(duration: 2)
//        .speed(0.2)
//        .repeatForever(autoreverses: false)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
//                Capsule()
//                    .frame(width: geometry.size.width, height: 10)
//                    .opacity(0.3)
//                    .foregroundColor(.gray)

                Text("🦆")
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(x: min(progress * (geometry.size.width-40),
                                   geometry.size.width))
//                Capsule()
//                    .frame(
//                        width: min(progress * geometry.size.width,
//                                   geometry.size.width),
//                        height: 10
//                    )
//                    .foregroundColor(.blue)
            }
            .onAppear {
                withAnimation(animation) {
                    progress = 1.0
                }
            }
        }
    }
}

//struct IndeterminateProgressView: View {
//    @State private var width: CGFloat = 0
//    @State private var offset: CGFloat = 0
//    private var isEnabled = true
//
//    var body: some View {
//        Rectangle()
//            .foregroundColor(.gray.opacity(0.15))
//            .readWidth()
//            .overlay(
//                Rectangle()
//                    .foregroundColor(Color.accentColor)
//                    .frame(width: self.width * 0.26, height: 6)
//                    .clipShape(Capsule())
//                    .offset(x: -self.width * 0.6, y: 0)
//                    .offset(x: self.width * 1.2 * self.offset, y: 0)
//                    .animation(.default.repeatForever().speed(0.265), value: self.offset)
//                    .onAppear{
//                        withAnimation {
//                            self.offset = 1
//                        }
//                    }
//            )
//            .clipShape(Capsule())
//            .opacity(self.isEnabled ? 1 : 0)
//            .animation(.default, value: self.isEnabled)
//            .frame(height: 6)
//            .onPreferenceChange(WidthPreferenceKey.self) { width in
//                self.width = width
//            }
//    }
//}
//
//struct WidthPreferenceKey: PreferenceKey {
//    static var defaultValue: CGFloat = 0
//
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//        value = max(value, nextValue())
//    }
//}
//
//private struct ReadWidthModifier: ViewModifier {
//    private var sizeView: some View {
//        GeometryReader { geometry in
//            Color.clear.preference(key: WidthPreferenceKey.self, value: geometry.size.width)
//        }
//    }
//
//    func body(content: Content) -> some View {
//        content.background(sizeView)
//    }
//}
//
//extension View {
//    func readWidth() -> some View {
//        self
//            .modifier(ReadWidthModifier())
//    }
//}

#Preview {
    CustomProgressView()
}
