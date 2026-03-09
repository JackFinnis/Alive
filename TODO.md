# TODO

## Priority

- Help people skip SpaceIntro using TipKit
- Use `Began`/`Ended` collision events instead of raycasting and convex casting in the boid system
- Remove foliage that has become unanchored when you are not looking at it

## Features

- Hold out your hand to make fish swim up to it and nibble on your finger
- Use particle effects to release bubbles from the fish
- Make bubbles come out of your mouth when you talk
- Pop bubbles when they hit the surface or your hand
- Confine the fish to an actual spherical fish tank
- Make static objects manipulable (e.g. move seaweed out of the way)
- Make butterfly flap its wings when it is on your finger
- Improve gesture to attract butterflies
- Make butterflies land on flowers / allow you to place butterflies on flowers
- Pick up starfish on your hand and throw it like a spider
- Add more butterflies
- Add more creatures with new movement algorithms in existing/new spaces (hummingbird, bees, caterpillars)
- Vines/growth shader — vines grow up walls and start to flower
- Apply different textures based on the surface classification of the mesh
- Use MusicKit to play ambient music and make fish swim in time to the music
- Use AppTransaction to detect who paid for the app
- Room-based experiences — put each space in a different room so you can walk between them
- Shared experiences with SharePlay so friends can see your creatures in real time

## Performance

- Don't do boid calculations on every frame
- Raycast and convex cast less frequently
- Use `lookAt` instead of `setTransform`

## Polish

- Fix WaterMaterial underwater caustics so it works in real time without lagging
- Make ants move dynamically so spiders must recalculate paths in real time
- Make cavern environment dimmed and a bit darker
- Prevent spiders from hitting each other and fish from swimming through walls
- Make sure butterflies are never left stationary

## Framework Questions

- `GroundingShadowComponent` doesn't work with `OcclusionMaterial`
- `MeshInstancesComponent` doesn't work with animations or `CollisionComponent`
- `AdaptiveResolutionComponent` only gives binned distance to entity
- `ModelSortGroupComponent` might be useful to give the world mesh underwater effect and occlusion
