//
//  Vector.swift
//  Alive
//
//  Created by Jack Finnis on 22/02/2025.
//

import simd

typealias Vector = SIMD3<Float>
typealias Coord = SIMD2<Float>

extension Vector {
    static let up: Self     = [0,  1, 0]
    static let down: Self   = [0, -1, 0]

    static let units: [Vector] = [
        [ 1,  0,  0],
        [ 0,  1,  0],
        [ 0,  0,  1],
        [-1,  0,  0],
        [ 0, -1,  0],
        [ 0,  0, -1],
    ]
    
    var coord: Coord {
        .init(x: x, y: z)
    }
    
    var isPointingUp: Bool {
        y > 0.7
    }
    
    func direction(to other: Vector) -> Vector {
        normalize(other - self)
    }
    
    func distance(to other: Vector) -> Float {
        length(other - self)
    }
    
    func halfway(to other: Vector) -> Vector {
        (self + other)/2
    }
    
    func distanceSquared(to other: Vector) -> Float {
        length_squared(other - self)
    }
}

extension Coord {
    func distance(to other: Coord) -> Float {
        length(other - self)
    }
}

extension simd_float4 {
    var vector: Vector {
        .init(x: x, y: y, z: z)
    }
}

extension simd_float4x4 {
    var right: Vector {
        columns.0.vector
    }
    var up: Vector {
        columns.1.vector
    }
    var forward: Vector {
        columns.2.vector
    }
    var position: Vector {
        columns.3.vector
    }
}

extension Sequence where Element == Vector {
    func closest(to other: Vector) -> Vector? {
        self.min { $0.distanceSquared(to: other) < $1.distanceSquared(to: other) }
    }
}

extension Array where Element == Vector {
    func average() -> Vector? {
        guard isNotEmpty else { return nil }
        return reduce(into: .zero) { result, element in
            result += element
        } / Float(count)
    }
}
