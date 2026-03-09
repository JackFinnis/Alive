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

// - todo
// use AppTransaction.shared detect who paid for the app
// hold out your hand to make fish swim up to it and nibble on your finger
// try to add more butterflies
// remove foliage that has become not anchored to anything when you are not looking at it
// use particle effects to release bubbles from the fish
// Make static objects manipulable - eg move around seaweed out of the way of your computer
// confine the fish to an actual spherical fish tank
// Help people skip SpaceIntro using TipKit
// make bubbles come out of your mouth when you talk
// use Music kit to play ambient music and make fish swim in time to the music
// implement shared experiences with friedns in the same and different rooms
// fix WaterMaterial underwater caustics so it works in real time without lagging
// apply different textures based on the surface classification of the mesh

// - ask
// GroundingShadowComponent doesnt work with OcclusionMaterial
// MeshInstancesComponent doesnt work with animations or collision component
// AdaptiveResolutionComponent only gives binned distance to entity
// ModelSortGroupComponent might be useful to give the world mesh underwater effect and occlusion

// - performance
// dont do boid calculations on every frame
// raycast and convexcast less
// use lookat not setTransform
// improve boid system to use Began/Ended collision events so we dont have to use raycasting and convexcasting

// - meh
// make butterfly flap its wings when it is on your finger
// make cavern environment dimmed and a bit darker
// make sure spiders never hit each other and fish dont swim through walls
// pop bubbles when they hit the surface or your hand
// make sure butterflies are never left stationary
// pickup starfish on your hand and throw it like a spider
// improve gesture to attract butterflies
// make butterflies land on flowers
// allow you to place butterflies on flowers
