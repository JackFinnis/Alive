//
//  RRT.swift
//  Alive
//
//  Created by Jack Finnis on 19/01/2025.
//

import RealityKit

class RRT {
    private let start: Vector
    private let end: Vector
    private let scene: Scene
    private let bounds: BoundingBox
    
    private let stepSize: Float = 0.1
    private let endRadiusSquared: Float
    private let maxIterations: Int = 1000
    private let bias: Float = 0.2
    
    private var parent: [Vector : Vector] = [:]
    private var nodes: [Vector] = []
    
    init(start: Vector, end: Vector, scene: Scene) {
        self.start = start
        self.end = end
        self.scene = scene
        self.endRadiusSquared = pow(stepSize*2, 2)
        let bounds: BoundingBox = .init()
            .union(start)
            .union(end)
        self.bounds = bounds
            .union(bounds.min - [1, 1, 1])
            .union(bounds.max + [1, 1, 1])
    }
    
    func calculatePath() async -> [Vector]? {
        nodes = [start]
        
        for _ in 0..<maxIterations {
            let randomPosition = getRandomPosition()
            let closestNode = nodes.closest(to: randomPosition)!
            let direction = closestNode.direction(to: randomPosition)
            let step = direction * stepSize
            let newNode = closestNode + step
            
            if await isValidEdge(from: closestNode, to: newNode, in: scene) || nodes.count == 1 {
                nodes.append(newNode)
                parent[newNode] = closestNode
                
                if newNode.distanceSquared(to: end) < endRadiusSquared {
                    return reconstructPath(to: newNode)
                }
            }
        }

        return nil
    }
    
    private func getRandomPosition() -> Vector {
        if Float.random(in: 0...1) < bias {
            return end
        }
        
        return .init(
            x: Float.random(in: bounds.min.x...bounds.max.x),
            y: Float.random(in: bounds.min.y...bounds.max.y),
            z: Float.random(in: bounds.min.z...bounds.max.z),
        )
    }
    
    private func reconstructPath(to end: Vector) -> [Vector] {
        var path = [end]
        var current = end
        while current != start {
            if let parent = parent[current] {
                path.append(parent)
                current = parent
            }
        }
        return path.reversed()
    }
}

@MainActor
private func isValidEdge(from fromNode: Vector, to toNode: Vector, in scene: Scene) -> Bool {
    scene.raycast(from: fromNode, to: toNode).allSatisfy { !$0.entity.components.has(ObstacleComponent.self) }
}
