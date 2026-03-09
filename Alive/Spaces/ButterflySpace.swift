//
//  ButterflySpace.swift
//  Alive
//
//  Created by Jack Finnis on 07/04/2025.
//

import SwiftUI
import RealityKit
import ARKit

private let maxButterflies = 100

struct ButterflySpace: View {
    @Environment(Model.self) var model
    @State var meshProvider = MeshProvider()
    @State var handProvider = HandProvider()
    @State var deviceProvider = DeviceProvider()
    @State var butterflyCollisions: EventSubscription?
    @State var root = Entity()
    @State var moveLostButterfliesTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var scareRandomButterflyTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var updateGraphTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RealityView { content in
            ButterflySystem.registerSystem()
            HandSystem.registerSystem()
            DeviceSystem.registerSystem()
            content.add(root)
            root.addChild(meshProvider.root)
            addDevice()
            addHand(chirality: .left)
            addHand(chirality: .right)
            
            butterflyCollisions = content.subscribe(to: CollisionEvents.Began.self, componentType: ButterflyComponent.self) { event in
                guard event.entityA.components.has(ButterflyComponent.self) else { return }
                let butterfly = event.entityA
                let other = event.entityB
                
                if other.components.has(ScaryComponent.self) && butterfly.butterflyC.path.isEmpty {
                    Task {
                        await scareButterfly(event.entityA)
                    }
                }
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { tap in
                    Task {
                        let position = tap.entity.position
                        guard let butterfly = await addButterfly(vertex: .init(position: position, normal: .up)) else { return }
                        await scareButterfly(butterfly)
                    }
                }
        )
        .task {
            try? await meshProvider.run()
        }
        .task {
            try? await handProvider.run()
        }
        .task {
            try? await deviceProvider.run()
        }
        .task {
            await root.loopSound(.forest)
        }
        .task {
            try? await Task.sleep(for: .seconds(1))
            await meshProvider.updateGraph()
        }
        .onReceive(updateGraphTimer) { _ in
            Task {
                await meshProvider.updateGraph()
            }
        }
        .onReceive(scareRandomButterflyTimer) { _ in
            Task {
                await scareRandomButterfly()
            }
        }
        .onReceive(moveLostButterfliesTimer) { _ in
            moveLostButterflies()
        }
        .onChange(of: meshProvider.newMesh) { _, mesh in
            guard let mesh else { return }
            Task {
                await handleNewMesh(mesh)
            }
        }
        .onChange(of: handProvider.isPointingUp(chirality: .right)) { _, _ in
            Task {
                await handlePointingChange(chirality: .right)
            }
        }
        .onChange(of: handProvider.isPointingUp(chirality: .left)) { _, _ in
            Task {
                await handlePointingChange(chirality: .left)
            }
        }
        .onChange(of: handProvider.isClapping) { _, isClapping in
            guard isClapping else { return }
            for butterfly in root.children(ButterflyComponent.self).filter(\.butterflyC.isStationary) {
                Task {
                    await scareButterfly(butterfly)
                }
            }
        }
    }
    
    func scareRandomButterfly() async {
        let butterflies = root.children(ButterflyComponent.self).filter(\.butterflyC.isStationary)
        guard let butterfly = butterflies.randomElement() else { return }
        await scareButterfly(butterfly)
    }
    
    func moveLostButterflies() {
        guard let scene = root.scene else { return }
        for butterfly in root.children(ButterflyComponent.self).filter(\.butterflyC.isStationary) {
            let direction = butterfly.transform.rotation.act(.up)
            let delta = direction * 0.01
            let hits = scene.raycast(from: butterfly.position + delta, to: butterfly.position - delta).filter { $0.entity.components.has(ObstacleComponent.self) }
            if hits.isEmpty {
                Task {
                    await scareButterfly(butterfly)
                }
            }
        }
    }
    
    func handlePointingChange(chirality: HandAnchor.Chirality) async {
        let butterflies = root.children(ButterflyComponent.self)
        let curiousButterfly = butterflies.first { $0.butterflyC.curiousChirality == chirality }
        if handProvider.isPointingUp(chirality: chirality) {
            if curiousButterfly == nil {
                guard let indexTip = handProvider.getTransform(chirality, .indexFingerTip)?.position,
                      let butterfly = butterflies.closest(to: indexTip),
                      let path = await getPath(from: butterfly.position, to: indexTip)
                else { return }
                if let curiousChirality = butterfly.butterflyC.curiousChirality {
                    model.curiousChiralities.remove(curiousChirality)
                }
                butterfly.butterflyC.path = path
                butterfly.butterflyC.normal = .up
                butterfly.butterflyC.curiousChirality = chirality
                model.curiousChiralities.insert(chirality)
            }
        } else {
            if let curiousButterfly, let chirality = curiousButterfly.butterflyC.curiousChirality {
                curiousButterfly.butterflyC.curiousChirality = nil
                model.curiousChiralities.remove(chirality)
                await scareButterfly(curiousButterfly)
            }
        }
    }
    
