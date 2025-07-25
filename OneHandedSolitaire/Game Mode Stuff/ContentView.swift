//
//  ContentView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var game: GameEngine
    @Environment(\.dismiss) var dismiss
    @State private var scoreSaved = false
    @State private var showQuitAlert = false
    @Namespace private var animation
    var onGameEnd: (() -> Void)? = nil
    var mode: GameMode = .single
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.85)]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Deck & Fan
                    ZStack(alignment: .bottomLeading) {
                        if !game.deck.isEmpty {
                            ForEach(0..<min(game.deck.count, 5), id: \.self) { i in
                                Image("card_back")
                                    .resizable()
                                    .frame(width: 88, height: 130)
                                    .offset(x: CGFloat(i) * 0.5, y: CGFloat(-i) * 2)
                                    .shadow(radius: 1)
                            }
                        }

                        ZStack {
                            FanView(cards: game.visibleStack, discardedCards: game.discardedCards, animation: animation)

                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(
                                    TapGesture()
                                        .onEnded {
                                            withAnimation {
                                                game.drawCard()
                                            }
                                        }
                                )
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 30)
                                        .onEnded { value in
                                            let horizontal = value.translation.width
                                            withAnimation {
                                                if horizontal > 30 {
                                                    if game.visibleStack.count >= 4 {
                                                        let top4 = Array(game.visibleStack.suffix(4))
                                                        if (top4[0].value == top4[3].value) ||
                                                            (top4[0].suit == top4[1].suit &&
                                                             top4[1].suit == top4[2].suit &&
                                                             top4[2].suit == top4[3].suit) {
                                                            _ = game.tryDiscard()
                                                        }
                                                    }
                                                } else if horizontal < -30 {
                                                    if game.visibleStack.count >= 4 {
                                                        let top4 = Array(game.visibleStack.suffix(4))
                                                        if top4[0].suit == top4[3].suit {
                                                            _ = game.tryDiscard()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                )
                        }
                    }

                    // Stats
                    HStack(spacing: 20) {
                        statCard(title: "Undos", value: "\(game.undosUsed)", icon: "arrow.uturn.backward")
                        statCard(title: "Score", value: "\(game.calculateScore() + game.undosUsed)", icon: "chart.bar.fill")
                        statCard(title: "Clears", value: "\(game.clears)", icon: "sparkles")
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)

                    // Buttons
                    HStack(spacing: 12) {
                        GameButton(title: "↩️ Undo", color: .gray) {
                            withAnimation { game.undo() }
                        }
                        .disabled(game.gameOver)

                        GameButton(title: "🏁 End", color: .red) {
                            endGameAndReturnHome()
                        }
                        .disabled(!game.isDeckEmpty && !game.gameOver)

                        GameButton(title: "🚪 Quit", color: .orange) {
                            showQuitAlert = true
                        }
                    }
                    .padding(.top)

                    Spacer()
                }
                .padding(.top, 20)
                .frame(width: geo.size.width)

                // Discard animation
                ForEach(game.cardsBeingDiscarded, id: \.id) { card in
                    CardView(card: card)
                        .frame(width: 88, height: 130)
                        .offset(x: geo.size.width * 1.2, y: -40)
                        .rotationEffect(.degrees(30))
                        .opacity(0.0)
                        .animation(.easeInOut(duration: 0.6), value: game.cardsBeingDiscarded)
                        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .trailing).combined(with: .opacity)))
                        .zIndex(1000)
                }
            }
            .alert("Quit Game?", isPresented: $showQuitAlert) {
                Button("Yes", role: .destructive) {
                    game.startNewGame()
                    scoreSaved = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.85))
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.15))
        .cornerRadius(14)
    }

    private func GameButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }

    private func endGameAndReturnHome() {
        withAnimation {
            game.endGame()
        }

        if !scoreSaved && mode == .single {
            let score = game.calculateScore() + game.undosUsed
            let isWin = game.hasWon
            ScoreManager.saveScore(to: "singles", score: score, isWin: isWin)
            scoreSaved = true
            print("✅ Score saved to singles:", score, "Win:", isWin)
        } else {
            print("⛔️ Not saving to singles due to mode =", mode)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            scoreSaved = false

            if mode == .single {
                game.startNewGame()
            }

            onGameEnd?() ?? dismiss()
        }
    }
}
