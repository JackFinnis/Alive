//
//  ScaryComponent.swift
//  Alive
//
//  Created by Jack Finnis on 22/04/2025.
//

import RealityKit

struct ScaryComponent: Component {
    var radius: Float = 0
}

extension Entity {
    var scaryC: ScaryComponent {
        get { components[ScaryComponent.self]! }
        set { components[ScaryComponent.self] = newValue }
    }
}
