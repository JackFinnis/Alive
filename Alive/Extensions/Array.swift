//
//  Array.swift
//  Alive
//
//  Created by Jack Finnis on 05/06/2025.
//

import RealityKit

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element == Vertex {
    func smoothPath() -> [Vertex] {
        guard count >= 2 else { return self }
        
        let first = self[0]
        let last = self[count - 1]
        
        var smoothed: [Vertex] = [first]
        for i in 0..<(count - 1) {
            let current = self[i]
            let next = self[i + 1]
            
            let avgPosition = (current.position + next.position) / 2
            let avgNormal = normalize(current.normal + next.normal)
            
            smoothed.append(Vertex(position: avgPosition, normal: avgNormal))
        }
        smoothed.append(last)
        
        return smoothed
    }
}
