//
//  ScoreManager.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import FirebaseAuth
import FirebaseFirestore

struct ScoreManager {
    private static var db: Firestore { Firestore.firestore() }
    
    // Save PRACTICE results (singles, ao3, daily)
    static func savePracticeResult(mode: String, score: Int, isWin: Bool = false, extraData: [String: Any] = [:]) {
        guard let user = Auth.auth().currentUser else {
            print("❌ No user logged in.")
            return
        }

        let doc = db.collection("practice").document(mode).collection("results").document()
        db.collection("users").document(user.uid).getDocument { snapshot, _ in
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"

            var data: [String: Any] = [
                "userID": user.uid,
                "username": username,
                "score": score,
                "isWin": isWin,
                "timestamp": Timestamp(date: Date())
            ]
            extraData.forEach { data[$0.key] = $0.value }

            doc.setData(data) { error in
                if let error = error {
                    print("❌ Error saving practice \(mode) result: \(error.localizedDescription)")
                } else {
                    print("✅ Practice \(mode) result saved:", data)
                }
            }
        }
    }

    // Save CAREER results (singles, ao3)
    static func saveCareerResult(mode: String, tier: String, placement: Int, score: Int, isWin: Bool = false, extraData: [String: Any] = [:]) {
        guard let user = Auth.auth().currentUser else { return }
        
        let doc = db.collection("career").document(mode).collection("results").document()
        db.collection("users").document(user.uid).getDocument { snapshot, _ in
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"

            var data: [String: Any] = [
                "userID": user.uid,
                "username": username,
                "tier": tier,
                "placement": placement,
                "score": score,
                "isWin": isWin,
                "timestamp": Timestamp(date: Date())
            ]
            extraData.forEach { data[$0.key] = $0.value }

            doc.setData(data) { error in
                if let error = error {
                    print("❌ Error saving career \(mode) result: \(error.localizedDescription)")
                } else {
                    print("✅ Career \(mode) result saved:", data)
                }
            }
        }
    }
}
