//
//  SpatialGrid.swift
//  Alive
//
//  Created by Jack Finnis on 04/04/2025.
//

import RealityKit

final class SpatialGrid {
    private let cellSize: Float
    private var grid: [SIMD3<Int>: [Entity]] = [:]
    
    init(cellSize: Float) {
        self.cellSize = cellSize
    }
    
    func clear() {
        grid.removeAll(keepingCapacity: true)
    }
    
    @MainActor
    func insert(_ entity: Entity) {
        let cell = getCell(entity.position)
        grid[cell, default: []].append(entity)
    }
    
    func getNearby(_ position: SIMD3<Float>) -> [Entity] {
        let cell = getCell(position)
        var nearby: [Entity] = []
        
        for dx in -1...1 {
            for dy in -1...1 {
                for dz in -1...1 {
                    let neighborCell = SIMD3<Int>(cell.x + dx, cell.y + dy, cell.z + dz)
                    if let entities = grid[neighborCell] {
                        nearby.append(contentsOf: entities)
                    }
                }
            }
        }
        return nearby
    }
    
    private func getCell(_ position: SIMD3<Float>) -> SIMD3<Int> {
        return SIMD3<Int>(
            Int(floor(position.x / cellSize)),
            Int(floor(position.y / cellSize)),
            Int(floor(position.z / cellSize))
        )
    }
}

