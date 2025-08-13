//
//  HomeView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showCareer = false
    @State private var showPractice = false
    @State private var showLeaderboard = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("One‑Handed Solitaire")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 10)

                // Score Meter Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Score Meter")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(authViewModel.scoreMeter)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    // Simple horizontal meter
                    GeometryReader { geo in
                        let pct = CGFloat(authViewModel.scoreMeter) / 100.0
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.15))
                                .frame(height: 18)
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.9))
                                .frame(width: max(10, geo.size.width * pct), height: 18)
                                .animation(.easeInOut, value: authViewModel.scoreMeter)
                        }
                    }
                    .frame(height: 18)
                }
                .padding()
                .background(Color.black.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal)

                // Main buttons
                VStack(spacing: 14) {
                    NavigationLink(destination: ModeSelectionView()
                        .environmentObject(authViewModel)) {
                        Label("Career", systemImage: "flag.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(HomeButtonStyle())

                    Button(action: { showPractice = true }) {
                        Label("Practice", systemImage: "play.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(HomeButtonStyle())

                    Button(action: { showLeaderboard = true }) {
                        Label("Leaderboard", systemImage: "chart.bar")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(HomeButtonStyle())

                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gearshape")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(HomeButtonStyle())
                }
                .padding(.horizontal)

                Spacer()

                Button("Log Out") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
                .padding(.bottom, 16)
            }
            .padding(.top)
            .background(
                LinearGradient(colors: [Color.green, Color.green.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
            // Navigation destinations
            .navigationDestination(isPresented: $showCareer) {
                ModeSelectionView()
                    .environmentObject(authViewModel)
            }
            .navigationDestination(isPresented: $showPractice) {
                PracticeSelectionView()
                    .environmentObject(authViewModel)
            }
            .navigationDestination(isPresented: $showLeaderboard) {
                LeaderboardView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
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
