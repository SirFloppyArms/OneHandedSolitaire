//
//  AuthGateView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-19.
//

import SwiftUI

struct AuthGateView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                HomeView()
            } else {
                SignInView()
            }
        }
        .environmentObject(authViewModel)
    }
}
