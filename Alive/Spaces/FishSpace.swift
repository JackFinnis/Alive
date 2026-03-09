//
//  FishSpace.swift
//  Alive
//
//  Created by Jack Finnis on 04/04/2025.
//

import SwiftUI
import RealityKit
import ARKit
import AVFoundation

private let maxFishes = 50
private let maxSharks = 1

struct FishSpace: View {
    @State var deviceProvider = DeviceProvider()
    @State var meshProvider = MeshProvider()
    @State var root = Entity()
    @State var addBubbleTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RealityView { content in
            FishSystem.registerSystem()
            SharkSystem.registerSystem()
            VelocitySystem.registerSystem()
            HandSystem.registerSystem()
            DeviceSystem.registerSystem()
            content.add(root)
            root.addChild(meshProvider.root)
            addDevice()
            addHand(chirality: .left)
            addHand(chirality: .right)
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { tap in
                    guard let device = deviceProvider.getTransform() else { return }
                    Task {
                        let position = tap.entity.position - normalize(device.forward)*0.2
                        await addFish(position: position, forward: -device.forward)
                        let fishes = root.children(FishComponent.self)
                        if fishes.count == maxFishes-1 {//fishes.count > 50 && Float.random(in: 0...1) < 1/50
                            await addShark(position: position, forward: -device.forward)
                        }
                    }
                }
        )
        .task {
            try? await meshProvider.run()
        }
        .task {
            try? await deviceProvider.run()
        }
        .task {
            await root.loopSound(.underwater)
        }
        .task {
            for _ in 0..<20 {
                Task {
                    await addFish(position: .up, forward: .up)
                }
            }
        }
        .onReceive(addBubbleTimer) { _ in
            guard let seaweed = root.children(SeaweedComponent.self).randomElement() else { return }
            Task {
                await addBubble(position: seaweed.position)
            }
        }
        .onChange(of: meshProvider.newMesh) { _, mesh in
            guard let mesh else { return }
            Task {
                await handleNewMesh(mesh)
            }
        }
    }
    
    func handleNewMesh(_ mesh: MeshAnchor) async {
        let vertices = mesh.vertices
        try? await Task.sleep(for: .seconds(1))
        for _ in 0...(vertices.count/100) {
            guard let vertex = vertices.randomElement(),
                  vertex.normal.isPointingUp,
                  let scene = root.scene
            else { continue }
            let hits = scene.convexCast(
                convexShape: .generateSphere(radius: 0.2),
                fromPosition: vertex.position + .up*0.2,
                fromOrientation: .init(),
                toPosition: vertex.position + .up*0.5,
                toOrientation: .init()
            )
            if hits.isEmpty {
                await addSeaweed(position: vertex.position)
            }
        }
        if let vertex = vertices.randomElement() {
            await addStarfish(vertex: vertex)
        }
    }
    
    func addBubble(position: Vector) async {
        let bubble = await File.bubble.getEntity()
        bubble.position = position
        let scale: Float = .random(in: 0.5...1.5)
        bubble.scale = .init(repeating: scale)
        bubble.components.set(VelocityComponent(velocity: .up*scale*0.2, deleteAfter: Date.now.addingTimeInterval(60)))
        root.addChild(bubble)
    }
    
    func addStarfish(vertex: Vertex) async {
        let starfish = await File.starfish.getEntity()
        starfish.generateCollisionShapes(recursive: true, static: true)
        starfish.components.set(ObstacleComponent())
        starfish.setTransform(position: vertex.position + vertex.normal*0.02, up: vertex.normal)
        root.addChild(starfish)
    }
    
    func addSeaweed(position: Vector) async {
        let seaweed = await File.seaweed.getEntity()
        seaweed.components.set(SeaweedComponent())
        seaweed.components.set(CollisionComponent(shapes: [.generateCapsule(height: 80, radius: 20)], isStatic: true))
        seaweed.components.set(ObstacleComponent())
        seaweed.position = position
        root.addChild(seaweed)
    }
    
    func addFish(position: Vector, forward: Vector) async {
        let type = Fish.allCases.randomElement()!
        let fish = await type.file.getEntity()
        let animation = fish.playAnimation(fish.availableAnimations.first!.repeat())
        
//        let sound = Sound.bubble
//        let file = await sound.getFile()
//        let audio = fish.playAudio(file)
//        audio.gain = sound.decibel
//        audio.pause()
        
        fish.components.set(FishComponent(type: type, animation: animation, velocity: .zero))
        fish.setTransform(position: position + .random(in: -1...1)*0.01, forward: forward)
        root.addChild(fish)
        
        let fishes = root.children(FishComponent.self)
        if fishes.count > maxFishes, let device = deviceProvider.getTransform() {
            fishes.furthest(from: device.position)?.removeFromParent()
        }
    }
    
    func addShark(position: Vector, forward: Vector) async {
        guard let target = root.children(FishComponent.self).randomElement() else { return }
        let shark = await File.shark.getEntity()
        let animation = shark.playAnimation(shark.availableAnimations.first!.repeat())
        shark.components.set(SharkComponent(animation: animation, target: target, targetSince: .now))
        shark.components.set(ScaryComponent(radius: 0.7))
        shark.setTransform(position: position, forward: forward)
        root.addChild(shark)
        
        let sharks = root.children(SharkComponent.self)
        if sharks.count > maxSharks, let device = deviceProvider.getTransform() {
            sharks.furthest(from: device.position)?.removeFromParent()
        }
    }
    
    func addHand(chirality: HandAnchor.Chirality) {
        let entity = Entity()
        entity.components.set(ScaryComponent(radius: 0.3))
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.2)]))
        entity.components.set(InputTargetComponent())
        entity.components.set(HandComponent(chirality: chirality))
        root.addChild(entity)
    }
    
    func addDevice() {
        let entity = Entity()
        entity.components.set(ObstacleComponent())
        entity.components.set(DeviceComponent())
        entity.components.set(CollisionComponent(shapes: [.generateCapsule(height: personHeight, radius: 0.3)]))
        root.addChild(entity)
    }
}
