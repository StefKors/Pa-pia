//
//  ProgressIcon.swift
//  Pápia
//
//  Created by Stef Kors on 29/04/2024.
//

import SwiftUI

struct ProgressIcon: View {
    private let animation = Animation.snappy(duration: 1.25).repeatForever(autoreverses: false)
    @State var isAtMaxScale = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3.0)
                .opacity(0.3)
                .foregroundColor(.accentColor)

            Circle()
                .trim(from: 0.0, to: .pi/10)
                .stroke(style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(.accentColor)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: self.animation)
        }
        .frame(width: 16, height: 16)
        .rotationEffect(Angle(degrees: self.isAtMaxScale ? 360.0 : 0.0))
        .onAppear {
            withAnimation(self.animation, {
                self.isAtMaxScale.toggle()
            })
        }
        .padding(1)
        .clipShape(Rectangle())
    }
}


#Preview {
    ProgressIcon()
}
