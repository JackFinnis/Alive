//
//  File.swift
//  Alive
//
//  Created by Jack Finnis on 17/04/2025.
//

import RealityKit
import RealityKitContent

enum File: String, CaseIterable {
    // fish
    case clownfish  // https://developer.apple.com/documentation/realitykit/building_an_immersive_experience_with_realitykit
    case sardine    // https://developer.apple.com/documentation/realitykit/building_an_immersive_experience_with_realitykit
    case shark      // https://www.turbosquid.com/3d-models/free-shark-3d-model/975376
    case starfish   // https://developer.apple.com/documentation/realitykit/building_an_immersive_experience_with_realitykit
    case yellowtang // https://developer.apple.com/documentation/realitykit/building_an_immersive_experience_with_realitykit
    case seaweed = "seaweed/seaweed" // https://developer.apple.com/documentation/realitykit/building_an_immersive_experience_with_realitykit
    case bubble
    // spider
    case spider     // https://sketchfab.com/3d-models/animated-spider-af87017501fc44e39a33c220f2435100
    case ant        // https://www.turbosquid.com/3d-models/3d-model-ant-1339233
    case cobweb
    // butterfly
    case butterfly  // https://developer.apple.com/documentation/realitykit/composing-interactive-3d-content-with-realitykit-and-reality-composer-pro
    case butterfly_bush = "butterfly_bush/butterfly_bush" // https://www.fab.com/listings/0b932c4a-706f-4a89-a681-8d6e0deb017c
//    case butterfly_bush               // https://www.fab.com/listings/0b932c4a-706f-4a89-a681-8d6e0deb017c
//    case daylily                      // https://www.fab.com/listings/64f686f5-d96d-4287-a679-633932d5bcaa
//    case dwarf_snowflake              // https://www.fab.com/listings/a37dc20f-0532-478c-bbbf-4086d4774d36
//    case goldmound                    // https://www.fab.com/listings/ac18c559-a8c4-466a-984b-8ebd7aca474c
//    case lungwort                     // https://www.fab.com/listings/bc57eee9-a709-4553-a1ae-a488afb2a8a4
//    case alba_armeria                 // https://www.fab.com/listings/2f82e124-5b5e-4575-b8eb-f79965c07566
//    case lily_red                     // https://www.fab.com/listings/02b0534d-e75f-4ac7-a64a-65c2bd36df65
    
    var forward: Vector {
        switch self {
        default:
            return [0, 0, 1]
        }
    }
    
    var up: Vector {
        switch self {
        default:
            return [0, 1, 0]
        }
    }
    
    var scale: Float? {
        switch self {
        case .clownfish, .sardine:
            return 0.011
        case .spider:
            return 0.0005
        case .shark:
            return 0.0015
        case .butterfly_bush:
            return 0.8
        default:
            return nil
        }
    }
    
    var rcp: Bool {
        switch self {
        case .bubble, .seaweed, .butterfly_bush, .cobweb:
            return true
        default:
            return false
        }
    }
    
    @MainActor
    func getEntity() async -> Entity {
        if let cached = fileCache[self] {
            return cached.clone(recursive: true)
        }
        let entity: Entity
        if rcp {
            entity = try! await Entity(named: rawValue, in: realityKitContentBundle)
        } else {
            entity = try! await ModelEntity(named: rawValue)
        }
        entity.components.set(FileComponent(file: self))
        if let scale {
            entity.scale = .init(repeating: scale)
        }
        fileCache[self] = entity
        return entity
    }
}

@MainActor private var fileCache: [File: Entity] = [:]
private let populateFileCache: Void = {
    for file in File.allCases {
        Task {
            await file.getEntity()
        }
    }
}()
