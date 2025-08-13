//
//  CareerResultsView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import SwiftUI

struct CareerResultsView: View {
    @ObservedObject var manager: CareerManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("Standings — \(manager.currentTier.rawValue)")
                    .font(.title3.bold())
                    .padding(.top)

                List {
                    ForEach(Array(manager.lastStandings.enumerated()), id: \.0) { idx, row in
                        HStack {
                            Text("\(idx + 1).")
                                .frame(width: 28, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text(row.0)
                                    .font(.body)
                                Text("Score: \(row.1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if row.2 { // isYou
                                Text("You")
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)

                HStack(spacing: 12) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("Advance if eligible") {
                        manager.advanceTierIfEligible()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Results")
        }
    }
}
