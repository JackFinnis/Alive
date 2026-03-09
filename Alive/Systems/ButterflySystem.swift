//
//  ButterflySystem.swift
//  Alive
//
//  Created by Jack Finnis on 10/04/2025.
//

import RealityKit

final class ButterflySystem: System {
    let handProvider = HandProvider()
    
    init(scene: Scene) {
        Task {
            try? await handProvider.run()
        }
    }
    
    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        let butterflies = context.entities(matching: .init(where: .has(ButterflyComponent.self)), updatingSystemWhen: .rendering)
        
        for butterfly in butterflies {
            if let chirality = butterfly.butterflyC.curiousChirality {
                guard let indexTip = handProvider.getTransform(chirality, .indexFingerTip) else { continue }
                if butterfly.position.distance(to: indexTip.position) < 0.01 {
                    butterfly.butterflyC.path = []
                    let up = indexTip.right * (chirality == .left ? 1 : -1)
                    butterfly.setTransform(position: indexTip.position, up: up, forward: indexTip.forward)
                } else if butterfly.butterflyC.path.isEmpty {
                    butterfly.butterflyC.path = [indexTip.position]
                }
            }
            
            if let target = butterfly.butterflyC.path.first {
                let toTarget = target - butterfly.position
                let direction = normalize(toTarget)
                let distance = butterfly.butterflyC.speed * dt
                let position = butterfly.position + direction * distance
                
                butterfly.setTransform(position: position, forward: direction, lerp: 0.1)
                butterfly.butterflyC.animation.resume()
                
                if length(toTarget) < 0.01 {
                    butterfly.butterflyC.path.removeFirst()
                    if butterfly.butterflyC.path.isEmpty {
                        butterfly.setTransform(position: butterfly.position, up: butterfly.butterflyC.normal)
                    }
                }
            } else {
                butterfly.butterflyC.animation.pause()
                butterfly.butterflyC.animation.time = 0
            }
        }
    }
}
