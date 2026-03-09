//
//  App.swift
//  Alive
//
//  Created by Jack Finnis on 04/04/2025.
//

import SwiftUI
import ARKit
import TelemetryDeck

let personHeight: Float = 1.7

@main
struct AliveApp: App {
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    @State var model = Model.shared
    @State var openSpaceAt: Date = .now
    
    init() {
        TelemetryDeck.initialize(config: .init(appID: "F3E3A8F0-C695-4890-AD13-8C586355D9B4"))
    }
    
    var body: some Scene {
        WindowGroup(id: "SpacePicker") {
            SpacePicker()
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        WindowGroup(for: Space.self) { $space in
            if let space = $space.wrappedValue {
                SpaceIntro(space: space)
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        
        ImmersiveSpace(for: Space.self) { $space in
            if let space = $space.wrappedValue {
                Group {
                    switch space {
                    case .fish:
                        FishSpace()
                    case .spider:
                        SpiderSpace()
                    case .butterfly:
                        ButterflySpace()
                    }
                }
                .onAppear {
                    openSpaceAt = .now
                    Analytics.log(.openSpace(space))
                }
                .onDisappear {
                    openWindow(id: "SpacePicker")
                    model.curiousChiralities = []
                    let duration = openSpaceAt.distance(to: .now)
                    Analytics.log(.closeSpace(space, duration: duration))
                }
            }
        }
        .upperLimbVisibility(model.curiousChiralities.isNotEmpty ? .hidden : .visible)
        .environment(model)
    }
}

@Observable
class Model {
    @MainActor static let shared = Model()
    private init() {}
    
    var curiousChiralities: Set<HandAnchor.Chirality> = []
}
