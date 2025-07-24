//
//  ScoreManager.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import FirebaseAuth
import FirebaseFirestore

struct ScoreManager {
    static func saveScore(to collection: String, score: Int, isWin: Bool = false) {
        guard let user = Auth.auth().currentUser else {
            print("❌ No user logged in.")
            return
        }

        let db = Firestore.firestore()
        let doc = db.collection(collection).document()

        // Get the username from Firestore
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"

            doc.setData([
                "userID": user.uid,
                "username": username,
                "score": score,
                "isWin": isWin,
                "timestamp": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Error saving score: \(error.localizedDescription)")
                } else {
                    print("✅ Score saved to \(collection): \(score)")
                }
            }
        }
    }
}
