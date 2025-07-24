//
//  Deck.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import Foundation

class Deck {
    var cards: [Card] = []

    init() {
        reset()
    }

    func reset() {
        cards = Suit.allCases.flatMap { suit in
            (1...13).map { value in
                Card(suit: suit, value: value)
            }
        }
        shuffle()
    }

    func shuffle() {
        cards.shuffle()
    }

    func drawFromBottom() -> Card? {
        return cards.isEmpty ? nil : cards.removeLast()
    }

    var isEmpty: Bool {
        return cards.isEmpty
    }

    var count: Int {
        return cards.count
    }
}
