//
//  SinglesLeaderboardView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-23.
//

import SwiftUI
import FirebaseFirestore

struct SinglesLeaderboardView: View {
    enum SinglesLeaderboardType: String, CaseIterable {
        case bestScoreWithoutWin = "Best (No Win)"
        case mostWins = "Most Wins"
        case bestScoreWithWin = "Best (With Win)"
    }

    @State private var selectedType: SinglesLeaderboardType = .bestScoreWithoutWin
    @State private var leaderboardEntries: [LeaderboardEntry] = []

    var body: some View {
        VStack {
            Picker("Leaderboard Type", selection: $selectedType) {
                ForEach(SinglesLeaderboardType.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List(leaderboardEntries) { entry in
                HStack {
                    Text(entry.username)
                    Spacer()
                    Text(entry.displayValue)
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Singles Leaderboard")
        .onAppear { fetchSinglesLeaderboard() }
        .onChange(of: selectedType) { _ in fetchSinglesLeaderboard() }
    }

    private func fetchSinglesLeaderboard() {
        let db = Firestore.firestore()
        db.collection("singles").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            var entries: [LeaderboardEntry] = []

            switch selectedType {
            case .bestScoreWithoutWin:
                var results: [(entry: LeaderboardEntry, score: Int, time: Date)] = []
                for doc in docs {
                    if !(doc["isWin"] as? Bool == false) { continue }
                    if let score = doc["score"] as? Int,
                       let username = doc["username"] as? String,
                       let ts = doc["timestamp"] as? Timestamp {
                        results.append((LeaderboardEntry(id: doc.documentID, username: username, displayValue: "\(score)"), score, ts.dateValue()))
                    }
                }
                results.sort { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 }
                entries = results.map { $0.0 }

            case .mostWins:
                let wins = docs.filter { ($0["isWin"] as? Bool) == true }
                let grouped = Dictionary(grouping: wins, by: { $0["username"] as? String ?? "Unknown" })
                entries = grouped.map { LeaderboardEntry(id: $0.key, username: $0.key, displayValue: "\($0.value.count)") }
                entries.sort { Int($0.displayValue)! > Int($1.displayValue)! }

            case .bestScoreWithWin:
                var results: [(entry: LeaderboardEntry, score: Int, time: Date)] = []
                for doc in docs {
                    if !(doc["isWin"] as? Bool == true) { continue }
                    if let score = doc["score"] as? Int,
                       let username = doc["username"] as? String,
                       let ts = doc["timestamp"] as? Timestamp {
                        results.append((LeaderboardEntry(id: doc.documentID, username: username, displayValue: "\(score)"), score, ts.dateValue()))
                    }
                }
                results.sort { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 }
                entries = results.map { $0.0 }
            }

            leaderboardEntries = entries
        }
    }
}
