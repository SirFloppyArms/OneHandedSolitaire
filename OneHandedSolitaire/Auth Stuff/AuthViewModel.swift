//
//  AuthViewModel.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

// AuthViewModel additions & small edits
import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var errorMessage: String? = nil

    // NEW: Score meter 0..100
    @Published var scoreMeter: Int = 0

    private var db = Firestore.firestore()

    init() {
        self.isSignedIn = Auth.auth().currentUser != nil
        Auth.auth().addStateDidChangeListener { _, user in
            self.isSignedIn = user != nil
            if let user = user {
                self.fetchUserProfile(userID: user.uid)
            } else {
                self.scoreMeter = 0
            }
        }
    }

    func fetchUserProfile(userID: String) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.scoreMeter = data["scoreMeter"] as? Int ?? 0
                // If you later want to load friends or other profile fields, do that here.
            }
        }
    }

    // NEW: update Score Meter in Firestore
    func updateScoreMeter(to newValue: Int) {
        guard let user = Auth.auth().currentUser else { return }
        let bounded = max(0, min(100, newValue))
        self.scoreMeter = bounded
        db.collection("users").document(user.uid).setData(["scoreMeter": bounded], merge: true) { err in
            if let err = err {
                print("❌ Error saving scoreMeter: \(err.localizedDescription)")
            } else {
                print("✅ scoreMeter saved:", bounded)
            }
        }
    }

    // Existing signup — add default scoreMeter on new user creation
    func signUp(email: String, password: String, username: String) {
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                // Save username to Firestore with default scoreMeter
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "email": email,
                    "username": username,
                    "createdAt": Timestamp(),
                    "scoreMeter": 0
                ]) { err in
                    if let err = err {
                        print("❌ Error saving user info: \(err.localizedDescription)")
                    } else {
                        print("✅ User profile created with username: \(username)")
                        self.fetchUserProfile(userID: user.uid)
                    }
                }
            }
        }
    }

    // signIn and signOut unchanged, but ensure fetch on sign in
    func signIn(email: String, password: String) {
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                self.fetchUserProfile(userID: user.uid)
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
            self.scoreMeter = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
