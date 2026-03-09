//
//  DeviceProvider.swift
//  Alive
//
//  Created by Jack Finnis on 14/02/2025.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
class DeviceProvider {
    private let session = ARKitSession()
    private let provider = WorldTrackingProvider()
    
    func run() async throws {
        try await session.run([provider])
    }
    
    func getTransform() -> simd_float4x4? {
        guard provider.state == .running else { return nil }
        return provider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())?.originFromAnchorTransform
    }
}
