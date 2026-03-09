//
//  Anchor.swift
//  Alive
//
//  Created by Jack Finnis on 19/04/2025.
//

import ARKit

extension MeshAnchor {
    var worldVertices: [Vector] {
        geometry.vertices.positions()
            .map(\.homogeneousPosition)
            .map { originFromAnchorTransform * $0 }
            .map(\.vector)
    }
    
    var worldNormals: [Vector] {
        geometry.normals.normals()
            .map(\.homogeneousDirection)
            .map { originFromAnchorTransform * $0 }
            .map(\.vector)
    }
    
    var vertices: [Vertex] {
        zip(worldVertices, worldNormals).map(Vertex.init)
    }
}

extension Vector {
    var homogeneousPosition: simd_float4 {
        .init(self, 1)
    }
    
    var homogeneousDirection: simd_float4 {
        .init(self, 0)
    }
}

extension GeometrySource {
    func positions() -> [Vector] {
        (0..<count)
            .map { index in
                buffer
                    .contents()
                    .advanced(by: offset + stride * index)
                    .assumingMemoryBound(to: (Float, Float, Float).self)
                    .pointee
            }
            .map { .init($0.0, $0.1, $0.2) }
    }
    
    func normals() -> [Vector] {
        (0..<count)
            .map { index in
                buffer
                    .contents()
                    .advanced(by: offset + stride * index)
                    .assumingMemoryBound(to: (Float, Float, Float).self)
                    .pointee
            }
            .map { .init($0.0, $0.1, $0.2) }
    }
    
    func classifications() -> [MeshAnchor.MeshClassification] {
        (0..<count)
            .map { index in
                buffer
                    .contents()
                    .advanced(by: offset + stride * index)
                    .assumingMemoryBound(to: MeshAnchor.MeshClassification.self)
                    .pointee
            }
    }
}

extension GeometryElement {
    func faces() -> [[Int]] {
        (0..<count)
            .map { index in
                buffer
                    .contents()
                    .advanced(by: index * primitive.indexCount * bytesPerIndex)
                    .assumingMemoryBound(to: (Int32, Int32, Int32).self)
                    .pointee
            }
            .map { [$0.0, $0.1, $0.2].map(Int.init) }
    }
}
