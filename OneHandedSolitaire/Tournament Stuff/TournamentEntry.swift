//
//  TournamentEntry.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-23.
//

import SwiftUI
import FirebaseFirestore

struct Tournament: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var type: String // e.g., "weekly", "monthly", "yearly", or "custom"
}

struct TournamentEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var username: String
    var scores: [Int]
    var ao3: Double
    var timestamp: Date
}
