//
//  VelocityComponent.swift
//  Alive
//
//  Created by Jack Finnis on 20/05/2025.
//

import Foundation
import RealityKit

struct VelocityComponent: Component {
    let velocity: Vector
    let deleteAfter: Date
}

extension Entity {
    var velocityC: VelocityComponent {
        get { components[VelocityComponent.self]! }
        set { components[VelocityComponent.self] = newValue }
    }
}
