//
//  HandComponent.swift
//  Alive
//
//  Created by Jack Finnis on 10/04/2025.
//

import RealityKit
import ARKit

struct HandComponent: Component {
    let chirality: HandAnchor.Chirality
}

extension Entity {
    var handC: HandComponent {
        get { components[HandComponent.self]! }
        set { components[HandComponent.self] = newValue }
    }
}
