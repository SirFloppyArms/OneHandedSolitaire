//
//  Ao3LeaderboardView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-23.
//

import SwiftUI
import FirebaseFirestore

struct Ao3LeaderboardView: View {
    enum Ao3LeaderboardType: String, CaseIterable {
        case bestScoreWithoutWin = "Best (No Win)"
        case mostWins = "Most Wins"
        case bestScoreWithWin = "Best (With Win)"
    }

    @State private var selectedType: Ao3LeaderboardType = .bestScoreWithoutWin
    @State private var leaderboardEntries: [LeaderboardEntry] = []

    var body: some View {
        VStack {
            Picker("Leaderboard Type", selection: $selectedType) {
                ForEach(Ao3LeaderboardType.allCases, id: \.self) {
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
        .navigationTitle("Ao3 Leaderboard")
        .onAppear { fetchAo3Leaderboard() }
        .onChange(of: selectedType) { _ in fetchAo3Leaderboard() }
    }

    private func fetchAo3Leaderboard() {
        let db = Firestore.firestore()
        db.collection("ao3").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            var entries: [LeaderboardEntry] = []

            switch selectedType {
            case .bestScoreWithoutWin:
                var results: [(LeaderboardEntry, Double, Date)] = []
                for doc in docs {
                    let scores = doc["scores"] as? [Int] ?? []
                    if scores.contains(-10) { continue }
                    if let ao3 = doc["ao3"] as? Double,
                       let username = doc["username"] as? String,
                       let ts = doc["timestamp"] as? Timestamp {
                        results.append((LeaderboardEntry(id: doc.documentID, username: username, displayValue: String(format: "%.2f", ao3)), ao3, ts.dateValue()))
                    }
                }
                results.sort { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 }
                entries = results.map { $0.0 }

            case .mostWins:
                let wins = docs.filter { ($0["scores"] as? [Int] ?? []).contains(-10) }
                let grouped = Dictionary(grouping: wins, by: { $0["username"] as? String ?? "Unknown" })
                entries = grouped.map { LeaderboardEntry(id: $0.key, username: $0.key, displayValue: "\($0.value.count)") }
                entries.sort { Int($0.displayValue)! > Int($1.displayValue)! }

            case .bestScoreWithWin:
                var results: [(LeaderboardEntry, Double, Date)] = []
                for doc in docs {
                    let scores = doc["scores"] as? [Int] ?? []
                    if !scores.contains(-10) { continue }
                    if let ao3 = doc["ao3"] as? Double,
                       let username = doc["username"] as? String,
                       let ts = doc["timestamp"] as? Timestamp {
                        results.append((LeaderboardEntry(id: doc.documentID, username: username, displayValue: String(format: "%.2f", ao3)), ao3, ts.dateValue()))
                    }
                }
                results.sort { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 }
                entries = results.map { $0.0 }
            }

            leaderboardEntries = entries
        }
    }
}
