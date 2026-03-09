//
//  Analytics.swift
//  Alive
//
//  Created by Jack Finnis on 19/10/2025.
//

import TelemetryDeck

struct Analytics {
    enum Event {
        case openSpace(Space)
        case closeSpace(Space, duration: Double)
    }
    
    static func log(_ event: Event) {
        print("log", event)
        switch event {
        case .openSpace(let space):
            TelemetryDeck.signal("openSpace", parameters: [
                "space": space.rawValue,
            ])
        case .closeSpace(let space, let duration):
            TelemetryDeck.signal("closeSpace", parameters: [
                "space": space.rawValue,
                "duration": String(Int(duration))
            ])
        }
    }
}
