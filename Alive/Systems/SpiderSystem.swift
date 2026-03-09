//
//  SpiderSystem.swift
//  Alive
//
//  Created by Jack Finnis on 10/04/2025.
//

import RealityKit

final class SpiderSystem: System {
    let handProvider = HandProvider()
    
    init(scene: Scene) {
        Task {
            try? await handProvider.run()
        }
    }
    
    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        let spiders = context.entities(matching: .init(where: .has(SpiderComponent.self)), updatingSystemWhen: .rendering)
        
        for spider in spiders {
            if let chirality = spider.spiderC.curiousChirality {
                guard let middleKnuckle = handProvider.getTransform(chirality, .middleFingerKnuckle),
                      let thumbKnuckle = handProvider.getTransform(chirality, .thumbKnuckle),
                      let wrist = handProvider.getTransform(chirality, .forearmWrist)
                else {
                    spider.spiderC.drop()
                    continue
                }
                
                let up = thumbKnuckle.forward * (chirality == .left ? -1 : 1)
                let forward = (wrist.position + up * 0.02) - middleKnuckle.position
                let position = middleKnuckle.position + 0.01 * up
                let distance = spider.position.distance(to: position)
                let isDropping = handProvider.isDropping(chirality: chirality)
                
                if spider.spiderC.path.isNotEmpty {
                    if isDropping || distance > 0.2 {
                        spider.spiderC.drop()
                    } else {
                        spider.spiderC.path = [.init(position: position, normal: up)]
                    }
                } else {
                    if isDropping || distance > 0.03 {
                        spider.spiderC.drop(initialVelocity: (position - spider.position) * 60)
                    } else {
                        spider.setTransform(position: position, up: up, forward: forward)
                    }
                }
            }
            
            if spider.spiderC.isFalling {
                let newVelocity = spider.spiderC.fallingVelocity + .down * 8 * dt
                let newPosition = spider.position + newVelocity * dt
                spider.spiderC.path = []
                spider.spiderC.fallingVelocity = newVelocity
                spider.setTransform(position: newPosition, forward: newVelocity)
                
                let hits = context.scene.raycast(
                    origin: spider.position,
                    direction: normalize(newVelocity),
                    length: 0.1
                )
                if let hit = hits.first(where: { $0.entity.components.has(ObstacleComponent.self) }) {
                    spider.setTransform(position: hit.position, up: hit.normal)
                    spider.spiderC.isFalling = false
                    spider.spiderC.fallingVelocity = .zero
                }
            } else if let target = spider.spiderC.path.first {
                let toTarget = target.position - spider.position
                let direction = normalize(toTarget)
                let distance = spider.spiderC.speed * dt
                let position = spider.position + direction * distance
                
                if length(toTarget) < 0.01 {
                    spider.spiderC.path.removeFirst()
                }
                
                spider.setTransform(position: position, up: target.normal, forward: direction, lerp: spider.spiderC.path.isEmpty ? 1 : 0.2)
                spider.spiderC.animation.resume()
            } else {
                spider.spiderC.animation.pause()
            }
        }
    }
}
