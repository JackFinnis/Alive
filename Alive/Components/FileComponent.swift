//
//  FileComponent.swift
//  Alive
//
//  Created by Jack Finnis on 10/04/2025.
//

import RealityKit

struct FileComponent: Component {
    let file: File
}

extension Entity {
    var file: File {
        components[FileComponent.self]!.file
    }
}
