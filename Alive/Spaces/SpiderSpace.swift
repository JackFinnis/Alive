//
//  SpiderSpace.swift
//  Alive
//
//  Created by Jack Finnis on 07/04/2025.
//

import SwiftUI
import RealityKit
import ARKit

private let maxSpiders = 100

struct SpiderSpace: View {
    @Environment(Model.self) var model
    @State var deviceProvider = DeviceProvider()
    @State var meshProvider = MeshProvider()
    @State var handProvider = HandProvider()
    @State var spiderCollisions: EventSubscription?
    @State var cobwebCollisions: EventSubscription?
    @State var root = Entity()
    @State var moveLostSpidersTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var scareRandomSpiderTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var updateGraphTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @State var lastClap = Date.distantPast
    
    var body: some View {
        RealityView { content in
            SpiderSystem.registerSystem()
            HandSystem.registerSystem()
            DeviceSystem.registerSystem()
            VelocitySystem.registerSystem()
            content.add(root)
            root.addChild(meshProvider.root)
            addDevice()
            addHand(chirality: .left)
            addHand(chirality: .right)
            
            cobwebCollisions = content.subscribe(to: CollisionEvents.Began.self, componentType: CobwebComponent.self) { event in
                guard event.entityA.components.has(CobwebComponent.self) else { return }
                let cobweb = event.entityA
                let other = event.entityB
                
                if other.components.has(HandComponent.self) || other.components.has(DeviceComponent.self) {
                    cobweb.removeFromParent()
                }
            }
            
            spiderCollisions = content.subscribe(to: CollisionEvents.Began.self, componentType: SpiderComponent.self) { event in
                guard event.entityA.components.has(SpiderComponent.self) else { return }
                let spider = event.entityA
                let other = event.entityB
                
                if other.components.has(AntComponent.self) {
                    let velocity = normalize(other.position - spider.position) * spider.spiderC.speed/2
                    other.components.set(VelocityComponent(velocity: velocity, deleteAfter: .now.addingTimeInterval(0.1)))
                }
                if other.components.has(HandComponent.self) {
                    setCurious(spider: spider, hand: other)
                }
                if other.components.has(SpiderComponent.self) {
                    Task {
                        await scareSpider(spider)
                    }
                }
                if other.components.has(DeviceComponent.self) {
                    Task {
                        await scareSpider(spider)
                    }
                }
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToEntity(where: .has(ObstacleComponent.self))
                .onEnded { tap in
                    Task {
                        let tapPosition = tap.convert(tap.location3D, from: .local, to: .scene)
                        guard let vertex = meshProvider.graph.closestVertex(to: tapPosition) else { return }
                        await addAnt(vertex: .init(position: tapPosition, normal: vertex.normal))
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
            try? await handProvider.run()
        }
        .task {
            await root.loopSound(.cave)
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
        .onReceive(scareRandomSpiderTimer) { _ in
            Task {
                await scareRandomSpider()
            }
        }
        .onReceive(moveLostSpidersTimer) { _ in
            moveLostSpiders()
        }
        .onChange(of: meshProvider.newMesh) { _, mesh in
            guard let mesh else { return }
            Task {
                await handleNewMesh(mesh)
            }
        }
        .onChange(of: handProvider.isClapping) { _, isClapping in
            guard isClapping,
                  lastClap.distance(to: .now) > 10,
                  let device = deviceProvider.getTransform()
            else { return }
            lastClap = .now
            for spider in root.children(SpiderComponent.self).filter({ !$0.spiderC.isFalling }) {
                let velocity = device.position - spider.position
                spider.spiderC.drop(initialVelocity: velocity)
            }
        }
    }
    
    func scareRandomSpider() async {
        let spiders = root.children(SpiderComponent.self).filter(\.spiderC.isStationary)
        guard let spider = spiders.randomElement() else { return }
        await scareSpider(spider)
    }
    
    func moveLostSpiders() {
        guard let scene = root.scene else { return }
        for spider in root.children(SpiderComponent.self).filter(\.spiderC.isStationary) {
            let direction = spider.transform.rotation.act(.up)
            let delta = direction * 0.01
            let hits = scene.raycast(from: spider.position + delta, to: spider.position - delta).filter { $0.entity.components.has(ObstacleComponent.self) }
            if hits.isEmpty {
                Task {
                    await scareSpider(spider)
                }
            }
        }
    }
    
    func setCurious(spider: Entity, hand: Entity) {
        let chirality = hand.handC.chirality
        guard root.children(SpiderComponent.self).allSatisfy({ $0.spiderC.curiousChirality != chirality }),
              !handProvider.isDropping(chirality: chirality)
        else { return }
        spider.spiderC.curiousChirality = chirality
        spider.spiderC.path = [.init(position: hand.position, normal: .up)]
        model.curiousChiralities.insert(chirality)
    }
    
    func dropRandomSpider() {
        guard let spider = root.children(SpiderComponent.self).filter(\.spiderC.isStationary).randomElement(),
              let scene = root.scene
        else { return }
        let hits = scene.raycast(origin: spider.position, direction: .down, length: 10).filter { $0.entity.components.has(ObstacleComponent.self) }
        let maxDistance = hits.map(\.distance).max()
        if let maxDistance, maxDistance > 0.1 {
            spider.spiderC.isFalling = true
        }
    }
    
    func addRandomAnt() async {
        let graph = meshProvider.graph
        guard let device = deviceProvider.getTransform(),
              let vertex = graph.randomVertex(near: device.position)
        else { return }
        await addAnt(vertex: vertex)
    }
    
    func handleNewMesh(_ mesh: MeshAnchor) async {
        let vertices = mesh.vertices
        for _ in 0...(vertices.count/500) {
            guard let vertex = vertices.randomElement() else { continue }
            await addSpider(vertex: vertex)
        }
        for _ in 0...(vertices.count/1000) {
            guard let a = vertices.randomElement()?.position else { continue }
            for _ in 0...(vertices.count/500) {
                guard let b = vertices.randomElement()?.position else { continue }
                let delta = a - b
                let length = length(delta)
                guard length < 1.5,
                      a.y.distance(to: b.y).magnitude > 0.1,
                      a.coord.distance(to: b.coord) > 0.1
                else { continue }
                
                let cobweb = await File.cobweb.getEntity()
                
                let along = normalize(delta)
                let right = normalize(cross(along, .up))
                let laser = normalize(cross(along, right))
                let middle = a.halfway(to: b)
                let position = middle + laser*0.2*length
                cobweb.setTransform(position: position, forward: -laser)
                
                cobweb.components.set(CobwebComponent())
                cobweb.components.set(CollisionComponent(shapes: [.generateCapsule(height: length, radius: 0.05)], isStatic: true))
                cobweb.scale.y = length
                let sphere = cobweb.children.first!.children.first! as! ModelEntity
                var material = sphere.model!.materials.first! as! ShaderGraphMaterial
                try! material.setParameter(name: "Length", value: .float(length))
                sphere.model!.materials = [material]
                
                root.addChild(cobweb)
            }
        }
    }
    
    func scareSpider(_ spider: Entity) async {
        let graph = meshProvider.graph
        guard spider.spiderC.isStationary,
              let device = deviceProvider.getTransform(),
              let targetVertex = graph.randomVertex(near: device.position),
              let spiderVertex = graph.closestVertex(to: spider.position),
              let path = await aStar(graph: graph, start: spiderVertex.position, goal: targetVertex.position)
        else { return }
        spider.spiderC.path = Array(path.dropFirst()).smoothPath()
    }
    
    func addSpider(vertex: Vertex) async {
        let entity = await File.spider.getEntity()
        let variation: Float = .random(in: 0.7...1.1)
        entity.scale *= variation
        let speed: Float = .random(in: 0.3...0.5) / variation
        let controller = entity.playAnimation(entity.availableAnimations.first!.repeat())
        controller.speed = 14 * speed / variation
        entity.components.set(SpiderComponent(speed: speed, animation: controller))
        entity.components.set(InputTargetComponent())
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.05/File.spider.scale!)]))
        entity.setTransform(position: vertex.position, up: vertex.normal)
        root.addChild(entity)
        
        let spiders = root.children(SpiderComponent.self)
        if spiders.count > maxSpiders, let device = deviceProvider.getTransform() {
            spiders.furthest(from: device.position)?.removeFromParent()
        }
    }
    
