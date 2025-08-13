//
//  Ao3GameView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Ao3GameView: View {
    @StateObject private var game = GameEngine()
    @State private var gameCount = 1
    @State private var scores: [(score: Int, isWin: Bool)] = []
    @Environment(\.dismiss) var dismiss

    var mode: GameMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Game \(gameCount)/4")
                .font(.title)

            GameView(game: game, onGameEnd: handleGameEnd, mode: mode)

            Spacer()
        }
    }

    // Saves to either practice or career leaderboard
    private func saveAo3Score() {
        guard scores.count == 4 else {
            print("❌ Not enough scores")
            return
        }

        let rawScores = scores.map { $0.score }
        let sorted = rawScores.sorted()
        let bestThree = Array(sorted.prefix(3))
        let average = Double(bestThree.reduce(0, +)) / 3.0
        let winCount = scores.filter { $0.isWin }.count

        guard let user = Auth.auth().currentUser else {
            print("❌ No user logged in.")
            return
        }

        let db = Firestore.firestore()
        let collectionPath: CollectionReference

        if mode == .careerAo3 {
            collectionPath = db.collection("career").document("ao3").collection("results")
        } else { // practice Ao3
            collectionPath = db.collection("practice").document("ao3").collection("results")
        }

        let doc = collectionPath.document()

        db.collection("users").document(user.uid).getDocument { snapshot, _ in
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"

            doc.setData([
                "userID": user.uid,
                "username": username,
                "scores": rawScores,
                "wins": winCount,
                "ao3": average,
                "timestamp": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Error saving Ao3: \(error.localizedDescription)")
                } else {
                    print("✅ \(mode) Ao3 saved:", average, "from scores:", scores)
                }
            }
        }
    }

    private func handleGameEnd() {
        let score = game.calculateScore() + game.undosUsed
        let isWin = game.hasWon
        scores.append((score, isWin))

        if gameCount < 4 {
            gameCount += 1
            game.startNewGame()
        } else {
            saveAo3Score()
            dismiss()
        }
    }
}
