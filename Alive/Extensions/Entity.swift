//
//  Entity.swift
//  Alive
//
//  Created by Jack Finnis on 19/04/2025.
//

import RealityKit

extension Entity {
    func setTransform(position newPosition: Vector, up: Vector = .up, forward: Vector? = nil, lerp: Float = 1) {
        let desiredForward: Vector
        if let forward {
            desiredForward = normalize(forward)
        } else {
            let randomDirection: Vector = normalize(.random(in: -1...1))
            desiredForward = normalize(randomDirection - dot(randomDirection, up) * up)
        }
        
        let worldRight = normalize(cross(up, desiredForward))
        let worldUp = cross(desiredForward, worldRight)
        let worldRotationMatrix = float3x3(columns: (worldRight, worldUp, desiredForward))
        
        let modelRight = normalize(cross(file.up, file.forward))
        let modelRotationMatrix = float3x3(columns: (modelRight, file.up, file.forward))
        
        let finalRotationMatrix = worldRotationMatrix * modelRotationMatrix.inverse
        let finalRotation = simd_quatf(finalRotationMatrix)

        let lerpRotation = simd_slerp(transform.rotation, finalRotation, lerp)
        
        transform.rotation = lerpRotation
        position = newPosition
    }
    
    func children(_ componentType: Component.Type) -> [Entity] {
        children.filter { $0.components.has(componentType) }
    }
}

@MainActor
extension Sequence where Element == Entity {
    func closest(to position: Vector) -> Entity? {
        self.min { $0.position.distanceSquared(to: position) < $1.position.distanceSquared(to: position) }
    }
    
    func furthest(from position: Vector) -> Entity? {
        self.max { $0.position.distanceSquared(to: position) < $1.position.distanceSquared(to: position) }
    }
}
