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
