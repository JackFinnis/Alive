//
//  VelocitySystem.swift
//  Alive
//
//  Created by Jack Finnis on 10/04/2025.
//

import RealityKit

final class VelocitySystem: System {
    init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        let entities = context.entities(matching: .init(where: .has(VelocityComponent.self)), updatingSystemWhen: .rendering)
        
        for entity in entities {
            if entity.velocityC.deleteAfter < .now {
                entity.removeFromParent()
            }
            
            let newPosition = entity.position + entity.velocityC.velocity * dt
            entity.setTransform(position: newPosition, up: entity.transform.matrix.up, forward: entity.velocityC.velocity)
        }
    }
}
