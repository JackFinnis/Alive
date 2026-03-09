//
//  ButterflyComponent.swift
//  Alive
//
//  Created by Jack Finnis on 22/04/2025.
//

import ARKit
import RealityKit

struct ButterflyComponent: Component {
    let speed: Float
    let animation: AnimationPlaybackController
//    let audio: AudioPlaybackController
    var path: [Vector] = []
    var normal: Vector
    var curiousChirality: HandAnchor.Chirality? = nil
    
    var isStationary: Bool {
        path.isEmpty && curiousChirality == nil
    }
}

extension Entity {
    var butterflyC: ButterflyComponent {
        get { components[ButterflyComponent.self]! }
        set { components[ButterflyComponent.self] = newValue }
    }
}
