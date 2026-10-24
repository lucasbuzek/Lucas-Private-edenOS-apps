#if DEBUG
import SwiftUI

/// DEBUG-only inspection screen. Launch with `-SWAYAvatarGallery` to see every
/// character in deterministic poses (front / back / side) plus one live dance loop.
/// Not compiled into Release builds; not a user-facing screen.
struct SWAYAvatarGalleryView: View {
    static var requested: Bool { ProcessInfo.processInfo.arguments.contains("-SWAYAvatarGallery") }

    private let shots: [(label: String, move: String, t: TimeInterval, angle: SWAYPuppetAngle)] = [
        ("idle", "step-touch", 0, .front),
        ("jack", "jumping-jack", 0.25, .front),
        ("lunge", "side-lunge", 0.5, .front),
        ("back", "grapevine", 0.75, .back),
        ("side", "march", 0.5, .right)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("SWAY avatar gallery (DEBUG)").font(.headline)
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    HStack(spacing: 8) {
                        ForEach(SWAYCharacterID.allCases, id: \.self) { id in
                            SWAYCharacterStage(character: id,
                                               source: .move(id: "hip-sway", musicalTime: t.truncatingRemainder(dividingBy: 8), bpm: 100, paused: false))
                                .frame(width: 58, height: 120)
                        }
                    }
                }
                ForEach(SWAYCharacterID.allCases, id: \.self) { id in
                    row(id)
                }
            }.padding(12)
        }
        .background(Color(white: 0.12))
        .foregroundStyle(.white)
    }

    private func row(_ id: SWAYCharacterID) -> some View {
        let probe = SWAYPuppetRenderer(joints: [:], angle: .front, character: id.rawValue)
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(id.displayName) — \(probe.hasOwnRig ? "own rig" : "Lucia rig fallback (not authored)")")
                .font(.caption.bold())
            HStack(spacing: 6) {
                ForEach(Array(shots.enumerated()), id: \.offset) { _, shot in
                    VStack(spacing: 2) {
                        SWAYPuppetRenderer(joints: SwayCoachPoseEngine.pose(moveID: shot.move, musicalTime: shot.t, bpm: 100).puppetJoints,
                                           angle: shot.angle, character: id.rawValue)
                            .frame(width: 66, height: 130)
                            .background(Color.white.opacity(0.06))
                        Text(shot.label).font(.system(size: 9))
                    }
                }
            }
        }
    }
}
#endif
