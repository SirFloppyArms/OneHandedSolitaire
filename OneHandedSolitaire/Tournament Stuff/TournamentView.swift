//
//  TournamentView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import SwiftUI
import FirebaseFirestore

struct TournamentView: View {
    @State private var tournaments: [Tournament] = []

    var body: some View {
        List(tournaments) { tournament in
            if tournament.isActive {
                NavigationLink(destination: TournamentGameView(tournamentId: tournament.id ?? "")) {
                    VStack(alignment: .leading) {
                        Text(tournament.name)
                            .font(.headline)
                        Text("Ends: \(tournament.endDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Tournaments")
        .onAppear {
            createOrUpdateAutoTournaments {
                fetchActiveTournaments()
            }
        }
    }

    private func fetchActiveTournaments() {
        let db = Firestore.firestore()
        db.collection("tournaments")
            .whereField("isActive", isEqualTo: true)
            .order(by: "endDate")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    self.tournaments = docs.compactMap { try? $0.data(as: Tournament.self) }
                }
            }
    }

    private func createOrUpdateAutoTournaments(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let now = Date()
        let calendar = Calendar.current

        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
        let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!

        let autoTournaments = [
            ("Weekly Tournament", "weekly", weekEnd),
            ("Monthly Tournament", "monthly", monthEnd),
            ("Yearly Tournament", "yearly", yearEnd)
        ]

        let group = DispatchGroup()

        for (name, type, endDate) in autoTournaments {
            group.enter()

            let query = db.collection("tournaments").whereField("type", isEqualTo: type)
            query.getDocuments { snapshot, error in
                let activeExists = snapshot?.documents.contains(where: {
                    guard let end = ($0.data()["endDate"] as? Timestamp)?.dateValue() else { return false }
                    return end > now
                }) ?? false

                if !activeExists {
                    let newTournament = Tournament(
                        name: name,
                        startDate: type == "weekly" ? weekStart :
                                   type == "monthly" ? monthStart :
                                   yearStart,
                        endDate: endDate,
                        isActive: true,
                        type: type
                    )
                    try? db.collection("tournaments").addDocument(from: newTournament)
                }

                // Deactivate old tournaments
                snapshot?.documents.forEach { doc in
                    if let end = (doc.data()["endDate"] as? Timestamp)?.dateValue(), end <= now {
                        doc.reference.updateData(["isActive": false])
                    }
                }

                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }
}
