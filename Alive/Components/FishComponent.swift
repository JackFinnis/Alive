//
//  FishComponent.swift
//  Alive
//
//  Created by Jack Finnis on 05/04/2025.
//

import RealityKit

struct FishComponent: Component {
    let type: Fish
    let animation: AnimationPlaybackController
//    let audio: AudioPlaybackController
    var velocity: Vector
}

extension Entity {
    var fishC: FishComponent {
        get { components[FishComponent.self]! }
        set { components[FishComponent.self] = newValue }
    }
}
