//
//  Sound.swift
//  Alive
//
//  Created by Jack Finnis on 17/04/2025.
//

import RealityKit

// https://freesound.org/home/bookmarks/

enum Sound: String {
    case underwater // https://freesound.org/people/wjoojoo/sounds/197751/
    case cave       // https://freesound.org/people/Sclolex/sounds/177958/
    case forest     // https://freesound.org/people/Erablo42/sounds/661187/
    
    var decibel: Double {
        switch self {
        case .underwater:
            return -30
        case .cave:
            return -30
        case .forest:
            return -10
        }
    }
}

extension Entity {
    func loopSound(_ sound: Sound) async {
        let file = try! await AudioFileResource(
            named: sound.rawValue,
            configuration: AudioFileResource.Configuration(
                shouldLoop: true,
                shouldRandomizeStartTime: true
            )
        )
        let audio = playAudio(file)
        audio.gain = -.infinity
        audio.fade(to: sound.decibel, duration: 3)
    }
}