    func addAnt(vertex: Vertex) async {
        let entity = await File.ant.getEntity()
        entity.generateCollisionShapes(recursive: true, static: true)
        entity.components.set(AntComponent())
        entity.components.remove(VelocityComponent.self)
        entity.setTransform(position: vertex.position, up: vertex.normal)
        root.addChild(entity)
        
        let graph = meshProvider.graph
        guard let spider = root.children(SpiderComponent.self).filter(\.spiderC.isStationary).closest(to: vertex.position),
              let spiderVertexMesh = graph.closestVertex(to: spider.position),
              let flyVertexMesh = graph.closestVertex(to: vertex.position),
              let path = await aStar(graph: graph, start: spiderVertexMesh.position, goal: flyVertexMesh.position)
        else { return }
        spider.spiderC.path = Array(path.dropFirst().dropLast() + [vertex]).smoothPath()
    }
    
    func addHand(chirality: HandAnchor.Chirality) {
        let entity = Entity()
        entity.components.set(HandComponent(chirality: chirality))
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.05)]))
        root.addChild(entity)
    }
    
    func addDevice() {
        let entity = Entity()
        entity.components.set(DeviceComponent())
        entity.components.set(CollisionComponent(shapes: [.generateCapsule(height: personHeight, radius: 0.3)]))
        root.addChild(entity)
    }
}
