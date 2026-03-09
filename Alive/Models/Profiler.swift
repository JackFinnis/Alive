//
//  Profile.swift
//  Alive
//
//  Created by Jack Finnis on 09/05/2025.
//

import Foundation
import RealityKit
import ARKit

@MainActor
class Profiler {
    static let shared = Profiler(enabled: true)
    private init(enabled: Bool) {
        self.enabled = enabled
    }
    
    private let enabled: Bool
    private var startedLogging: Date? = .now
    private var dts: [Double] = []
    
    func log(_ dt: Double) {
        guard enabled, startedLogging != nil else { return }
        dts.append(dt)
    }
    
    func startLogging() {
        dts = []
        startedLogging = .now
    }
    
    func stopLogging(count: Int) -> Bool {
        guard let startedLogging, startedLogging.distance(to: .now) > 1 else { return false }
        print("profile", count, dts.average()!)
        self.startedLogging = nil
        return true
    }
}
