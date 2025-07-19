//
//  Card.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import Foundation

enum Suit: String, CaseIterable {
    case hearts, diamonds, clubs, spades
}

struct Card: Identifiable, Equatable {
    let id = UUID()
    let suit: Suit
    let value: Int // 1 (Ace) to 13 (King)

    var imageName: String {
        let name: String

        switch value {
        case 1: name = "ace"
        case 11: name = "jack"
        case 12: name = "queen"
        case 13: name = "king"
        default: name = "\(value)"
        }

        return "\(name)_of_\(suit.rawValue.lowercased())"
    }

    var description: String {
        return "\(suit.rawValue)\(imageName)"
    }
}
