import SwiftUI
import RealityKit
import SWAYcoreKit
import simd

/// Where bundled production characters live: <bundle>/Characters/<id>.usdz (+ <id>.character.json).
public enum CharacterAssets {
    public static var bundle: Bundle = .main
    public static func url(_ id: String) -> URL? {
        bundle.url(forResource: id, withExtension: "usdz", subdirectory: "Characters") ?? bundle.url(forResource: id, withExtension: "usdz")
    }
    public static func manifest(_ id: String) -> CharacterManifest? {
        guard let u = bundle.url(forResource: id + ".character", withExtension: "json", subdirectory: "Characters") ?? bundle.url(forResource: id + ".character", withExtension: "json"),
              let d = try? Data(contentsOf: u) else { return nil }
        return try? JSONDecoder().decode(CharacterManifest.self, from: d)
    }
    /// Product-facing truth: a character is available only if the asset exists AND its manifest satisfies the rig contract.
    public static func availability(_ id: String) -> (ok: Bool, reason: String?) {
        guard url(id) != nil else { return (false, "Character asset not bundled (run the SWAYcore builder to generate production assets).") }
        guard let m = manifest(id) else { return (false, "Character manifest missing.") }
        let issues = RigContract.validate(m)
        return issues.isEmpty ? (true, nil) : (false, issues.joined(separator: "; "))
    }
}

/// Drives a skinned character's skeleton from a normalized Pose through the shared retargeting contract.
@MainActor public final class CharacterRig {
    public let root = Entity()
    private var model: ModelEntity?
    private var jointIndex: [SWAYJoint: Int] = [:]
    private var restLocal: [Transform] = []
    private var restWorldRot: [SWAYJoint: simd_quatf] = [:]
    public private(set) var failure: String?

    public init() {}

    public func load(characterID: String, hair: String? = nil, outfit: String? = nil) async {
        guard let url = CharacterAssets.url(characterID) else { failure = "asset missing"; return }
        do {
            let e = try await Entity(contentsOf: url)
            root.addChild(e)
            guard let m = Self.firstSkinned(e) else { failure = "no skinned model in asset"; return }
            model = m
            for (i, path) in m.jointNames.enumerated() {
                let leaf = path.split(separator: "/").last.map(String.init) ?? path
                if let j = SWAYJoint(rawValue: leaf) { jointIndex[j] = i }
            }
            guard jointIndex.count == SWAYJoint.allCases.count else { failure = "skeleton joints \(jointIndex.count)/23"; return }
            restLocal = m.jointTransforms
            var w: [SWAYJoint: simd_quatf] = [:]
            func world(_ j: SWAYJoint) -> simd_quatf {
                if let c = w[j] { return c }
                let local = restLocal[jointIndex[j]!].rotation
                let r = Skeleton.parent[j].map { world($0) * local } ?? local
                w[j] = r; return r
            }
            for j in SWAYJoint.allCases { _ = world(j) }
            restWorldRot = w
            applyVariant(hair: hair, outfit: outfit, in: e)
        } catch { failure = "load: \(error.localizedDescription)" }
    }

    static func firstSkinned(_ e: Entity) -> ModelEntity? {
        if let m = e as? ModelEntity, !m.jointNames.isEmpty { return m }
        for c in e.children { if let f = firstSkinned(c) { return f } }
        return nil
    }

    /// Variants are separate meshes named Hair_<style> / Outfit_<name>; only the selection is enabled.
    public func applyVariant(hair: String?, outfit: String?, in e: Entity? = nil) {
        let r = e ?? root
        func visit(_ n: Entity) {
            if n.name.hasPrefix("Hair_") { n.isEnabled = (hair != nil && n.name == "Hair_" + hair!) }
            if n.name.hasPrefix("Outfit_") { n.isEnabled = (outfit != nil && n.name == "Outfit_" + outfit!) }
            n.children.forEach(visit)
        }
        visit(r)
        if let hair { root.findEntity(named: "Hair")?.isEnabled = (hair == "default") }
        if let outfit { root.findEntity(named: "Outfit")?.isEnabled = (outfit == "default") }
    }

    /// Applies a pose. `mirrorDisplay` swaps sides so the performer reads like a mirror to the viewer (ND-012).
    public func apply(_ pose: Pose, mirrorDisplay: Bool = true) {
        guard let model, failure == nil else { return }
        let p = mirrorDisplay ? pose.mirroredPose() : pose
        let delta = PoseRetargeter.worldRotations(for: p)
        var worldTarget: [SWAYJoint: simd_quatf] = [:]
        var t = model.jointTransforms
        func target(_ j: SWAYJoint) -> simd_quatf {
            if let c = worldTarget[j] { return c }
            let d = delta[j] ?? .identity
            let q = simd_quatf(ix: Float(d.x), iy: Float(d.y), iz: Float(d.z), r: Float(d.w)) * restWorldRot[j]!
            worldTarget[j] = q; return q
        }
        for j in SWAYJoint.allCases {
            let local = Skeleton.parent[j].map { target($0).inverse * target(j) } ?? target(j)
            t[jointIndex[j]!].rotation = simd_normalize(local)
        }
        model.jointTransforms = t
    }

    public func setOpacity(_ o: Float) { root.components.set(OpacityComponent(opacity: o)) }
}

public struct CharacterStageView: View {
    let characterID: String
    let pose: Pose?
    var youCharacterID: String? = nil
    var youPose: Pose? = nil
    var youOpacity: Double = 0.45
    var hair: String? = nil
    var outfit: String? = nil
    @State private var coach = CharacterRig()
    @State private var you = CharacterRig()
    @State private var status: String?

    public init(characterID: String, pose: Pose?, youCharacterID: String? = nil, youPose: Pose? = nil, youOpacity: Double = 0.45, hair: String? = nil, outfit: String? = nil) {
        self.characterID = characterID; self.pose = pose; self.youCharacterID = youCharacterID; self.youPose = youPose
        self.youOpacity = youOpacity; self.hair = hair; self.outfit = outfit
    }

    public var body: some View {
        ZStack {
            if let status {
                // Honest unavailable state (diagnostic, not a substitute character).
                VStack(spacing: 8) { Image(systemName: "figure.dance").font(.largeTitle); Text("Character unavailable").font(.headline); Text(status).font(.caption).multilineTextAlignment(.center) }
                    .foregroundStyle(SwayTheme.subtext).padding()
            }
            RealityView { content in
                await coach.load(characterID: characterID, hair: hair, outfit: outfit)
                if let f = coach.failure { status = f } else { content.add(coach.root) }
                if let yid = youCharacterID { await you.load(characterID: yid); if you.failure == nil { you.setOpacity(Float(youOpacity)); content.add(you.root) } }
                let cam = PerspectiveCamera(); cam.position = [0, 0.95, 3.4]; cam.look(at: [0, 0.9, 0], from: cam.position, relativeTo: nil)
                content.add(cam)
                let light = DirectionalLight(); light.look(at: .zero, from: [1.5, 3, 3], relativeTo: nil); content.add(light)
            } update: { _ in
                if let pose { coach.apply(pose) }
                if let youPose { you.setOpacity(Float(youOpacity)); you.apply(youPose) }
            }
            .realityViewCameraControls(.none)
        }
        .accessibilityLabel("Dance coach")
    }
}
