//
//  CareerManager.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class CareerManager: ObservableObject {
    enum Tier: String, CaseIterable, Codable, Comparable {
        case local = "Local"
        case provincial = "Provincial"
        case national = "National"
        case global = "Global"
        
        static func < (lhs: Tier, rhs: Tier) -> Bool {
            guard let lhsIndex = allCases.firstIndex(of: lhs),
                let rhsIndex = allCases.firstIndex(of: rhs) else {
                return false
            }
            return lhsIndex < rhsIndex
        }
        
        // number of AI opponents (including player => totalPlayers)
        var playerCount: Int {
            switch self {
            case .local: return 16   // ~15 AI + you
            case .provincial: return 16
            case .national: return 16
            case .global: return 16
            }
        }
    }

    struct Rival: Identifiable, Codable, Equatable {
        let id: String
        var name: String
        var seed: Int // for optional future determinism / personality
    }

    // Published
    @Published var currentTier: Tier = .local
    @Published var currentPlacement: Int = 0
    @Published var rivals: [Rival] = []
    @Published var lastStandings: [(name: String, score: Int, isYou: Bool)] = []
    @Published var lastPlacement: Int? = nil
    
    // Ao3 tracking
    @Published private(set) var ao3Scores: [(score: Int, isWin: Bool)] = []
    private let ao3TotalRounds = 4
    private var ao3CurrentRound = 0

    // Dependencies
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private weak var authVM: AuthViewModel?

    // RNG
    private var rng = SystemRandomNumberGenerator()

    init(authViewModel: AuthViewModel) {
        self.authVM = authViewModel
        loadOrCreateRivals()
    }
    
    // Call this to record each Ao3 subgame
    func recordAo3Round(score: Int, isWin: Bool) {
        ao3Scores.append((score, isWin))
        ao3CurrentRound += 1

        if ao3CurrentRound >= ao3TotalRounds {
            saveAo3CareerResult()
            resetAo3()
        }
    }

    private func resetAo3() {
        ao3Scores.removeAll()
        ao3CurrentRound = 0
    }

    private func saveAo3CareerResult() {
        guard ao3Scores.count == ao3TotalRounds,
            let user = Auth.auth().currentUser else { return }

        let rawScores = ao3Scores.map { $0.score }
        let sortedScores = rawScores.sorted()
        let bestThree = Array(sortedScores.prefix(3))
        let average = Double(bestThree.reduce(0, +)) / 3.0
        let winCount = ao3Scores.filter { $0.isWin }.count

        let db = Firestore.firestore()
        let doc = db.collection("career_ao3").document()

        db.collection("users").document(user.uid).getDocument { snapshot, error in
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"

            doc.setData([
                "userID": user.uid,
                "username": username,
                "scores": rawScores,
                "wins": winCount,
                "ao3_average": average,
                "tier": self.currentTier.rawValue,
                "timestamp": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Error saving Ao3 career result: \(error.localizedDescription)")
                } else {
                    print("✅ Ao3 career result saved:", average)
                }
            }
        }
    }
    
    func hasQualified(for tier: Tier) -> Bool {
        switch tier {
        case .local:
            return true
        case .provincial:
            return highestTierReached() >= .local && top4In(.local)
        case .national:
            return highestTierReached() >= .provincial && top4In(.provincial)
        case .global:
            return highestTierReached() >= .national && top4In(.national)
        }
    }

    private func highestTierReached() -> Tier {
        // Fetch from user defaults or Firestore; fallback to current tier
        return currentTier
    }

    private func top4In(_ tier: Tier) -> Bool {
        // Check saved placements in Firestore or locally
        // Here’s a dummy check for now:
        return lastPlacement != nil && lastPlacement! <= 4
    }

    // MARK: - Rival generation & persistence

    private func loadOrCreateRivals() {
        guard let user = Auth.auth().currentUser else {
            // create local-only rivals if not signed in
            self.rivals = Self.makeRivals(count: 15)
            return
        }

        let docRef = db.collection("users").document(user.uid)
        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let raw = data["careerRivals"] as? [[String: Any]] {
                // load persisted rivals
                let loaded: [Rival] = raw.compactMap { dict in
                    if let id = dict["id"] as? String,
                       let name = dict["name"] as? String,
                       let seed = dict["seed"] as? Int {
                        return Rival(id: id, name: name, seed: seed)
                    }
                    return nil
                }
                if loaded.count >= 8 {
                    DispatchQueue.main.async {
                        self.rivals = loaded
                    }
                    return
                }
            }
            // otherwise create new and persist
            let created = Self.makeRivals(count: 15)
            DispatchQueue.main.async {
                self.rivals = created
            }
            let serial = created.map { ["id": $0.id, "name": $0.name, "seed": $0.seed] }
            docRef.setData(["careerRivals": serial], merge: true)
        }
    }

    static private func makeRivals(count: Int) -> [Rival] {
        let namePool = RivalNameBank.shared.namePool
        var rng = SystemRandomNumberGenerator()
        var result: [Rival] = []
        var used = Set<String>()
        var idx = 0
        while result.count < count {
            let candidate = namePool.randomElement(using: &rng) ?? "Player \(result.count+1)"
            if used.contains(candidate) { continue }
            used.insert(candidate)
            let r = Rival(id: UUID().uuidString, name: candidate, seed: Int.random(in: 1...10_000))
            result.append(r)
            idx += 1
        }
        return result
    }

    // MARK: - Difficulty tables (based on your vision)

    private func difficultyRange(for tier: Tier) -> (min: Int, max: Int, distributionBias: Double) {
        switch tier {
        case .local:
            return (-10, 25, 0.4) // lower is better in your scoring (score = remaining - bonuses)
        case .provincial:
            return (-8, 18, 0.4)
        case .national:
            return (-6, 14, 0.7)
        case .global:
            return (-5, 10, 0.8)
        }
    }

    // MARK: - Simulate a career competition round

    /// Simulates one Career competition for the current tier.
    /// - Parameters:
    ///   - playerScore: your final numeric score (lower is better).
    ///   - playerIsWin: whether the game was a win (all cards cleared).
    /// - Returns: standings array sorted ascending by score (best first)
    func simulateCareerRound(playerScore: Int, playerIsWin: Bool) -> [(name: String, score: Int, isYou: Bool)] {
        // generate AI scores according to tier difficulty
        let totalPlayers = currentTier.playerCount
        var entries: [(name: String, score: Int, isYou: Bool)] = []

        // compute base difficulty
        let range = difficultyRange(for: currentTier)
        // We'll create approx (totalPlayers - 1) AI scores
        for i in 0..<(totalPlayers - 1) {
            let rival = i < rivals.count ? rivals[i] : Rival(id: UUID().uuidString, name: "Rival \(i+1)", seed: Int.random(in: 1...9999))
            // Create score around random distribution with tier bias
            // convert to Double baseline then round to Int
            let base = Double(range.min)
            let spread = Double(range.max - range.min)
            // bias factor: some rivals are stronger/weaker based on seed
            let seedFactor = Double((rival.seed % 100)) / 100.0 // 0..1
            // mean around base + mid-spread shifted by seedFactor
            let mean = base + spread * (0.4 + (1.0 - range.distributionBias) * (seedFactor - 0.5))
            // variance small for higher tiers
            let variance = max(1.0, spread * (1.0 - range.distributionBias) * 0.45)
            let raw = mean + (Double.random(in: -1...1) * variance)
            let aiScore = Int(round(raw))
            entries.append((name: rival.name, score: aiScore, isYou: false))
        }

        // Add player
        entries.append((name: "You", score: playerScore, isYou: true))

        // sort ascending (lower scores better)
        entries.sort { a, b in
            if a.score != b.score { return a.score < b.score }
            // tie-breaker: earlier created (stable) - keep deterministic order
            return a.name < b.name
        }

        // save standings & placement
        DispatchQueue.main.async {
            self.lastStandings = entries.map { ($0.name, $0.score, $0.isYou) }
            if let idx = entries.firstIndex(where: { $0.isYou }) {
                self.lastPlacement = idx + 1
            } else { self.lastPlacement = nil }
        }

        // update ScoreMeter via AuthViewModel
        if let placement = entries.firstIndex(where: { $0.isYou }) {
            let place = placement + 1
            applyScoreMeterChange(afterPlacement: place, totalPlayers: totalPlayers, didWin: playerIsWin)
        }

        // persist career result to Firestore (collection per tier)
        saveCareerResultToFirestore(standings: entries)

        return entries
    }

    // MARK: - ScoreMeter formula & update

    private func applyScoreMeterChange(afterPlacement placement: Int, totalPlayers: Int, didWin: Bool) {
        // placementFactor 0..1 (1 best)
        let placementFactor = (Double(totalPlayers) - Double(placement)) / Double(max(1, totalPlayers - 1))
        let winBonus = didWin ? 0.15 : 0.0

        // core delta balanced to move meter slowly (range roughly -12 .. +20)
        let delta = ((placementFactor * 0.25) + winBonus - 0.1) * 100.0

        // round to Int
        let change = Int(round(delta))

        // pass to AuthViewModel (which persists)
        DispatchQueue.main.async {
            if let auth = self.authVM {
                let current = auth.scoreMeter
                let newVal = max(0, min(100, current + change))
                auth.updateScoreMeter(to: newVal)
            }
        }
    }

    // Compute luckiness L = 1 + (ScoreMeter / 100) * 0.15
    func currentLuckiness() -> Double {
        let meter = Double(authVM?.scoreMeter ?? 0)
        return 1.0 + (meter / 100.0) * 0.15
    }

    // MARK: - Tier progression

    /// Call this after simulateCareerRound to advance if eligible.
    /// advancement rule: top 4 advance (per your vision)
    func advanceTierIfEligible() {
        guard let placement = lastPlacement else { return }
        if placement <= 4 {
            // move to next tier if exists
            if let idx = Tier.allCases.firstIndex(of: currentTier), idx < Tier.allCases.count - 1 {
                currentTier = Tier.allCases[idx + 1]
            }
        }
    }

    // MARK: - Persistence for career results

    private func saveCareerResultToFirestore(standings: [(name: String, score: Int, isYou: Bool)]) {
        guard let user = Auth.auth().currentUser else { return }
        let collection = "career_\(currentTier.rawValue.lowercased())"
        let db = Firestore.firestore()
        let doc = db.collection(collection).document()

        // compute player's placement & wins
        let playerEntry = standings.first(where: { $0.isYou })
        let placement = standings.firstIndex(where: { $0.isYou }) ?? -1
        let score = playerEntry?.score ?? 9999
        let isWin = (playerEntry?.score == 0) // conservative check; adapt if your hasWon flag differs

        // username
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"
            doc.setData([
                "userID": user.uid,
                "username": username,
                "score": score,
                "placement": placement,
                "isWin": isWin,
                "tier": self.currentTier.rawValue,
                "timestamp": Timestamp(date: Date())
            ])
        }
    }
}
