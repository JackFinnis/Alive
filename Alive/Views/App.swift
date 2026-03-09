//
//  App.swift
//  Alive
//
//  Created by Jack Finnis on 04/04/2025.
//

import SwiftUI
import ARKit
import TelemetryDeck // https://dashboard.telemetrydeck.com/apps/F3E3A8F0-C695-4890-AD13-8C586355D9B4

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
// use AppTransaction.shared to create better in-app purchase
// attract fish to your finger
// more butterflies
// remove foliage that you are not looking at and that is not anchored to a thing
// particle effects for bubbles for fish
// Make static objects manipulable - move around seaweed out of way of computer
// confine the fish to an actual fish tank
// Help people skip the intro using TipKit
// why did it break for Grandpa?
// make bubbles come out of your mouth

// - ask
// GroundingShadowComponent doesnt work with OcclusionMaterial
// MeshInstancesComponent doesnt work with animations or collision component
// AdaptiveResolutionComponent only gives me binned distance to entity
// ModelSortGroupComponent

// - performance
// dont do boid every frame
// raycast and convexcast less
// use lookat not setTransform

// - done
// scary body column
// break cobwebs
// improve clap
// only pick targets within 5m
// check convexcast stuff
// butterfly bush
// make sure fan doesnt start
// compress audio files
// background music
// spiderwebs material?
// Flowers sway
// "set volume to max"
// butterflies flap too fast
// bigger creatures in SpacePicker
// once you point down butterfly fly off
// shark didnt appear
// Title page with Alive and buttons
// more instructions
// Ant animation - runs away then disappears
// clap to make all butterflies fly
// butterflies land on wrong side of walls?
// turn hand over to drop spider
// not distance-based spider crawl onto hand
// if i close the scene does stuff get deleted and start again?
// shark move away from user
// fix shark
// spiders and butterflies drift into the mesh - update their positions
// fish and spider noises
// Recycle entities - remove the furthest ones and then add a close one
// Simplify rcp project
// spider jump towards you when throw it off

// - meh
// make bubbles move diagonally up walls like they would
// make butterfly open wings when on finger
// fish swim up to hand and nibble
// localise
// spiders land in same direction to you
// reposition the starfish, seaweed if necessary
// lerp butterflies?
// make cavern a bit darker dimmed everywhere
// add water material back
// Stop spiders about to hit
// fish swim through wall
// pop bubbles
// butterflies left stationary?
// pickup starfish
// improve gesture to attract butterflies
// butterfly land/place on flowers
// spiders webs
// place butterfly on flower
// underwater caustics shader
// mesh classification textures
