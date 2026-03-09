//
//  SpiderComponent.swift
//  Alive
//
//  Created by Jack Finnis on 08/04/2025.
//

import ARKit
import RealityKit

struct SpiderComponent: Component {
    let speed: Float
    let animation: AnimationPlaybackController
    var path: [Vertex] = []
    var isFalling: Bool = false
    var fallingVelocity: Vector = .zero
    var curiousChirality: HandAnchor.Chirality? = nil
    
    var isStationary: Bool {
        path.isEmpty && curiousChirality == nil && !isFalling
    }
    
    @MainActor
    mutating func drop(initialVelocity: Vector = .zero) {
        isFalling = true
        fallingVelocity = initialVelocity
        if let curiousChirality {
            Model.shared.curiousChiralities.remove(curiousChirality)
        }
        curiousChirality = nil
    }
}

extension Entity {
    var spiderC: SpiderComponent {
        get { components[SpiderComponent.self]! }
        set { components[SpiderComponent.self] = newValue }
    }
}
