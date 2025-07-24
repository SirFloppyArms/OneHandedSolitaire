//
//  TournamentListView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-23.
//

import SwiftUI
import FirebaseFirestore

struct TournamentListView: View {
    @State private var allTournaments: [TournamentInfo] = []
    @State private var searchText = ""

    var filteredTournaments: [TournamentInfo] {
        if searchText.isEmpty {
            return allTournaments
        } else {
            return allTournaments.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredTournaments) { tournament in
                NavigationLink(destination: TournamentResultsView(tournament: tournament)) {
                    VStack(alignment: .leading) {
                        Text(tournament.displayName)
                            .font(.headline)
                        Text(tournament.dateRange)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Tournaments")
        .onAppear {
            fetchTournaments()
        }
    }

    func fetchTournaments() {
        let db = Firestore.firestore()
        db.collection("tournaments")
            .order(by: "endDate", descending: true)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { return }

                allTournaments = docs.compactMap { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unknown"
                    let category = data["type"] as? String ?? "Unknown"
                    let start = (data["startDate"] as? Timestamp)?.dateValue()
                    let end = (data["endDate"] as? Timestamp)?.dateValue()

                    guard let start = start, let end = end else { return nil }

                    return TournamentInfo(
                        id: doc.documentID,
                        displayName: "\(category.capitalized), \(formattedDateRange(start: start, end: end))",
                        dateRange: formattedDateRange(start: start, end: end)
                    )
                }
            }
    }

    func formattedDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct TournamentInfo: Identifiable {
    var id: String
    var displayName: String
    var dateRange: String
}
