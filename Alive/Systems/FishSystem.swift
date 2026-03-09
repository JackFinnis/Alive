//
//  FishSystem.swift
//  Alive
//
//  Created by Jack Finnis on 04/04/2025.
//

import RealityKit

final class FishSystem: System {
    private let deviceProvider = DeviceProvider()
    
    private let visualRange: Float      = 0.5
    private let protectedRange: Float   = 0.2
    private let visualRangeSquared: Float
    private let protectedRangeSquared: Float
    
    private let cohesionFactor: Float   = 0.25
    private let separationFactor: Float = 0.25
    private let alignmentFactor: Float  = 0.1
    private let avoidanceFactor: Float  = 0.05
    private let seekingFactor: Float    = 0.02
    private let scaredFactor: Float     = 2
    
    private let spatialGrid: SpatialGrid
    
    init(scene: Scene) {
        visualRangeSquared = pow(visualRange, 2)
        protectedRangeSquared = pow(protectedRange, 2)
        spatialGrid = SpatialGrid(cellSize: visualRange)
        Task {
            try? await deviceProvider.run()
        }
    }
    
    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        let device = deviceProvider.getTransform()?.position ?? .zero
        let fishes = context.entities(matching: .init(where: .has(FishComponent.self)), updatingSystemWhen: .rendering)
        let scaries = context.entities(matching: .init(where: .has(ScaryComponent.self)), updatingSystemWhen: .rendering)
        
        spatialGrid.clear()
        for fish in fishes {
            spatialGrid.insert(fish)
        }
        
        for fish in fishes {
            var newVelocity = fish.fishC.velocity
            
            var neighbours: Int = 0
            var cohesionSum: Vector = .zero
            var alignmentSum: Vector = .zero
            var separationSum: Vector = .zero
            
            let nearbyFish = spatialGrid.getNearby(fish.position)
            for otherFish in nearbyFish where otherFish != fish {
                let delta = fish.position - otherFish.position
                let distanceSquared = length_squared(delta)
                
                if distanceSquared < protectedRangeSquared {
                    separationSum += normalize(delta)
                } else if distanceSquared < visualRangeSquared && otherFish.fishC.type == fish.fishC.type {
                    cohesionSum += otherFish.position
                    alignmentSum += otherFish.fishC.velocity
                    neighbours += 1
                }
            }
            
            for direction in Vector.units {
                let hits = context.scene.raycast(
                    origin: fish.position,
                    direction: direction,
                    length: visualRange
                )
                for hit in hits where hit.entity.components.has(ObstacleComponent.self) {
                    let distance = max(hit.distance, visualRange / 10)
                    newVelocity += hit.normal / pow(distance / visualRange, 2) * avoidanceFactor * dt
                }
            }
            
            for scary in scaries {
                let distance = max(scary.position.distance(to: fish.position), scary.scaryC.radius / 5)
                if distance < scary.scaryC.radius {
                    newVelocity += scary.position.direction(to: fish.position) / pow(distance / scary.scaryC.radius, 2) * scaredFactor * dt
                }
            }
            
            if neighbours > 0 {
                let cohesionDelta = cohesionSum / Float(neighbours) - fish.position
                newVelocity += cohesionDelta * cohesionFactor * dt

                let alignmentDelta = alignmentSum / Float(neighbours) - fish.fishC.velocity
                newVelocity += alignmentDelta * alignmentFactor * dt
            }
            
            newVelocity += (device - fish.position) * seekingFactor * dt
            
            newVelocity += separationSum * separationFactor * dt
            
            if length(newVelocity) > fish.fishC.type.maxSpeed {
                newVelocity /= 1.03
            }
            if length(newVelocity) < 0.1 {
                newVelocity *= 1.1
            }
            
            let direction = normalize(newVelocity)
            if direction.y.magnitude > 0.7 {
                newVelocity.y /= 1.1
            }
            
            let newPosition = fish.position + newVelocity * Float(context.deltaTime)
            fish.setTransform(position: newPosition, forward: newVelocity, lerp: 0.1)
            fish.fishC.velocity = newVelocity
            fish.fishC.animation.speed = length(newVelocity) * fish.fishC.type.animationSpeed
        }
    }
}
