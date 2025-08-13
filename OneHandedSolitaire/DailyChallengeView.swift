//
//  DailyChallengeView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import SwiftUI

struct DailyChallengeView: View {
    @State private var hasPlayedToday = false
    @State private var todayScore: Int? = nil
    @State private var showGame = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Challenge")
                .font(.largeTitle).bold()
                .padding(.top)
            
            if let score = todayScore {
                Text("Your score today: \(score)")
                    .font(.title3)
                    .foregroundColor(.green)
            } else {
                Text("You haven’t played today’s challenge yet.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            NavigationLink(
                destination: GameView(game: GameEngine()),
                isActive: $showGame
            ) {
                Button(hasPlayedToday ? "Come Back Tomorrow" : "Start Challenge") {
                    showGame = true
                }
                .buttonStyle(HomeButtonStyle())
                .disabled(hasPlayedToday)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            todayScore = DailyChallengeManager.shared.todayScore
            hasPlayedToday = todayScore != nil
        }
    }
}

final class DailyChallengeManager {
    static let shared = DailyChallengeManager()
    
    private let scoreKey = "DailyChallengeScore"
    private let dateKey = "DailyChallengeDate"
    
    var todayScore: Int? {
        guard let storedDate = UserDefaults.standard.string(forKey: dateKey),
              storedDate == currentDateString() else { return nil }
        return UserDefaults.standard.value(forKey: scoreKey) as? Int
    }
    
    func saveScore(_ score: Int) {
        UserDefaults.standard.set(score, forKey: scoreKey)
        UserDefaults.standard.set(currentDateString(), forKey: dateKey)
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

