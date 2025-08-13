//
//  ModeSelectionView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var navigateToSingles = false
    @State private var navigateToAO3 = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Select Game Mode")
                    .font(.largeTitle)
                    .bold()

                NavigationLink(
                    destination: CareerModeSelectionView(selectedMode: .careerSingle, authViewModel: authViewModel)
                        .environmentObject(authViewModel),
                    isActive: $navigateToSingles
                ) {
                    EmptyView()
                }

                NavigationLink(
                    destination: CareerModeSelectionView(selectedMode: .careerAo3, authViewModel: authViewModel)
                        .environmentObject(authViewModel),
                    isActive: $navigateToAO3
                ) {
                    EmptyView()
                }

                Button("Singles") {
                    navigateToSingles = true
                }
                .buttonStyle(.borderedProminent)

                Button("AO3") {
                    navigateToAO3 = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
