//
//  CareerModeSelectionView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import SwiftUI

struct CareerModeSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var careerManager: CareerManager
    @State private var selectedTier: CareerManager.Tier = .local
    @State private var showGame = false

    let selectedMode: GameMode

    init(selectedMode: GameMode, authViewModel: AuthViewModel) {
        self.selectedMode = selectedMode
        _careerManager = StateObject(wrappedValue: CareerManager(authViewModel: authViewModel))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Career Tier for \(selectedMode.rawValue)")
                .font(.title).bold()
                .padding(.top)

            ForEach(CareerManager.Tier.allCases, id: \.self) { tier in
                Button {
                    selectedTier = tier
                    showGame = true
                    careerManager.currentTier = tier
                } label: {
                    Text(tier.rawValue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isUnlocked(tier) ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isUnlocked(tier))
            }

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $showGame) {
            if selectedMode == .careerSingle {
                GameView(game: GameEngine(), mode: .careerSingle, careerManager: careerManager)
            } else if selectedMode == .careerAo3 {
                Ao3GameView(mode: .careerAo3)
            }
        }
    }

    private func isUnlocked(_ tier: CareerManager.Tier) -> Bool {
        switch tier {
        case .local:
            return true
        case .provincial:
            return careerManager.hasQualified(for: .provincial)
        case .national:
            return careerManager.hasQualified(for: .national)
        case .global:
            return careerManager.hasQualified(for: .global)
        }
    }
}
