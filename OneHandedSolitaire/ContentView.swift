//
//  ContentView.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import SwiftUI

struct ContentView: View {
    @StateObject var game = GameEngine()
    @State private var isDrawingCard = false
    @Namespace private var animation

    var body: some View {
        ZStack {
            // Optionally swap this to Image("felt_background").resizable() if you upload one
            LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    // 🎴 Deck cards behind
                    if !game.deck.isEmpty {
                        ForEach(0..<min(game.deck.count, 5), id: \.self) { i in
                            Image("")
                                .resizable()
                                .frame(width: 88, height: 130)
                                .offset(x: CGFloat(i) * 0.5, y: CGFloat(-i) * 2)
                                .shadow(radius: 1)
                        }
                    }

                    // 👁 Visible stack on top
                    FanView(cards: game.visibleStack, discardedCards: game.discardedCards, animation: animation)
                }

                Text("Cards Remaining in Deck: \(game.deck.count)")
                    .foregroundColor(.white)
                    .font(.subheadline)

                // Buttons
                HStack(spacing: 20) {
                    Button("Discard") {
                        withAnimation {
                            _ = game.tryDiscard()
                        }
                    }
                    .buttonStyle(ActionButtonStyle(color: .blue))

                    Button("Draw") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isDrawingCard = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            isDrawingCard = false
                            game.drawCard()
                        }
                    }
                    .buttonStyle(ActionButtonStyle(color: .green))

                    Button("Undo") {
                        // Add undo logic later
                    }
                    .buttonStyle(ActionButtonStyle(color: .gray))
                }
                .padding(.top, 10)
            }
            .padding()
            
            if isDrawingCard {
                Image("card_back")
                    .resizable()
                    .frame(width: 88, height: 130)
                    .offset(x: -UIScreen.main.bounds.width * 0.35, y: -180)
                    .transition(.move(edge: .top))
                    .animation(.easeInOut(duration: 0.25), value: isDrawingCard)
                    .zIndex(999)
            }
            
            ForEach(game.cardsBeingDiscarded, id: \.id) { card in
                CardView(card: card)
                    .frame(width: 88, height: 130)
                    .offset(x: UIScreen.main.bounds.width * 1.2, y: -40)
                    .rotationEffect(.degrees(30))
                    .opacity(0.0)
                    .animation(.easeInOut(duration: 0.6), value: game.cardsBeingDiscarded)
                    .transition(.asymmetric(insertion: .identity,
                                            removal: .move(edge: .trailing).combined(with: .opacity)))
                    .zIndex(1000)
            }
        }
    }
}
