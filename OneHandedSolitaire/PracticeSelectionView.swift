//
//  PracticeSelectionView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import SwiftUI

struct PracticeSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSingle = false
    @State private var showAo3 = false
    @State private var showDaily = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Practice")
                .font(.title).bold()
                .padding(.top)

            NavigationLink(destination: GameView(game: GameEngine(), mode: .practiceSingle),
                           isActive: $showSingle) {
                Button("Singles") { showSingle = true }
                    .buttonStyle(HomeButtonStyle())
            }

            NavigationLink(destination: Ao3GameView(mode: .practiceAo3),
                           isActive: $showAo3) {
                Button("Ao3 (Best 3 of 4)") { showAo3 = true }
                    .buttonStyle(HomeButtonStyle())
            }

            NavigationLink(destination: DailyChallengeView(),
                           isActive: $showDaily) {
                Button("Daily Challenge") { showDaily = true }
                    .buttonStyle(HomeButtonStyle())
            }

            Spacer()
        }
        .padding()
    }
}
