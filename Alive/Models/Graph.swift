//
//  Graph.swift
//  Alive
//
//  Created by Jack Finnis on 14/02/2025.
//

import ARKit
import HeapModule

struct Vertex: Hashable {
    let position: Vector
    let normal: Vector
}

struct Graph {
    let neighbours: [Vector : Set<Vector>]
    let normals: [Vector : Vector]
    
    fileprivate func getVertex(position: Vector) -> Vertex {
        .init(position: position, normal: normals[position]!)
    }
    
    func closestVertex(to position: Vector) -> Vertex? {
        guard let closest = neighbours.keys.closest(to: position) else { return nil }
        return getVertex(position: closest)
    }
    
    func randomVertex(near: Vector) -> Vertex? {
        for _ in 0...10 {
            if let position = neighbours.keys.randomElement() {
                return getVertex(position: position)
            }
        }
        return nil
    }
    
    static var empty: Graph {
        .init(neighbours: [:], normals: [:])
    }
}

extension Graph {
    init(anchors: [MeshAnchor]) async {
        var neighbours: [Vector : Set<Vector>] = [:]
        var normals: [Vector : Vector] = [:]
        
        for anchor in anchors {
            let vertices = anchor.vertices
            let faces = anchor.geometry.faces.faces()
            
            var adjacencyList: [Int : Set<Int>] = [:]
            
            for faceIndices in faces {
                for vertexIndex in faceIndices {
                    adjacencyList[vertexIndex] = adjacencyList[vertexIndex, default: []].union(faceIndices)
                }
            }
            
            for (vertexIndex, neighbourIndices) in adjacencyList {
                let vertexPosition = vertices[vertexIndex].position
                let vertexNormal = vertices[vertexIndex].normal
                let neighborPositions = neighbourIndices.compactMap { neighbourIndex -> Vector? in
                    guard vertexIndex != neighbourIndex else { return nil }
                    return vertices[neighbourIndex].position
                }
                neighbours[vertexPosition] = neighbours[vertexPosition, default: []].union(neighborPositions)
                normals[vertexPosition] = normalize(normals[vertexPosition, default: vertexNormal] + vertexNormal)
            }
        }
        
        self = .init(neighbours: neighbours, normals: normals)
    }
}

fileprivate struct NodeScore {
    let node: Vector
    let fScore: Float
}

extension NodeScore: Comparable {
    static func < (lhs: NodeScore, rhs: NodeScore) -> Bool {
        lhs.fScore < rhs.fScore
    }
}

func aStar(graph: Graph, start: Vector, goal: Vector) async -> [Vertex]? {
    var openSet = Heap<NodeScore>()
    var closedSet: Set<Vector> = []
    var cameFrom: [Vector: Vector] = [:]
    var gScore: [Vector: Float] = [start: 0]
    
    openSet.insert(.init(node: start, fScore: start.distance(to: goal)))

    while let currentFScoredNode = openSet.popMin() {
        let current = currentFScoredNode.node

        if current == goal {
            return reconstructPath(to: goal, graph: graph, cameFrom: cameFrom)
        }
        
        guard !closedSet.contains(current) else {
            continue
        }
        closedSet.insert(current)
        
        for neighbour in graph.neighbours[current, default: []] {
            if closedSet.contains(neighbour) {
                continue
            }

            let tentativeGScore = gScore[current, default: .infinity] + current.distance(to: neighbour)
            
            if tentativeGScore < gScore[neighbour, default: .infinity] {
                cameFrom[neighbour] = current
                gScore[neighbour] = tentativeGScore
                let neighbourFScore = tentativeGScore + neighbour.distance(to: goal)
                openSet.insert(.init(node: neighbour, fScore: neighbourFScore))
            }
        }
    }
    
    return nil
}

func reconstructPath(to end: Vector, graph: Graph, cameFrom: [Vector : Vector]) -> [Vertex] {
    var path = [graph.getVertex(position: end)]
    var current = end
    while let previous = cameFrom[current] {
        path.append(graph.getVertex(position: previous))
        current = previous
    }
    return path.reversed()
}
