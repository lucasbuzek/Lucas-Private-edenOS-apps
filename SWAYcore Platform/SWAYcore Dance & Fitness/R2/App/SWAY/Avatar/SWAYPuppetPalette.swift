import Foundation

/// Offline palette lookup for YOUR DANCER's authored 2.5D puppet artwork.
/// Keeps rigs, pivots, bone lengths and their coach counterparts unchanged.
/// The manifest is generated from the same cutout PNGs and bundled with the app.
private struct SWAYPuppetPaletteManifest: Decodable {
    let format: String
    let version: Int
    let defaultSkin: Int
    let defaultOutfit: Int
    let skins: [String]
    let outfits: [String]
    let assets: [String: [String: String]]
}

enum SWAYPuppetPaletteResolver {
    private static let manifest: SWAYPuppetPaletteManifest? = {
        guard let url = Bundle.main.url(forResource: "yourDancer_palette_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(SWAYPuppetPaletteManifest.self, from: data),
              catalog.format == "SWAY-YOUR-DANCER-PALETTE",
              catalog.version == 1,
              catalog.skins.count == 3,
              catalog.outfits.count == 3 else { return nil }
        return catalog
    }()

    /// A production edit is visible ONLY if its material asset was delivered.
    /// No visual substitution is permitted for Lucia or the other coaches.
    static func file(_ base: String, profile: SwayCharacterProfile?) -> String {
        guard base.hasPrefix("yourDancer_"), let profile, let manifest else { return base }
        let skin = max(0, min(manifest.skins.count - 1, profile.skinTone))
        let outfit = max(0, min(manifest.outfits.count - 1, profile.outfitStyle))
        let key = "skin\(skin)_outfit\(outfit)"
        return manifest.assets[base]?[key] ?? base
    }

    static var hasDeliveredVariants: Bool {
        guard let manifest else { return false }
        return manifest.assets.count == 45 &&
            manifest.assets.values.allSatisfy { $0.count == 9 }
    }
}
