//
//  SharkComponent.swift
//  Alive
//
//  Created by Jack Finnis on 22/04/2025.
//

import RealityKit
import Foundation

struct SharkComponent: Component {
    let animation: AnimationPlaybackController
    var velocity: Vector = .zero
    var target: Entity
    var targetSince: Date = .now
}

extension Entity {
    var sharkC: SharkComponent {
        get { components[SharkComponent.self]! }
        set { components[SharkComponent.self] = newValue }
    }
}
