//
//  LeaderboardView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import SwiftUI
import Firebase

struct LeaderboardView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                NavigationLink(destination: SinglesLeaderboardView()) {
                    leaderboardButton(label: "Singles")
                }

                NavigationLink(destination: Ao3LeaderboardView()) {
                    leaderboardButton(label: "Ao3")
                }

                NavigationLink(destination: TournamentListView()) {
                    leaderboardButton(label: "Tournaments")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Leaderboards")
        }
    }

    private func leaderboardButton(label: String) -> some View {
        Text(label)
            .font(.title2)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

struct OldLeaderboardView: View {
    enum LeaderboardCategory: String, CaseIterable {
        case singles = "Singles"
        case ao3 = "Ao3"
        case tournament = "Tournament"
    }

    enum LeaderboardType: String, CaseIterable {
        case bestScoreWithoutWin = "Best (No Win)"
        case mostWins = "Most Wins"
        case bestScoreWithWin = "Best (With Win)"
    }

    @State private var selectedCategory: LeaderboardCategory = .singles
    @State private var selectedType: LeaderboardType = .bestScoreWithoutWin
    @State private var leaderboardEntries: [LeaderboardEntry] = []

    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(LeaderboardCategory.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                Picker("Type", selection: $selectedType) {
                    ForEach(LeaderboardType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                List(leaderboardEntries) { entry in
                    HStack {
                        Text(entry.username)
                        Spacer()
                        Text(entry.displayValue)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Leaderboards")
            .onChange(of: selectedCategory) { _ in
                fetchLeaderboard()
            }
            .onChange(of: selectedType) { _ in
                fetchLeaderboard()
            }
            .onAppear {
                fetchLeaderboard()
            }
        }
    }

    private func fetchLeaderboard() {
        leaderboardEntries = []

        switch selectedCategory {
        case .singles:
            fetchSinglesLeaderboard()
        case .ao3:
            fetchAo3Leaderboard()
        case .tournament:
            fetchTournamentLeaderboard()
        }
    }

    private func fetchSinglesLeaderboard() {
        let db = Firestore.firestore()
        let collection = db.collection("singles")

        collection.getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }

            var entries: [LeaderboardEntry] = []

            switch selectedType {
            case .bestScoreWithoutWin:
                var results: [(entry: LeaderboardEntry, score: Int, timestamp: Date)] = []

                for doc in docs {
                    let isWin = doc["isWin"] as? Bool ?? false
                    if isWin { continue }

                    if let score = doc["score"] as? Int,
                       let username = doc["username"] as? String,
                       let timestamp = doc["timestamp"] as? Timestamp {
                        let entry = LeaderboardEntry(id: doc.documentID, username: username, displayValue: "\(score)")
                        results.append((entry, score, timestamp.dateValue()))
                    }
                }

                results.sort {
                    $0.score != $1.score ? $0.score < $1.score : $0.timestamp < $1.timestamp
                }

                entries = results.map { $0.entry }

            case .mostWins:
                let groupedWins = Dictionary(grouping: docs.filter {
                    ($0["isWin"] as? Bool ?? false)
                }, by: { $0["username"] as? String ?? "Unknown" })

                entries = groupedWins.map { (username, docs) in
                    LeaderboardEntry(id: username, username: username, displayValue: "\(docs.count)")
                }.sorted { Int($0.displayValue)! > Int($1.displayValue)! }

            case .bestScoreWithWin:
                var results: [(entry: LeaderboardEntry, score: Int, timestamp: Date)] = []

                for doc in docs {
                    let isWin = doc["isWin"] as? Bool ?? false
                    if !isWin { continue }

                    if let score = doc["score"] as? Int,
                       let username = doc["username"] as? String,
                       let timestamp = doc["timestamp"] as? Timestamp {
                        let entry = LeaderboardEntry(id: doc.documentID, username: username, displayValue: "\(score)")
                        results.append((entry, score, timestamp.dateValue()))
                    }
                }

                results.sort {
                    $0.score != $1.score ? $0.score < $1.score : $0.timestamp < $1.timestamp
                }

                entries = results.map { $0.entry }
            }

            leaderboardEntries = entries
        }
    }

    private func fetchAo3Leaderboard() {
        let db = Firestore.firestore()
        let collection = db.collection("ao3")

        collection.getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }

            var entries: [LeaderboardEntry] = []

            switch selectedType {
            case .bestScoreWithoutWin:
                var results: [(entry: LeaderboardEntry, ao3: Double, timestamp: Date)] = []

                for doc in docs {
                    let scores = doc["scores"] as? [Int] ?? []
                    if scores.contains(-10) { continue }

                    if let ao3 = doc["ao3"] as? Double,
                       let username = doc["username"] as? String,
                       let timestamp = doc["timestamp"] as? Timestamp {
                        let entry = LeaderboardEntry(id: doc.documentID, username: username, displayValue: String(format: "%.2f", ao3))
                        results.append((entry, ao3, timestamp.dateValue()))
                    }
                }

                results.sort {
                    $0.ao3 != $1.ao3 ? $0.ao3 < $1.ao3 : $0.timestamp < $1.timestamp
                }

                entries = results.map { $0.entry }

            case .mostWins:
                let groupedWins = Dictionary(grouping: docs.filter {
                    ($0["scores"] as? [Int] ?? []).contains(-10)
                }, by: { $0["username"] as? String ?? "Unknown" })

                entries = groupedWins.map { (username, docs) in
                    LeaderboardEntry(id: username, username: username, displayValue: "\(docs.count)")
                }.sorted { Int($0.displayValue)! > Int($1.displayValue)! }

            case .bestScoreWithWin:
                var results: [(entry: LeaderboardEntry, ao3: Double, timestamp: Date)] = []

                for doc in docs {
                    let scores = doc["scores"] as? [Int] ?? []
                    if !scores.contains(-10) { continue }

                    if let ao3 = doc["ao3"] as? Double,
                       let username = doc["username"] as? String,
                       let timestamp = doc["timestamp"] as? Timestamp {
                        let entry = LeaderboardEntry(id: doc.documentID, username: username, displayValue: String(format: "%.2f", ao3))
                        results.append((entry, ao3, timestamp.dateValue()))
                    }
                }

                results.sort {
                    $0.ao3 != $1.ao3 ? $0.ao3 < $1.ao3 : $0.timestamp < $1.timestamp
                }

                entries = results.map { $0.entry }
            }

            leaderboardEntries = entries
        }
    }
    
    private func fetchTournamentLeaderboard() {
        let db = Firestore.firestore()

        db.collection("tournaments")
            .whereField("isActive", isEqualTo: true)
            .order(by: "endDate", descending: false)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                guard let tournamentDoc = snapshot?.documents.first else {
                    leaderboardEntries = []
                    return
                }

                let tournamentID = tournamentDoc.documentID

                db.collection("tournaments")
                    .document(tournamentID)
                    .collection("entries")
                    .getDocuments { snapshot, error in
                        guard let docs = snapshot?.documents else { return }

                        var results: [(entry: LeaderboardEntry, ao3: Double, timestamp: Date)] = []

                        for doc in docs {
                            if let ao3 = doc["ao3"] as? Double,
                               let username = doc["username"] as? String,
                               let timestamp = doc["timestamp"] as? Timestamp {
                                let entry = LeaderboardEntry(id: doc.documentID, username: username, displayValue: String(format: "%.2f", ao3))
                                results.append((entry, ao3, timestamp.dateValue()))
                            }
                        }

                        results.sort {
                            $0.ao3 != $1.ao3 ? $0.ao3 < $1.ao3 : $0.timestamp < $1.timestamp
                        }

                        leaderboardEntries = results.map { $0.entry }
                    }
            }
    }
}
