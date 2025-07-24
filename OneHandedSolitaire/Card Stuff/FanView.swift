//
//  FanView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import SwiftUI

struct FanView: View {
    let cards: [Card]
    let discardedCards: [Card]
    var animation: Namespace.ID

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // 🗃 Discarded cards (e.g., being thrown away)
            ForEach(discardedCards) { card in
                CardView(card: card)
                    .frame(width: 160, height: 224) // 💡 Card size (same for all areas)
                    .offset(x: 400)                 // 💡 Pushes discarded cards far right (off-screen)
                    .opacity(0.8)                   // 💡 Transparency of discarded cards
                    .rotationEffect(.degrees(20))  // 💡 Angle of discarded cards
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(-1)                     // 💡 Always behind everything else
            }

            // ⚙️ Split: last 4 cards go to sleeve, rest to vertical stack
            let topCount = 4
            let total = cards.count
            let topCards = Array(cards.suffix(min(topCount, total)))     // Sleeve cards (max 4)
            let bottomCards = Array(cards.prefix(total - topCards.count))// Remaining go in vertical stack

            // 🟦 Bottom stack (vertical)
            Group {
                ForEach(Array(bottomCards.enumerated()), id: \.1.id) { index, card in
                    CardView(card: card)
                        .frame(width: 160, height: 224)          // 💡 Size of stacked cards
                        .offset(
                            x: -17,                              // 💡 Horizontal nudge of stack (negative = left)
                            y: CGFloat(-(bottomCards.count - index) * 3) // 💡 Vertical spread between stacked cards
                        )
                        .rotationEffect(.degrees(0))             // 💡 Stack stays upright (no tilt)
                        .zIndex(Double(index))                   // 💡 Lower cards appear behind higher ones
                        .matchedGeometryEffect(id: card.id, in: animation)
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                }
            }
            .offset(y: -20) // 💡 Moves *entire vertical stack* upward. Increase = closer to sleeve

            // 🟥 Top sleeve (fanned 4 cards)
            ForEach(Array(topCards.enumerated()), id: \.1.id) { index, card in
                sleeveCard(card: card, index: index)
            }
        }
        .frame(height: 350)        // 💡 Height of whole layout zone (adjust based on spacing needs)
        .padding(.leading, 12)     // 💡 Nudges the whole fan layout slightly right
    }

    // ✅ Helper for sleeve card layout
    private func sleeveCard(card: Card, index: Int) -> some View {
        
        // 📐 Rotation of bottom sleeve card (card 4) — more negative = tilts more left
        let card4Rotation: Double = -4
        
        // 🔁 How much each card above card 4 rotates further to the right
        let rotationStep: Double = 5
        
        // ↔️ Horizontal spacing between each card in the fan
        let stepX: CGFloat = 24
        
        // ↕️ Vertical spacing between each card in the fan
        let stepY: CGFloat = 10

        let xOffset: CGFloat
        let yOffset: CGFloat
        let rotation: Double

        if index == 0 {
            // 📌 Bottom sleeve card (card 4)
            xOffset = 2                    // 💡 Horizontal position starts at 0
            yOffset = -5                 // 💡 Vertical boost for card 4 — pushes it lower in the fan
            rotation = card4Rotation      // 💡 Use the base leftward tilt
        } else {
            // 🧷 Cards 3, 2, 1 — layered on top of card 4
            let relativeIndex = index - 1 // Shift: card 3 = 0, card 2 = 1, card 1 = 2
            xOffset = CGFloat(index) * stepX    // 💡 Wider `stepX` = more spread horizontally
            yOffset = CGFloat(index) * stepY    // 💡 Higher `stepY` = more lift per card
            rotation = card4Rotation + Double(relativeIndex + 1) * rotationStep
            // 💡 Each card rotates more clockwise relative to card 4
        }

        let z = Double(100 + index) // 💡 Ensures card 1 > card 2 > card 3 > card 4 in front

        return CardView(card: card)
            .frame(width: 160, height: 224) // 💡 Size of each fanned card
            .offset(x: xOffset, y: yOffset) // 💡 Position based on step values
            .rotationEffect(.degrees(rotation)) // 💡 Rotation angle per index
            .zIndex(z) // 💡 Stacking order
            .matchedGeometryEffect(id: card.id, in: animation)
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2) // 💡 Drop shadow
    }
}
