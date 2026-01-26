//
//  FullSizePapiaIcon.swift
//  Papia
//
//  Created by Stef Kors on 08/12/2024.
//

import SwiftUI

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
