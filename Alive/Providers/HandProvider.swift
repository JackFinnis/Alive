//
//  HandProvider.swift
//  Alive
//
//  Created by Jack Finnis on 14/02/2025.
//

import RealityKit
import ARKit

@Observable
class HandProvider {
    private(set) var anchors: [HandAnchor.Chirality : HandAnchor] = [:]
    
    private let session = ARKitSession()
    private let provider = HandTrackingProvider()
    
    @MainActor
    func run() async throws {
        try await session.run([provider])
        
        for await update in provider.anchorUpdates {
            let anchor = update.anchor
            switch update.event {
            case .added, .updated:
                if anchor.isTracked {
                    anchors[anchor.chirality] = anchor
                } else {
                    anchors.removeValue(forKey: anchor.chirality)
                }
            case .removed:
                anchors.removeValue(forKey: anchor.chirality)
            }
        }
    }
    
    func getTransform(_ chirality: HandAnchor.Chirality, _ joint: HandSkeleton.JointName) -> simd_float4x4? {
        guard let anchor = anchors[chirality],
              let skeleton = anchor.handSkeleton
        else { return nil }
        return anchor.originFromAnchorTransform * skeleton.joint(joint).anchorFromJointTransform
    }
    
    func isPointingUp(chirality: HandAnchor.Chirality) -> Bool {
        guard let indexTip = getTransform(chirality, .indexFingerTip),
              let middleTip = getTransform(chirality, .middleFingerTip)
        else { return false }
        let up = indexTip.right * (chirality == .left ? 1 : -1)
        return up.y > 0
               && indexTip.position.distance(to: middleTip.position) > 0.05
    }
    
    func isDropping(chirality: HandAnchor.Chirality) -> Bool {
        guard let wrist = getTransform(chirality, .wrist) else { return false }
        switch chirality {
        case .right:
            return wrist.up.y > 0.7
        case .left:
            return wrist.up.y < -0.7
        }
    }
    
    var isClapping: Bool {
        guard let leftKnuckle = getTransform(.left, .littleFingerKnuckle),
              let rightKnuckle = getTransform(.right, .littleFingerKnuckle)
        else { return false }
        return leftKnuckle.position.distance(to: rightKnuckle.position) < 0.05
    }
}