    func handleNewMesh(_ mesh: MeshAnchor) async {
        let vertices = mesh.vertices
        for _ in 0...(vertices.count/500) {
            guard let vertex = vertices.randomElement() else { continue }
            _ = await addButterfly(vertex: vertex)
        }
        try? await Task.sleep(for: .seconds(1))
        for _ in 0...(vertices.count/500) {
            guard let vertex = vertices.randomElement(),
                  vertex.normal.isPointingUp,
                  let scene = root.scene
            else { continue }
            let size: Float = 0.3
            let hits = scene.convexCast(
                convexShape: .generateSphere(radius: size),
                fromPosition: vertex.position + .up*size,
                fromOrientation: .init(),
                toPosition: vertex.position + .up,
                toOrientation: .init()
            )
            if hits.isEmpty {
                await addFlower(position: vertex.position)
            }
        }
    }
    
    func addButterfly(vertex: Vertex) async -> Entity? {
        let butterfly = await File.butterfly.getEntity()
        let speed: Float = .random(in: 0.6...1)
        let variation: Float = .random(in: 0.8...1.1)
        butterfly.scale *= variation
        let animation = butterfly.playAnimation(butterfly.availableAnimations.first!.repeat())
        animation.speed = speed * 2
        
//        let sound = Sound.butterfly
//        let file = await sound.getFile()
//        let audio = butterfly.playAudio(file)
//        audio.pause()
//        audio.gain = sound.decibel
        
        butterfly.components.set(ButterflyComponent(speed: speed, animation: animation, normal: vertex.normal))
        butterfly.components.set(ScaryComponent())
        butterfly.components.set(CollisionComponent(shapes: [.generateSphere(radius: 10)]))
        butterfly.setTransform(position: vertex.position, up: vertex.normal)
        root.addChild(butterfly)
        
        let butterflies = root.children(ButterflyComponent.self)
        if butterflies.count > maxButterflies, let device = deviceProvider.getTransform() {
            butterflies.furthest(from: device.position)?.removeFromParent()
        }
        
        return butterfly
    }
    
    func addFlower(position: Vector) async {
        let flower = await File.butterfly_bush.getEntity()
        flower.setTransform(position: position)
        flower.generateCollisionShapes(recursive: true, static: true)
        flower.components.set(ObstacleComponent())
        root.addChild(flower)
    }
    
    func scareButterfly(_ butterfly: Entity) async {
        guard butterfly.butterflyC.curiousChirality == nil,
              let (path, vertex) = await getRandomPath(start: butterfly.position)
        else { return }
        butterfly.butterflyC.normal = vertex.normal
        butterfly.butterflyC.path = path + [vertex.position]
    }
    
    func getRandomPath(start: Vector) async -> ([Vector], Vertex)? {
        guard let scene = root.scene,
              let device = deviceProvider.getTransform()
        else { return nil }
        for _ in 0..<5 {
            if let end = meshProvider.graph.randomVertex(near: device.position),
               let path = await RRT(start: start, end: end.position, scene: scene).calculatePath() {
                return (path, end)
            }
        }
        return nil
    }
    
    func getPath(from start: Vector, to end: Vector) async -> [Vector]? {
        guard let scene = root.scene else { return nil }
        for _ in 0..<5 {
            if let path = await RRT(start: start, end: end, scene: scene).calculatePath() {
                return path
            }
        }
        return nil
    }
    
    func addHand(chirality: HandAnchor.Chirality) {
        let entity = Entity()
        entity.components.set(InputTargetComponent())
        entity.components.set(HandComponent(chirality: chirality))
        entity.components.set(ScaryComponent())
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.3)]))
        root.addChild(entity)
    }
    
    func addDevice() {
        let entity = Entity()
        entity.components.set(InputTargetComponent())
        entity.components.set(DeviceComponent())
        entity.components.set(ScaryComponent())
        entity.components.set(CollisionComponent(shapes: [.generateCapsule(height: personHeight, radius: 0.3)]))
        root.addChild(entity)
    }
}
