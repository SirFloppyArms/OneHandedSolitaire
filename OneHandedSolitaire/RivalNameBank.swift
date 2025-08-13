//
//  RivalNameBank.swift
//  OneHandedSolitaire
//
//  Created by Nolan Law on 2025-08-12.
//

import Foundation

final class RivalNameBank {
    static let shared = RivalNameBank()
    // a mixed list of realistic names with some recurring flair
    let namePool: [String] = [
        "Alex Mercer","Samira Nadeem","Jonas Reed","Priya Patel","Leo Carter",
        "Maya Ortega","Ethan Blake","Zara Noor","Oliver Finch","Nora Quinn",
        "Hugo Park","Ivy Sato","Caleb Stone","Lena Russo","Mateo Cruz",
        "Riley Brooks","Sofia Lane","Marcus Vale","Tess Harper","Owen Price",
        "Ava Morgan","Noah Briggs","Mila Rivers","Kai Fisher","Amir Khan",
        "Elena Voss","Theo Lang","Grace Holloway","Ian Murphy","Chloe Bennett",
        // repeat patterns allowed; pool can be extended
    ]
    private init() {}
}
