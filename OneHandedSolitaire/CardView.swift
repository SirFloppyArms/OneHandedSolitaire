//
//  CardView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceUp: Bool = true
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            if isFaceUp {
                Image(card.imageName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isHighlighted ? Color.blue : Color.black.opacity(0.3), lineWidth: isHighlighted ? 2.5 : 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 3)
            } else {
                Image("card_back")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .rotation3DEffect(
            .degrees(isFaceUp ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.3), value: isFaceUp)
    }
}
