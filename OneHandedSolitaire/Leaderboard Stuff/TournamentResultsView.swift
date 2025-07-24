//
//  TournamentResultsView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-23.
//

import SwiftUI
import FirebaseFirestore

struct TournamentResultsView: View {
    var tournament: TournamentInfo
    @State private var results: [LeaderboardEntry] = []

    var body: some View {
        List(results) { entry in
            HStack {
                Text(entry.username)
                Spacer()
                Text(entry.displayValue)
                    .bold()
            }
        }
        .navigationTitle(tournament.displayName)
        .onAppear {
            fetchResults()
        }
    }

    func fetchResults() {
        let db = Firestore.firestore()
        let entriesRef = db.collection("tournaments").document(tournament.id).collection("entries")

        entriesRef.getDocuments { snapshot, error in
            guard let entryDocs = snapshot?.documents else {
                print("❌ Failed to fetch entry docs:", error?.localizedDescription ?? "")
                return
            }

            var allEntries: [(LeaderboardEntry, Double, Date)] = []

            let dispatchGroup = DispatchGroup()

            for entryDoc in entryDocs {
                let userId = entryDoc.documentID
                let ao3sRef = entriesRef.document(userId).collection("ao3s")

                dispatchGroup.enter()
                ao3sRef.getDocuments { ao3Snapshot, error in
                    defer { dispatchGroup.leave() }

                    guard let ao3Docs = ao3Snapshot?.documents, ao3Docs.count == 5 else {
                        return  // skip users who don't have exactly 5 Ao3s
                    }

                    // Grab username from first doc
                    let username = ao3Docs.first?["username"] as? String ?? "Unknown"

                    let scores: [Double] = ao3Docs.compactMap { $0["ao3"] as? Double }
                    let timestamps: [Date] = ao3Docs.compactMap { ($0["timestamp"] as? Timestamp)?.dateValue() }

                    guard scores.count == 5 else { return }

                    let avg = scores.reduce(0, +) / 5.0
                    let earliestTimestamp = timestamps.min() ?? Date()

                    let entry = LeaderboardEntry(
                        id: userId,
                        username: username,
                        displayValue: String(format: "%.2f", avg)
                    )

                    allEntries.append((entry, avg, earliestTimestamp))
                }
            }

            dispatchGroup.notify(queue: .main) {
                allEntries.sort {
                    $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2
                }

                results = allEntries.map { $0.0 }
            }
        }
    }
}
