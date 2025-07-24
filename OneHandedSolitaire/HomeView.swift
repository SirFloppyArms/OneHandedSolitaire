//
//  HomeView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showSingleGame = false
    @State private var showAo3Game = false
    @State private var showTournament = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("One-Handed Solitaire")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top)

                VStack(spacing: 20) {
                    NavigationLink(destination: ContentView(game: GameEngine()), isActive: $showSingleGame) {
                        Button("▶️ Single Game") {
                            showSingleGame = true
                        }
                        .buttonStyle(HomeButtonStyle())
                    }

                    NavigationLink(destination: Ao3GameView(), isActive: $showAo3Game) {
                        Button("📉 Ao3") {
                            showAo3Game = true
                        }
                        .buttonStyle(HomeButtonStyle())
                    }

                    NavigationLink(destination: TournamentView(), isActive: $showTournament) {
                        Button("🏆 Tournament") {
                            showTournament = true
                        }
                        .buttonStyle(HomeButtonStyle())
                    }
                }

                HStack(spacing: 40) {
                    NavigationLink(destination: LeaderboardView()) {
                        Label("Leaderboard", systemImage: "chart.bar")
                    }

                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                .foregroundColor(.white)
                .font(.subheadline)

                Spacer()

                Button("Log Out") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.85)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
        }
    }
}

struct HomeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(configuration.isPressed ? 0.6 : 0.9))
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline)
            .padding(.horizontal, 20)
    }
}
