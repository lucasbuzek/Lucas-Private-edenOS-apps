import SwiftUI
import SWAYcoreEngine

/// Production illustrated 2.5D character consumer. YOUR DANCER is assembled from
/// separated, pose-aligned component masks; the coach atlas remains unchanged.
struct SWAYSkeletal2DAvatarView: View {
    enum Role { case coach, user }
    let role: Role
    let moveID: String
    let musicalTime: TimeInterval
    let bpm: Double
    let paused: Bool
    let mirrored: Bool
    var profile: SwayCharacterProfile? = nil

    private static let componentManifest = try? SWAY2DComponentManifest.load()

    var body: some View {
        let pose = illustratedPoseIndex
        Group {
            if role == .coach {
                Image(String(format: "LuciaPose%02d", pose))
                    .resizable()
                    .scaledToFit()
            } else if let manifest = Self.componentManifest {
                componentAvatar(manifest: manifest, pose: pose)
            } else {
                // Safe compatibility path for an incomplete/corrupt install. This is still
                // separated Build 143 artwork, never a flattened concept-sheet cutout.
                legacySeparatedAvatar(pose: pose)
            }
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        .accessibilityLabel(role == .coach ? "Lucia, SWAY coach, illustrated 2.5D" : "Your SWAY dancer, illustrated 2.5D")
        .accessibilityIdentifier(role == .coach ? "sway.avatar.durer2d.coach" : "sway.avatar.components2d.user")
    }

    @ViewBuilder
    private func componentAvatar(manifest: SWAY2DComponentManifest, pose: Int) -> some View {
        let appearance = SWAY2DComponentResolver.resolve(profile: profile ?? SwayCharacterProfile(), pose: pose, manifest: manifest)
        ZStack {
            ForEach(appearance.orderedLayers, id: \.category) { layer in
                Image(layer.assetName)
                    .resizable()
                    .scaledToFit()
                    .colorMultiply(tint(for: layer.tintRole, appearance: appearance))
                    .scaleEffect(layerScale(layer.scaleGroup, appearance: appearance))
                    .accessibilityHidden(true)
            }
        }
        .scaleEffect(appearance.bodyScale)
    }

    @ViewBuilder
    private func legacySeparatedAvatar(pose: Int) -> some View {
        ZStack {
            Image(String(format: "UserPose%02dDetail", pose)).resizable().scaledToFit()
            Image(String(format: "UserPose%02dSkin", pose)).resizable().scaledToFit().colorMultiply(legacySkinColor)
            Image(String(format: "UserPose%02dHair", pose)).resizable().scaledToFit().colorMultiply(legacyHairColor)
            Image(String(format: "UserPose%02dAccent", pose)).resizable().scaledToFit().colorMultiply(legacyOutfitColor)
        }
    }

    private func tint(for role: String?, appearance: SWAYResolved2DAppearance) -> Color {
        guard let role, let hex = appearance.tintHex[role] else { return .white }
        return Color(swayHex: hex)
    }

    private func layerScale(_ group: String, appearance: SWAYResolved2DAppearance) -> CGFloat {
        switch group {
        case "head": return CGFloat(appearance.headScale)
        case "hair": return CGFloat(appearance.headScale * appearance.hairScale)
        case "body": return CGFloat(appearance.limbScale)
        default: return 1
        }
    }

    /// Counts 1...8 select one of the twelve authored pose frames deterministically.
    private var illustratedPoseIndex: Int {
        let beat = musicalTime * max(SwayTimelineMath.minimumBPM, bpm) / 60.0
        let count = max(0, Int(floor(beat + 0.0001))) % 8
        let id = moveID.lowercased().replacingOccurrences(of: "_", with: "-")
        let atlas: [Int]
        if id.contains("march") { atlas = [1, 2, 3, 2, 1, 3, 2, 1] }
        else if id.contains("step-touch") || id.contains("side") { atlas = [1, 4, 5, 4, 1, 5, 4, 1] }
        else if id.contains("knee") { atlas = [1, 6, 7, 6, 1, 7, 6, 1] }
        else if id.contains("grape") { atlas = [1, 5, 4, 8, 1, 4, 5, 8] }
        else if id.contains("squat") { atlas = [1, 8, 8, 1, 1, 8, 8, 1] }
        else if id.contains("jump") || id.contains("reach") { atlas = [1, 9, 10, 9, 1, 10, 9, 1] }
        else if id.contains("sway") || id.contains("roll") { atlas = [1, 11, 12, 11, 1, 12, 11, 1] }
        else { atlas = [1, 4, 5, 6, 7, 8, 9, 10] }
        return atlas[count]
    }

    private var legacySkinColor: Color {
        let values = ["#F6C8AA", "#DB9E75", "#AD6D4C", "#784733", "#4F2E23"]
        return Color(swayHex: values[safe: profile?.skinTone ?? 2])
    }
    private var legacyHairColor: Color {
        let values = ["#29140D", "#452112", "#080707", "#611F14", "#A3471F", "#BA914C"]
        return Color(swayHex: values[safe: profile?.hairColor ?? 0])
    }
    private var legacyOutfitColor: Color {
        let values = ["#D11F7A", "#24A6C7", "#7A4FDC", "#F27A2B", "#1FB878"]
        return Color(swayHex: values[safe: profile?.outfitStyle ?? 0])
    }
}

private extension Array where Element == String {
    subscript(safe value: Int) -> String {
        guard !isEmpty else { return "#FFFFFF" }
        let index = ((value % count) + count) % count
        return self[index]
    }
}
