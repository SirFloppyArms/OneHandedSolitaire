//
//  GameEngine.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import Foundation
import SwiftUI

class GameEngine: ObservableObject {
    @Published private(set) var deck = Deck()
    @Published private(set) var visibleStack: [Card] = []
    @Published var discardedCards: [Card] = []
    @Published var cardsBeingDiscarded: [Card] = []
    
    @Published var clears: Int = 0
    @Published var gameOver: Bool = false
    @Published var hasWon: Bool = false
    
    var isDeckEmpty: Bool {
        return deck.isEmpty
    }

    private var inRecyclePhase = false
    private var deckSeed: Int? = nil
    private var deckLuckiness: Double = 1.0

    init(seed: Int? = nil, luckiness: Double = 1.0) {
        self.deckSeed = seed
        self.deckLuckiness = luckiness
        startNewGame(seed: seed, luckiness: luckiness)
    }

    func startNewGame(seed: Int? = nil, luckiness: Double = 1.0) {
        deckSeed = seed ?? deckSeed
        deckLuckiness = luckiness
        deck.reset(seed: deckSeed, luckiness: deckLuckiness)
        visibleStack.removeAll()
        discardedCards.removeAll()
        cardsBeingDiscarded.removeAll()
        clears = 0
        gameOver = false
        hasWon = false
        inRecyclePhase = false
        undosUsed = 0
        gameHistory.removeAll()

        for _ in 0..<4 {
            drawCard()
        }
    }

    // MARK: - Drawing Logic

    func drawCard() {
        recordGameState()
        if !deck.isEmpty {
            if let card = deck.drawFromBottom() {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    visibleStack.append(card)
                }
            }
        } else {
            inRecyclePhase = true
            recycleCard()
        }
    }

    private func recycleCard() {
        guard visibleStack.count > 1 else {
            checkGameOver()
            return
        }

        let card = visibleStack.removeFirst()
        withAnimation(.spring()) {
            visibleStack.append(card)
        }
    }

    // MARK: - Discard Rules

    func tryDiscard() -> Bool {
        guard visibleStack.count >= 4 else { return false }

        // Position 1 is topmost visible card
        let top4 = Array(visibleStack.suffix(4))
        let c1 = top4[0], c2 = top4[1], c3 = top4[2], c4 = top4[3]

        // All Same Suit
        if c1.suit == c2.suit && c2.suit == c3.suit && c3.suit == c4.suit {
            discard(cardsToDiscard: top4)
            return true
        }

        // Same Number Ends
        if c1.value == c4.value {
            discard(cardsToDiscard: top4)
            return true
        }

        // Same Suit Ends
        if c1.suit == c4.suit {
            discard(cardsToDiscard: [c2, c3])
            return true
        }

        return false
    }

    private func discard(cardsToDiscard: [Card]) {
        recordGameState()
        for card in cardsToDiscard {
            if let index = visibleStack.firstIndex(of: card) {
                visibleStack.remove(at: index)
                discardedCards.append(card)
                cardsBeingDiscarded.append(card)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if let discardIndex = self.cardsBeingDiscarded.firstIndex(of: card) {
                        self.cardsBeingDiscarded.remove(at: discardIndex)
                    }
                }
            }
        }

        // Clear condition
        if visibleStack.isEmpty {
            clears += 1
            for _ in 0..<4 {
                drawCard()
            }
        }

        checkGameOver()
    }

    private func checkGameOver() {
        if deck.isEmpty && !canRecycleFurther() && !canDiscardTop4() {
            gameOver = true
            hasWon = (visibleStack.isEmpty)
        }
    }

    private func canRecycleFurther() -> Bool {
        return inRecyclePhase && visibleStack.count > 1
    }

    private func canDiscardTop4() -> Bool {
        guard visibleStack.count >= 4 else { return false }
        let top4 = Array(visibleStack.suffix(4))
        let c1 = top4[0], c2 = top4[1], c3 = top4[2], c4 = top4[3]
        return (c1.suit == c2.suit && c2.suit == c3.suit && c3.suit == c4.suit) ||
               (c1.value == c4.value) ||
               (c1.suit == c4.suit)
    }

    // MARK: - Scoring

    func calculateScore() -> Int {
        let remaining = visibleStack.count + deck.count
        let clearBonus = clears * 2
        let winBonus = hasWon ? 10 : 0
        return remaining - clearBonus - winBonus
    }
    
    func endGame() {
        gameOver = true
        hasWon = visibleStack.isEmpty
    }
    
    @Published var undosUsed: Int = 0
    private var gameHistory: [(deck: [Card], visible: [Card], discarded: [Card])] = []

    func recordGameState() {
        gameHistory.append((deck: deck.cards, visible: visibleStack, discarded: discardedCards))
    }

    func undo() {
        guard !gameHistory.isEmpty else { return }
        let last = gameHistory.removeLast()
        deck.cards = last.deck
        visibleStack = last.visible
        discardedCards = last.discarded
        undosUsed += 1
    }
}
