//
//  Fish.swift
//  Alive
//
//  Created by Jack Finnis on 07/04/2025.
//

enum Fish: String, CaseIterable, Codable {
    case clownfish
    case sardine
    case yellowtang
    
    var file: File {
        switch self {
        case .yellowtang:   return .yellowtang
        case .clownfish:    return .clownfish
        case .sardine:      return .sardine
        }
    }
    
    var maxSpeed: Float {
        switch self {
        case .yellowtang:   return 0.25
        case .clownfish:    return 0.2
        case .sardine:      return 0.15
        }
    }
    
    var animationSpeed: Float {
        switch self {
        case .yellowtang:   return 10
        case .clownfish:    return 10
        case .sardine:      return 20
        }
    }
}
