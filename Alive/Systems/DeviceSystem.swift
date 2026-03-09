//
//  SpiderSystem.swift
//  Alive
//
//  Created by Jack Finnis on 10/04/2025.
//

import RealityKit

final class DeviceSystem: System {
    let deviceProvider = DeviceProvider()
    
    init(scene: Scene) {
        Task {
            try? await deviceProvider.run()
        }
    }
    
    func update(context: SceneUpdateContext) {
        let devices = context.entities(matching: .init(where: .has(DeviceComponent.self)), updatingSystemWhen: .rendering)
        for device in devices {
            guard let transform = deviceProvider.getTransform() else { continue }
            device.position = transform.position
            device.position.y = personHeight/2
        }
    }
}
