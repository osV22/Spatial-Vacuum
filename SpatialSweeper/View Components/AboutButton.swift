//
//  AboutButton.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/7/24.
//

import SwiftUI

struct AboutButton: View {
    var onTap: () -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.white)
                    .font(.title)
                Spacer()
                Text("About")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                Spacer()
            }
            .frame(width: 180, height: 60)
            .background(Color.white.opacity(0.2))
        }
        .onTapGesture {
            onTap()
        }
        .hoverEffect()
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.top, 50)
    }
}
