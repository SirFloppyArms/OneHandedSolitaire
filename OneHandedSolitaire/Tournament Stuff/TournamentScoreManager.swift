//
//  TournamentScoreManager.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-23.
//

import FirebaseAuth
import FirebaseFirestore

struct TournamentScoreManager {
    static func submitEntry(to tournamentID: String, scores: [Int]) {
        guard scores.count == 5 else {
            print("❌ Exactly 5 scores are required.")
            return
        }

        guard let user = Auth.auth().currentUser else {
            print("❌ No user logged in.")
            return
        }

        let ao3 = Double(scores.reduce(0, +)) / 3.0
        let db = Firestore.firestore()

        db.collection("users").document(user.uid).getDocument { snapshot, error in
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"
            let data: [String: Any] = [
                "userID": user.uid,
                "username": username,
                "scores": scores,
                "ao3": ao3,
                "timestamp": Timestamp(date: Date())
            ]

            db.collection("tournaments")
                .document(tournamentID)
                .collection("entries")
                .addDocument(data: data) { error in
                    if let error = error {
                        print("❌ Error saving tournament entry: \(error.localizedDescription)")
                    } else {
                        print("✅ Tournament entry submitted!")
                    }
                }
        }
    }
}
