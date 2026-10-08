import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Cut-out puppet rig authored by AssetFactory/puppet (cut.py): one rigid bitmap per
/// SWAYHumanoid-v1 bone, a pivot at the proximal joint and the rest pose it was cut from.
struct SWAYRig: Decodable {
    struct Part: Decodable {
        let name: String
        let file: String
        let z: Int
        let bone: [String]
        let size: [Double]
        let pivot: [Double]
    }
    let view: String
    let canvas: [Double]
    let joints: [String: [Double]]
    let parts: [Part]

    func rest(_ joint: String) -> CGPoint? {
        guard let p = joints[joint], p.count == 2 else { return nil }
        return CGPoint(x: p[0], y: p[1])
    }
}

/// Bundle loader with caches. Resources are flattened, so names carry character and view.
enum SWAYRigLibrary {
    nonisolated(unsafe) private static var rigs: [String: SWAYRig] = [:]
    nonisolated(unsafe) private static var missing: Set<String> = []
    #if canImport(UIKit)
    nonisolated(unsafe) private static var images: [String: UIImage] = [:]
    #endif

    static func rig(character: String, view: String) -> SWAYRig? {
        let key = "\(character)_\(view)_rig"
        if let cached = rigs[key] { return cached }
        if missing.contains(key) { return nil }
        guard let url = Bundle.main.url(forResource: key, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rig = try? JSONDecoder().decode(SWAYRig.self, from: data) else {
            missing.insert(key); return nil
        }
        rigs[key] = rig
        return rig
    }

    #if canImport(UIKit)
    static func image(_ file: String) -> UIImage? {
        if let cached = images[file] { return cached }
        let name = (file as NSString).deletingPathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        images[file] = image
        return image
    }
    #endif
}

/// Angle retargeting: only bone DIRECTIONS come from the coach clip / Vision; bone
/// LENGTHS come from the art, chained from the hips. The puppet therefore never tears
/// apart when the motion skeleton's proportions differ from the character's.
enum SWAYRigSolver {
    struct Placement { let file: String; let z: Int; let pivotInArt: CGPoint; let size: CGSize; let at: CGPoint; let rotation: Double; let scale: Double }

    /// child -> parent in the rig's joint tree
    static let parent: [String: String] = [
        "Spine": "Hips", "Neck": "Spine", "HeadTop": "Neck",
        "RightUpperArm": "Spine", "RightLowerArm": "RightUpperArm", "RightHand": "RightLowerArm", "RightHandTip": "RightHand",
        "LeftUpperArm": "Spine", "LeftLowerArm": "LeftUpperArm", "LeftHand": "LeftLowerArm", "LeftHandTip": "LeftHand",
        "RightUpperLeg": "Hips", "RightLowerLeg": "RightUpperLeg", "RightFoot": "RightLowerLeg", "RightToe": "RightFoot",
        "LeftUpperLeg": "Hips", "LeftLowerLeg": "LeftUpperLeg", "LeftFoot": "LeftLowerLeg", "LeftToe": "LeftFoot"]
    /// target joint used as the direction proxy for art-only terminal joints
    static let proxy: [String: String] = ["HeadTop": "Head"]
    /// bones whose rotation is inherited from another bone (shoulders ride the chest, hips' sockets ride the pelvis)
    static let inherit: [String: String] = [
        "RightUpperArm": "Neck", "LeftUpperArm": "Neck",
        "RightUpperLeg": "Spine", "LeftUpperLeg": "Spine",
        "RightHandTip": "RightHand", "LeftHandTip": "LeftHand"]
    /// terminal bones kept level (shoes stay flat on the floor)
    static let level: Set<String> = ["RightToe", "LeftToe"]

    private static func angle(_ a: CGPoint, _ b: CGPoint) -> Double { atan2(Double(b.y - a.y), Double(b.x - a.x)) }

    /// `target` is in canvas points. Returns nil when the torso is not available.
    static func solve(rig: SWAYRig, target: [String: CGPoint]) -> [Placement]? {
        guard let tHip = target["Hips"], let tNeck = target["Neck"],
              let rHip = rig.rest("Hips"), let rNeck = rig.rest("Neck") else { return nil }
        let restTorso = hypot(rNeck.x - rHip.x, rNeck.y - rHip.y)
        let targetTorso = hypot(tNeck.x - tHip.x, tNeck.y - tHip.y)
        guard restTorso > 1, targetTorso > 1 else { return nil }
        let scale = Double(targetTorso / restTorso)

        // delta rotation (target world angle - rest world angle) for the bone ending at `joint`
        var delta: [String: Double] = [:]
        func boneDelta(_ joint: String) -> Double {
            if let d = delta[joint] { return d }
            var d = 0.0
            if level.contains(joint) {
                d = 0
            } else if let from = inherit[joint] {
                d = boneDelta(from)
            } else if let p = parent[joint], let rp = rig.rest(p), let rj = rig.rest(joint),
                      let tp = target[p], let tj = target[proxy[joint] ?? joint],
                      hypot(tj.x - tp.x, tj.y - tp.y) > 0.5 {
                d = angle(tp, tj) - angle(rp, rj)
            } else if let p = parent[joint] {
                d = p == "Hips" ? 0 : boneDelta(p)   // missing target: follow parent
            }
            delta[joint] = d
            return d
        }
        // forward kinematics with the art's own bone lengths
        var pos: [String: CGPoint] = ["Hips": tHip]
        func position(_ joint: String) -> CGPoint? {
            if let p = pos[joint] { return p }
            guard let par = parent[joint], let pp = position(par),
                  let rp = rig.rest(par), let rj = rig.rest(joint) else { return nil }
            let d = boneDelta(joint)
            let vx = Double(rj.x - rp.x) * scale, vy = Double(rj.y - rp.y) * scale
            let p = CGPoint(x: pp.x + CGFloat(cos(d) * vx - sin(d) * vy), y: pp.y + CGFloat(sin(d) * vx + cos(d) * vy))
            pos[joint] = p
            return p
        }
        return rig.parts.compactMap { part in
            guard part.bone.count == 2, part.size.count == 2, part.pivot.count == 2,
                  let at = position(part.bone[0]) else { return nil }
            return Placement(file: part.file, z: part.z,
                             pivotInArt: CGPoint(x: part.pivot[0], y: part.pivot[1]),
                             size: CGSize(width: part.size[0], height: part.size[1]),
                             at: at, rotation: boneDelta(part.bone[1]), scale: scale)
        }.sorted { $0.z < $1.z }
    }
}

#if canImport(UIKit)
/// Draws a solved rig. `joints` are normalized (0...1) canvas coordinates.
struct SWAYRigPuppetCanvas: View {
    let rig: SWAYRig
    let joints: [String: CGPoint]
    var mirrored = false

    var body: some View {
        Canvas { context, size in
            let target = joints.mapValues { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
            guard let placements = SWAYRigSolver.solve(rig: rig, target: target) else { return }
            for item in placements {
                guard let image = SWAYRigLibrary.image(item.file) else { continue }
                var c = context
                c.translateBy(x: item.at.x, y: item.at.y)
                c.rotate(by: .radians(item.rotation))
                c.scaleBy(x: item.scale, y: item.scale)
                c.draw(Image(uiImage: image),
                       in: CGRect(x: -item.pivotInArt.x, y: -item.pivotInArt.y, width: item.size.width, height: item.size.height))
            }
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }
}
#endif
