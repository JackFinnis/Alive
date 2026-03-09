//
//  SpaceIntro.swift
//  Alive
//
//  Created by Jack Finnis on 17/10/2025.
//

import SwiftUI
import MediaPlayer

struct SpaceIntro: View {
    let space: Space
    
    @Environment(\.dismissWindow) var dismissWindow
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @AppStorage("skipIntro") var skipIntro = false
    @State var index = 0
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let instructions = [
            Text("\(Image(systemName: "speaker.wave.3.fill")) Set volume to max"),
        ] + space.instructions.map(Text.init) + [
            Text("\(Image(systemName: "digitalcrown.horizontal.press.fill")) Press Digital Crown to exit"),
            Text(space.warning),
        ]
        
        VStack {
            Menu {
                Button {
                    Task {
                        await openSpace()
                    }
                } label: {
                    Label("Skip Intro", systemImage: "forward.end")
                }
                Button {
                    Task {
                        skipIntro = true
                        await openSpace()
                    }
                } label: {
                    Label("Always Skip Intro", systemImage: "forward.end.alt")
                }
                Divider()
                Button(role: .destructive) {
                    dismissWindow()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            } label: {
                HStack {
                    Image(space.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .clipShape(.circle)
                    Text(space.name)
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .glassBackgroundEffect(in: .capsule)
            }
            .buttonStyle(.plain)
            .hoverEffectDisabled()
            Spacer()
            let instruction = instructions[safe: index-1] ?? Text("Entering \(space.name)...")
            instruction
                .fixedSize()
                .font(.largeTitle)
                .id(index)
                .transition(.blurReplace)
            Spacer()
        }
        .animation(.default, value: index)
        .onReceive(timer) { _ in
            index += 1
            if index > instructions.count {
                Task {
                    await openSpace()
                }
            }
        }
        .frame(width: 1200, height: 700)
    }
    
    func openSpace() async {
        await openImmersiveSpace(value: space)
        dismissWindow()
        dismissWindow(id: "SpacePicker")
    }
}

#Preview(traits: .fixedLayout(width: 1200, height: 700)) {
    SpaceIntro(space: .fish)
}
