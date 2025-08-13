//
//  CareerGameView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import SwiftUI

struct CareerGameView: View {
    @StateObject var careerManager: CareerManager
    @StateObject private var game: GameEngine
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    let gameMode: GameMode

    @State private var showResults = false

    // Init accepts careerManager & authViewModel from above
    init(authViewModel: AuthViewModel, gameMode: GameMode, careerManager: CareerManager) {
        self.gameMode = gameMode
        _careerManager = StateObject(wrappedValue: careerManager)
        // Use currentLuckiness at init
        _game = StateObject(wrappedValue: GameEngine(seed: nil, luckiness: careerManager.currentLuckiness()))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("\(gameMode.rawValue) Career — \(careerManager.currentTier.rawValue)")
                .font(.title2.bold())
                .padding(.top)

            Text("Score Meter: \(authViewModel.scoreMeter)")
                .font(.subheadline)

            GameView(game: game, onGameEnd: handleGameEnd, mode: gameMode == .careerSingle ? .careerSingle : .careerAo3)
                .frame(maxHeight: .infinity)
        }
        .onAppear {
            // Restart the game fresh each time this view appears
            game.startNewGame(seed: nil, luckiness: careerManager.currentLuckiness())
        }
        .sheet(isPresented: $showResults) {
            CareerResultsView(manager: careerManager)
        }
    }

    private func handleGameEnd() {
        let score = game.calculateScore() + game.undosUsed
        let isWin = game.hasWon
        print("DEBUG: Calculated score: \(score), hasWon: \(isWin)")

        _ = careerManager.simulateCareerRound(playerScore: score, playerIsWin: isWin)

        showResults = true
    }
}
