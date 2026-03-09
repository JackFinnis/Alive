//
//  Export.swift
//  Alive
//
//  Created by Jack Finnis on 09/05/2025.
//

import Foundation
import RealityKit
import ARKit

@MainActor
class Exporter {
    static let url = URL.documentsDirectory.appendingPathComponent("export.json")
    static let shared = Exporter(enabled: false)
    private init(enabled: Bool) {
        self.enabled = enabled
    }
    
    private let enabled: Bool
    private var export: Export = .init()
    
    func addMeshUpdate(_ update: AnchorUpdate<MeshAnchor>) {
        guard enabled else { return }
        export.meshUpdates.append(.init(update: update))
    }
    
    func addHandUpdate(_ update: AnchorUpdate<HandAnchor>) {
        guard enabled else { return }
        export.handUpdates.append(.init(update: update))
    }
    
    func addFrame(_ entities: some Sequence<Entity>) {
        guard enabled else { return }
        let states = entities.map(Export.EntityState.init)
        export.entityFrames.append(.init(entityStates: states))
    }
    
    func save() {
        guard enabled else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try! encoder.encode(export)
        try! data.write(to: Self.url)
    }
}

struct Export: Encodable {
    var handUpdates: [HandUpdate] = []
    var meshUpdates: [MeshUpdate] = []
    var entityFrames: [EntityFrame] = []
    
    struct MeshUpdate: Encodable {
        let timestamp: Date = .now
        let id: UUID
        let vertices: [Vector]
        let faces: [[Int]]
    }
    
    struct EntityFrame: Encodable {
        let timestamp: Date = .now
        let entityStates: [EntityState]
    }
    
    struct HandUpdate: Encodable {
        let timestamp: Date = .now
        let chirality: String
        let position: Vector?
    }
    
    struct EntityState: Encodable {
        let id: String
        let type: String?
        let position: Vector
        let forward: Vector
    }
}

extension Export.MeshUpdate {
    init(update: AnchorUpdate<MeshAnchor>) {
        self.init(
            id:         update.anchor.id,
            vertices:   update.event == .removed ? [] : update.anchor.worldVertices,
            faces:      update.event == .removed ? [] : update.anchor.geometry.faces.faces()
        )
    }
}

extension Export.HandUpdate {
    init(update: AnchorUpdate<HandAnchor>) {
        self.init(
            chirality:  update.anchor.chirality.description,
            position:   update.event == .removed ? nil : update.anchor.originFromAnchorTransform.position
        )
    }
}

extension Export.EntityState {
    @MainActor
    init(entity: Entity) {
        self.init(
            id: String(entity.id),
            type: entity.components[FishComponent.self]?.type.rawValue,
            position: entity.position,
            forward: entity.transform.matrix.forward
        )
    }
}
