//
//  MeshProvider.swift
//  Alive
//
//  Created by Jack Finnis on 19/01/2025.
//

import Foundation
import ARKit
import RealityKit
import RealityKitContent

@Observable
@MainActor
class MeshProvider {
    let root = Entity()
    private(set) var graph: Graph = .empty
    private(set) var newMesh: MeshAnchor?
    
    private let session = ARKitSession()
    private let provider = SceneReconstructionProvider(modes: [.classification])
    private var entities: [UUID : Entity] = [:]
    
    private var materials: [any Material] = []
    
    func run() async throws {
        let water = try await ShaderGraphMaterial(named: "/Root/WaterMaterial", from: "mesh.usda", in: realityKitContentBundle)
        let sand = try await ShaderGraphMaterial(named: "/Root/SandMaterial", from: "mesh.usda", in: realityKitContentBundle)
        materials = [sand]
        
        try await session.run([provider])
        
        for await update in provider.anchorUpdates {
            switch update.event {
            case .added:
                newMesh = update.anchor
                try await updateAnchor(update.anchor)
            case .updated:
                try await updateAnchor(update.anchor)
            case .removed:
                removeAnchor(update.anchor)
            }
        }
    }
    
    func updateGraph() async {
        graph = await .init(anchors: provider.allAnchors)
    }
    
    private func updateAnchor(_ anchor: MeshAnchor) async throws {
        let entity = entities[anchor.id] ?? {
            let entity = Entity()
            entity.components.set(ObstacleComponent())
            entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
            root.addChild(entity)
            entities[anchor.id] = entity
            return entity
        }()
        
        let mesh = try await MeshResource(from: anchor)
        let shape = try await ShapeResource.generateStaticMesh(from: mesh)
        
        entity.components.set(ModelComponent(mesh: mesh, materials: materials))
        entity.components.set(CollisionComponent(shapes: [shape], isStatic: true))
        entity.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
    }
    
    private func removeAnchor(_ anchor: MeshAnchor) {
        entities.removeValue(forKey: anchor.id)?.removeFromParent()
    }
}
