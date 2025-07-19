//
//  ActionButtonStyle.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-07-18.
//

import SwiftUI

struct ActionButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
