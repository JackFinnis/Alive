//
//  SharkSystem.swift
//  Alive
//
//  Created by Jack Finnis on 11/04/2025.
//

import RealityKit

@MainActor
final class SharkSystem: System {
    private let visualRange: Float = 1.0
    private let maxSpeed: Float = 0.5
    private let minSpeed: Float = 0.1
    
    private let seekingFactor: Float = 0.1
    private let avoidanceFactor: Float = 0.1
    private let scaredFactor: Float = 2
    
    init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        let fishes = context.entities(matching: .init(where: .has(FishComponent.self)), updatingSystemWhen: .rendering).map(\.self)
        let sharks = context.entities(matching: .init(where: .has(SharkComponent.self)), updatingSystemWhen: .rendering)
        let scaries = context.entities(matching: .init(where: .has(ScaryComponent.self)), updatingSystemWhen: .rendering)
        guard fishes.isNotEmpty else { return }
        
        for shark in sharks {
            var newVelocity = shark.sharkC.velocity
            
            var nearObstacle = false
            for direction in Vector.units {
                let hits = context.scene.raycast(
                    origin: shark.position,
                    direction: direction,
                    length: visualRange
                )
                
                for hit in hits where hit.entity.components.has(ObstacleComponent.self) {
                    nearObstacle = true
                    let distance = max(hit.distance, visualRange / 10)
                    newVelocity += hit.normal / pow(distance / visualRange, 2) * avoidanceFactor * dt
                }
            }
            
            if nearObstacle && shark.sharkC.targetSince.distance(to: .now) > 1 {
                shark.sharkC.target = fishes.randomElement()!
                shark.sharkC.targetSince = .now
            }
            
            let targetDelta = shark.sharkC.target.position - shark.position
            newVelocity += targetDelta * seekingFactor * dt
            
            for scary in scaries where scary != shark {
                let distance = max(scary.position.distance(to: shark.position), scary.scaryC.radius / 5)
                if distance < scary.scaryC.radius {
                    newVelocity += scary.position.direction(to: shark.position) / pow(distance / scary.scaryC.radius, 2) * scaredFactor * dt
                }
            }
            
            if length(newVelocity) > maxSpeed {
                newVelocity /= 1.03
            }
            
            let speed = length(newVelocity)
            if speed < minSpeed {
                newVelocity = normalize(newVelocity) * minSpeed
            }
            
            let direction = normalize(newVelocity)
            if direction.y.magnitude > 0.7 {
                newVelocity.y /= 1.1
            }
            
            let newPosition = shark.position + newVelocity * dt
            shark.setTransform(position: newPosition, forward: newVelocity, lerp: 0.02)
            shark.sharkC.animation.speed = length(newVelocity) * 4
            shark.sharkC.velocity = newVelocity
        }
    }
}
