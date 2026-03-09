//
//  SpacePicker.swift
//  Alive
//
//  Created by Jack Finnis on 21/04/2025.
//

import SwiftUI
import RealityKit
import StoreKit

struct SpacePicker: View {
    @Environment(\.openURL) var openURL
    @Environment(\.pushWindow) var pushWindow
    @Environment(\.dismissWindow) var dismissWindow
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @AppStorage("skipIntro") var skipIntro = false
    
    var body: some View {
        VStack {
            Menu {
                Section("Settings") {
                    Toggle("Always Skip Intro", systemImage: "forward.end.alt", isOn: $skipIntro)
                }
                Section("Alive") {
                    Link(destination: URL(string: "https://apps.apple.com/app/id6754123631?action=write-review")!) {
                        Label("Write a Review", systemImage: "quote.bubble")
                    }
                    Link(destination: URL(string: "mailto:jack@jackfinnis.com?subject=Alive%20Feedback")!) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                    Link(destination: URL(string: "https://apps.apple.com/developer/1633101066")!) {
                        Label("More Apps by Jack", systemImage: "square.grid.2x2")
                    }
                }
            } label: {
                HStack {
                    ZStack {
                        Image(.AppIcon.Back.content)
                            .resizable()
                            .scaledToFit()
                        Image(.AppIcon.Front.content)
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(height: 30)
                    .clipShape(.circle)
                    Text("Alive")
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .glassBackgroundEffect(in: .capsule)
            }
            .buttonStyle(.plain)
            .hoverEffectDisabled()
            .frame(depth: 250)
            
            Spacer()
            HStack {
                ForEach(Array(Space.allCases.enumerated()), id: \.offset) { i, space in
                    Button {
                        if skipIntro {
                            Task {
                                await openImmersiveSpace(value: space)
                                dismissWindow()
                            }
                        } else {
                            pushWindow(value: space)
                        }
                    } label: {
                        VStack(spacing: 0) {
                            RealityView { content in
                                let entity = await space.file.getEntity()
                                entity.playAnimation(entity.availableAnimations.first!.repeat())
                                entity.position.y = space == .fish ? 0 : -0.01
                                content.add(entity)
                                
                                let material = SimpleMaterial(color: .clear, roughness: .float(0), isMetallic: true)
                                let sphere = ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [material])
                                sphere.scale = .init(repeating: 0.5)
                                sphere.generateCollisionShapes(recursive: true, static: true)
                                sphere.components.set(InputTargetComponent())
                                sphere.components.set(HoverEffectComponent())
                                content.add(sphere)
                            }
                            .frame(depth: 0)
                            .frame(width: 400, height: 400)
                            
                            HStack {
                                Image(space.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                    .clipShape(.circle)
                                VStack(alignment: .leading) {
                                    Text(space.name)
                                        .font(.headline)
                                    Text(space.warning)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.trailing)
                            .padding(10)
                            .glassBackgroundEffect(in: .capsule)
                            .frame(depth: 250)
                        }
                    }
                    .hoverEffectDisabled()
                    .buttonStyle(.plain)
                    .rotation3DEffect(.degrees(-15 * (Double(i)-1)), axis: (0, 1, 0))
                    .offset(z: (Double(i)-1).magnitude * 50)
                }
            }
            Spacer()
        }
        .frame(width: 1200, height: 700)
    }
}

#Preview(traits: .fixedLayout(width: 1200, height: 700)) {
    SpacePicker()
}
