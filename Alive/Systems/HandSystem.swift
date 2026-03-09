//
//  SpiderSystem.swift
//  Alive
//
//  Created by Jack Finnis on 10/04/2025.
//

import RealityKit

final class HandSystem: System {
    let handProvider = HandProvider()
    
    init(scene: Scene) {
        Task {
            try? await handProvider.run()
        }
    }
    
    func update(context: SceneUpdateContext) {
        let hands = context.entities(matching: .init(where: .has(HandComponent.self)), updatingSystemWhen: .rendering)
        for hand in hands {
            guard let transform = handProvider.getTransform(hand.handC.chirality, .indexFingerTip) else { continue }
            hand.position = transform.position
        }
    }
}
