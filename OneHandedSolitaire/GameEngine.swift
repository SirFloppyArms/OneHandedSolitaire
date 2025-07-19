//
//  GameEngine.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import SwiftUI
import Foundation

class GameEngine: ObservableObject {
    @Published private(set) var deck = Deck()
    @Published private(set) var visibleStack: [Card] = []
    @Published var discardedCards: [Card] = []
    @Published var cardsBeingDiscarded: [Card] = []
    
    @Published var clears: Int = 0
    @Published var gameOver: Bool = false

    // MARK: - Setup

    init() {
        startNewGame()
    }

    func startNewGame() {
        deck.reset()
        visibleStack = []
        discardedCards = []
        clears = 0
        gameOver = false
        
        // Start by drawing 4 cards
        for _ in 0..<4 {
            drawCard()
        }
    }

    // MARK: - Drawing

    func drawCard() {
        guard !deck.isEmpty else {
            if visibleStack.count > 1 {
                let recycledCard = visibleStack.removeLast()
                visibleStack.insert(recycledCard, at: 0)
                return
            } else {
                gameOver = true
                return
            }
        }

        if let card = deck.drawFromBottom() {
            // Delay to sync with deck drop animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.visibleStack.append(card)
                }
            }
        }
    }

    // MARK: - Discard Rules

    func tryDiscard() -> Bool {
        guard visibleStack.count >= 4 else { return false }

        let top4 = Array(visibleStack.suffix(4))
        let c1 = top4[0]
        let c2 = top4[1]
        let c3 = top4[2]
        let c4 = top4[3]

        if c1.suit == c4.suit && c2.suit == c4.suit && c3.suit == c4.suit {
            discardCards(Array(top4))
            return true
        }

        if c1.value == c4.value {
            discardCards(Array(top4))
            return true
        }

        if c1.suit == c4.suit {
            discardCards([c2, c3])
            return true
        }

        return false
    }

    private func discardCards(_ cardsToDiscard: [Card]) {
        for card in cardsToDiscard {
            if let index = visibleStack.firstIndex(of: card) {
                visibleStack.remove(at: index)
                cardsBeingDiscarded.append(card)

                // Animate offscreen removal after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if let discardIndex = self.cardsBeingDiscarded.firstIndex(of: card) {
                        self.cardsBeingDiscarded.remove(at: discardIndex)
                    }
                }
            }
        }

        if visibleStack.isEmpty {
            clears += 1
            for _ in 0..<4 { drawCard() }
        }
    }

    // MARK: - Scoring

    func calculateScore() -> Int {
        let remaining = visibleStack.count + deck.count
        let clearBonus = clears * 2
        let winBonus = (remaining == 0) ? 10 : 0
        return remaining - clearBonus - winBonus
    }
}
