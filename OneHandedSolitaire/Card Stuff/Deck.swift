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

    // New signature with optional seed and luckiness (1.0 = normal)
    func reset(seed: Int? = nil, luckiness: Double = 1.0) {
        // create a fresh ordered deck
        cards = Suit.allCases.flatMap { suit in
            (1...13).map { value in
                Card(suit: suit, value: value)
            }
        }

        // seeded shuffle (if seed provided) or random shuffle otherwise
        if let seed = seed {
            cards = seededShuffle(cards: cards, seed: seed)
        } else {
            cards.shuffle()
        }

        // apply a subtle luck bias — stronger luckiness pushes small positive groupings to front
        if luckiness > 1.0 {
            applyLuckBias(luckiness: luckiness)
        }
    }

    private func seededShuffle(cards: [Card], seed: Int) -> [Card] {
        var rng = SeededGenerator(seed: UInt64(seed))
        var array = cards
        array.shuffle(using: &rng)
        return array
    }

    // Very simple bias: find a few small favorable patterns and move them slightly forward
    private func applyLuckBias(luckiness: Double) {
        // Clamp to a subtle range
        let factor = min(max(luckiness, 1.0), 1.25)
        // Number of bias operations proportional to factor
        let ops = Int(2 + (factor - 1.0) * 20) // low ops for subtlety
        for _ in 0..<ops {
            // pick a random target card that might help an early discard
            if let idx = cards.indices.randomElement() {
                // try to find another card matching suit or number and swap it slightly forward
                let card = cards[idx]
                if let matchIdx = cards.firstIndex(where: { $0.suit == card.suit && $0.id != card.id }) {
                    let newIndex = max(0, matchIdx - Int(1 + (factor - 1.0) * 4))
                    let movingCard = cards.remove(at: matchIdx)
                    cards.insert(movingCard, at: newIndex)
                } else if let matchIdx = cards.firstIndex(where: { $0.value == card.value && $0.id != card.id }) {
                    let newIndex = max(0, matchIdx - Int(1 + (factor - 1.0) * 4))
                    let movingCard = cards.remove(at: matchIdx)
                    cards.insert(movingCard, at: newIndex)
                }
            }
        }
    }

    func shuffle() {
        cards.shuffle()
    }

    func drawFromBottom() -> Card? {
        return cards.isEmpty ? nil : cards.removeLast()
    }

    var isEmpty: Bool { cards.isEmpty }
    var count: Int { cards.count }
}

// Small deterministic RNG
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed != 0 ? seed : 0xdeadbeef }
    mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}
