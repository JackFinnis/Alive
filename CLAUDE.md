# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a visionOS app built with Xcode. There is no command-line build or test pipeline.

- **Open**: `open Alive.xcodeproj`
- **Build/Run**: Use Xcode (requires Xcode 16.3+, visionOS SDK, Apple Vision Pro simulator or device)
- **Swift toolchain**: Swift 6.0 (strict concurrency)
- **No test targets** exist in this project

## Architecture

**Alive** is an immersive AR app for Apple Vision Pro with three interactive creature environments (Aquarium, Cavern, Meadow). It uses RealityKit's **Entity Component System (ECS)** pattern throughout.

### ECS Pattern

- **Components** (`Components/`): Pure data attached to entities (e.g. `FishComponent`, `SpiderComponent`, `VelocityComponent`)
- **Systems** (`Systems/`): Per-frame logic that queries and updates entities with specific components (e.g. `FishSystem` runs boid flocking, `SpiderSystem` runs pathfinding)
- **Spaces** (`Spaces/`): Top-level immersive views (`FishSpace`, `SpiderSpace`, `ButterflySpace`) that set up entities, providers, and systems

Systems register themselves and run each frame via RealityKit's system update loop. Components are registered in each Space's `init()`.

### Key Layers

| Directory | Role |
|-----------|------|
| `Views/` | SwiftUI scenes: app entry point (`App.swift`), space picker, intro screens |
| `Spaces/` | Immersive RealityKit views that spawn and manage creatures |
| `Systems/` | ECS systems with per-frame update logic |
| `Components/` | ECS component structs |
| `Providers/` | ARKit session wrappers: hand tracking, device tracking, mesh anchors |
| `Models/` | Algorithms and utilities: spatial grid, graph pathfinding, RRT, analytics |
| `Enums/` | Configuration types: `Space`, `Fish`, `Sound`, `File` (3D asset refs) |
| `Extensions/` | Helpers on `Entity`, `Array`, `Collection`, `Double`, `Mesh` |

### Creature AI

- **Fish**: Boid flocking (cohesion, separation, alignment, boundary avoidance). Shark appears at 50+ fish.
- **Spiders**: Graph-based pathfinding over mesh surfaces using RRT. Respond to hand proximity — crawl onto user's hand.
- **Butterflies**: Flight behavior responding to pointing gestures and clapping.

### ARKit Providers

Three providers wrap ARKit sessions and feed data into ECS:
- `HandProvider` — hand joint tracking, gesture detection (pointing, clapping, dropping)
- `DeviceProvider` — headset world position via `WorldTrackingProvider`
- `MeshProvider` — spatial mesh anchors for environment understanding

### Key Frameworks

- **RealityKit** — 3D rendering, ECS, physics, spatial audio
- **ARKit** — hand/device/mesh tracking
- **SwiftUI** — windowed UI (space picker, intros)
- **TelemetryDeck** — analytics
- **swift-collections** (`HeapModule`) — used in pathfinding

### Performance Patterns

- `SpatialGrid`: O(1) spatial neighbor lookups for boid/interaction queries
- Entity recycling: furthest entities removed and respawned closer to user
- `File` enum caches loaded 3D models to avoid redundant I/O

### App Entry Point

`App.swift` defines three scenes: a `WindowGroup` for the space picker, a `WindowGroup` for space intros, and an `ImmersiveSpace` that switches between the three creature spaces. `Model.shared` is the sole global observable state.

### Local Package

`Packages/RealityKitContent` is a local Swift package containing Reality Composer Pro assets (3D models, materials, scenes).
