//
//  TounamentGameView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TournamentGameView: View {
    @StateObject private var game = GameEngine()
    @State private var gameCount = 1
    @State private var scores: [(score: Int, isWin: Bool)] = []
    @Environment(\.dismiss) var dismiss
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    var tournamentId: String  // passed in when launching the view

    var body: some View {
        VStack(spacing: 20) {
            Text("Tournament Game \(gameCount)/4")
                .font(.title)

            ContentView(game: game, onGameEnd: handleGameEnd, mode: .tournament)

            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
            saveTournamentAo3()
            dismiss()
        }
    }

    private func saveTournamentAo3() {
        guard scores.count == 4 else {
            print("❌ Not enough scores")
            return
        }

        guard let user = Auth.auth().currentUser else {
            print("❌ No user logged in.")
            return
        }

        let db = Firestore.firestore()
        let ao3sRef = db.collection("tournaments")
                        .document(tournamentId)
                        .collection("entries")
                        .document(user.uid)
                        .collection("ao3s")

        // First: check how many Ao3s this user already submitted
        ao3sRef.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching Ao3 entries: \(error.localizedDescription)")
                return
            }

            let existingCount = snapshot?.documents.count ?? 0
            if existingCount >= 5 {
                // Show alert to user (main thread)
                DispatchQueue.main.async {
                    showAlert(title: "Limit Reached", message: "You've already submitted your 5 Ao3s for this tournament.")
                    dismiss()
                }
                return
            }

            // Prepare score data
            let rawScores = scores.map { $0.score }
            let bestThree = Array(rawScores.sorted().prefix(3))
            let average = Double(bestThree.reduce(0, +)) / 3.0
            let winCount = scores.filter { $0.isWin }.count

            // Get username
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                let username = snapshot?.data()?["username"] as? String ?? "Unknown"

                let ao3Data: [String: Any] = [
                    "scores": rawScores,
                    "wins": winCount,
                    "ao3": average,
                    "timestamp": Timestamp(date: Date()),
                    "userID": user.uid,
                    "username": username
                ]

                // Save new Ao3 in the user's ao3s subcollection
                ao3sRef.addDocument(data: ao3Data) { error in
                    if let error = error {
                        print("❌ Error saving Ao3: \(error.localizedDescription)")
                    } else {
                        print("✅ Ao3 saved for tournament:", tournamentId)
                        dismiss()
                    }
                }
            }
        }
    }
}
