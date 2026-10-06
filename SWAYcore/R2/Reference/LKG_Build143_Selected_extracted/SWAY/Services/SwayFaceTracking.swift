import Foundation
import SwiftUI

#if canImport(ARKit)
import ARKit

@MainActor
final class SwayFaceExpressionDriver: NSObject, ObservableObject, ARSessionDelegate {
    @Published private(set) var supported = ARFaceTrackingConfiguration.isSupported
    @Published private(set) var tracking = false
    @Published private(set) var blinkLeft: Double = 0
    @Published private(set) var blinkRight: Double = 0
    @Published private(set) var jawOpen: Double = 0
    @Published private(set) var smile: Double = 0
    @Published private(set) var brow: Double = 0
    @Published private(set) var cheekPuff: Double = 0

    private let session = ARSession()

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard ARFaceTrackingConfiguration.isSupported else { supported = false; return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
        tracking = false
    }

    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let face = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        let values = face.blendShapes
        func value(_ key: ARFaceAnchor.BlendShapeLocation) -> Double { values[key]?.doubleValue ?? 0 }
        let l = value(.mouthSmileLeft), r = value(.mouthSmileRight)
        let b = max(value(.browInnerUp), max(value(.browOuterUpLeft), value(.browOuterUpRight)))
        let leftBlink = value(.eyeBlinkLeft), rightBlink = value(.eyeBlinkRight)
        let jaw = value(.jawOpen), puff = value(.cheekPuff)
        Task { @MainActor in
            self.tracking = face.isTracked
            self.blinkLeft = leftBlink
            self.blinkRight = rightBlink
            self.jawOpen = jaw
            self.smile = (l + r) / 2
            self.brow = b
            self.cheekPuff = puff
        }
    }
}
#else
@MainActor
final class SwayFaceExpressionDriver: ObservableObject {
    @Published private(set) var supported = false
    @Published private(set) var tracking = false
    @Published private(set) var blinkLeft: Double = 0
    @Published private(set) var blinkRight: Double = 0
    @Published private(set) var jawOpen: Double = 0
    @Published private(set) var smile: Double = 0
    @Published private(set) var brow: Double = 0
    @Published private(set) var cheekPuff: Double = 0
    func start() {}
    func stop() {}
}
#endif

struct SwayExpressionBadge: View {
    @ObservedObject var driver: SwayFaceExpressionDriver
    var body: some View {
        HStack(spacing:10) {
            Circle().fill(driver.tracking ? Color.green : Color.secondary).frame(width:8,height:8)
            Text(driver.tracking ? "FACE LIVE" : (driver.supported ? "LOOK AT CAMERA" : "FACE PREVIEW UNAVAILABLE"))
                .font(.caption.bold())
            Spacer()
            if driver.tracking {
                if driver.smile > 0.35 { Image(systemName:"face.smiling.fill") }
                else if driver.jawOpen > 0.35 { Image(systemName:"mouth.fill") }
                else { Image(systemName:"face.smiling") }
            }
        }
        .foregroundStyle(driver.tracking ? Color.green : Color.secondary)
        .padding(.horizontal,14).padding(.vertical,10)
        .background(Color.white.opacity(0.06),in:Capsule())
    }
}
