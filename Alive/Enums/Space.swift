//
//  Space.swift
//  Alive
//
//  Created by Jack Finnis on 07/04/2025.
//

import RealityKit
import SwiftUI

enum Space: String, CaseIterable, Codable {
    case fish
    case spider
    case butterfly
    
    var file: File {
        switch self {
        case .fish:     return .clownfish
        case .spider:   return .spider
        case .butterfly:return .butterfly
        }
    }
    
    var name: String {
        switch self {
        case .fish:     return "The Aquarium"
        case .spider:   return "The Cavern"
        case .butterfly:return "The Meadow"
        }
    }
    
    var warning: String {
        switch self {
        case .fish:     return "Hold your breath—"
        case .spider:   return "Get ready to jump!"
        case .butterfly:return "Approach with care..."
        }
    }
    
    var icon: ImageResource {
        switch self {
        case .fish:     return .aquarium// https://www.flaticon.com/free-icon/starfish_8715119
        case .spider:   return .cavern  // https://www.flaticon.com/free-icon/spider-web_2250473
        case .butterfly:return .meadow  // https://www.flaticon.com/free-icon/lily_15019107
        }
    }
    
    var instructions: [String] {
        switch self {
        case .fish:
            return [
                "Tap to spawn fish",
                "Try to catch one!",
                "Keep tapping to attract a guest...",
            ]
        case .spider:
            return [
                "Tap to feed the spiders",
                "Are you brave enough to touch one?",
                "Whatever you do, don't clap!",
            ]
        case .butterfly:
            return [
                "Tap to spawn butterflies",
                "Point upwards to make a friend...",
                "Clap to break the stillness"
            ]
        }
    }
}

#Preview {
    SpaceIntro(space: .fish)
}

#Preview {
    SpacePicker()
}
