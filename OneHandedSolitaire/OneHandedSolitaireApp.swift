//
//  OneHandedSolitaireApp.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import SwiftUI
import Firebase

@main
struct OneHandedSolitaireApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AuthGateView()
        }
    }
}
