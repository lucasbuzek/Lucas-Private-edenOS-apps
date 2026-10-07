import Foundation
import SwiftUI

/// Runtime contract for the separated, pose-aligned YOUR DANCER art library.
/// AssetFactory owns the identical source manifest; the bundled copy is consumed here.
struct SWAY2DComponentManifest: Decodable, Sendable {
    struct Canvas: Decodable, Sendable { let width: Int; let height: Int; let alignment: String }
    struct Option: Decodable, Hashable, Sendable { let id: String; let name: String; let assetStem: String }
    struct Layer: Decodable, Sendable {
        let id: String
        let drawOrder: Int
        let profileField: String
        let tintRole: String?
        let scaleGroup: String
        let options: [Option]
    }
    let format: String
    let version: Int
    let poseCount: Int
    let assetNamePattern: String
    let canvas: Canvas
    let palettes: [String: [String]]
    let layers: [Layer]

    static func load(bundle: Bundle = .main) throws -> Self {
        let name = "your_dancer_2_5d_components"
        let bundles = bundle === Bundle.main ? [bundle] : [bundle, .main]
        let urls = bundles.flatMap { candidate in [
            candidate.url(forResource: name, withExtension: "json", subdirectory: "Avatars/User2_5D"),
            candidate.url(forResource: name, withExtension: "json")
        ] }
        guard let url = urls.compactMap({ $0 }).first else {
            throw NSError(domain: "SWAY2DComponents", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "YOUR DANCER component manifest is missing."])
        }
        let manifest = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard manifest.format == "SWAY-YOUR-DANCER-2.5D-COMPONENTS",
              manifest.version == 1, manifest.poseCount == 12,
              manifest.canvas.width > 0, manifest.canvas.height > 0,
              !manifest.layers.isEmpty,
              manifest.layers.allSatisfy({ !$0.options.isEmpty }) else {
            throw NSError(domain: "SWAY2DComponents", code: 422,
                          userInfo: [NSLocalizedDescriptionKey: "YOUR DANCER component manifest is invalid."])
        }
        return manifest
    }
}

struct SWAYResolved2DLayer: Equatable, Sendable {
    let category: String
    let optionID: String
    let assetName: String
    let drawOrder: Int
    let tintRole: String?
    let scaleGroup: String
}

struct SWAYResolved2DAppearance: Equatable, Sendable {
    let pose: Int
    let orderedLayers: [SWAYResolved2DLayer]
    let tintHex: [String: String]
    let bodyScale: Double
    let headScale: Double
    let limbScale: Double
    let hairScale: Double
}

enum SWAY2DComponentResolver {
    private static func wrapped(_ value: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((value % count) + count) % count
    }

    static func resolve(profile: SwayCharacterProfile, pose: Int,
                        manifest: SWAY2DComponentManifest) -> SWAYResolved2DAppearance {
        let safePose = wrapped(pose - 1, count: manifest.poseCount) + 1
        func selection(for field: String) -> Int {
            switch field {
            case "bodyStyle":
                switch profile.bodyStyle { case .neutral: return 0; case .female: return 1; case .male: return 2 }
            case "faceShape": return profile.faceShape
            case "eyeStyle": return profile.eyeStyle
            case "browStyle": return profile.browStyle
            case "noseStyle": return profile.noseStyle
            case "mouthStyle": return profile.mouthStyle
            case "facialHairStyle": return profile.facialHairStyle
            case "hairStyle": return profile.hairStyle
            case "outfitStyle": return profile.outfitStyle
            case "footwearStyle": return profile.footwearStyle
            case "accessoryStyle": return profile.accessoryStyle
            default: return 0
            }
        }
        let resolved = manifest.layers.map { layer -> SWAYResolved2DLayer in
            let option = layer.options[wrapped(selection(for: layer.profileField), count: layer.options.count)]
            return .init(category: layer.id, optionID: option.id,
                         assetName: "YD2D_\(option.assetStem)_P\(String(format: "%02d", safePose))",
                         drawOrder: layer.drawOrder, tintRole: layer.tintRole, scaleGroup: layer.scaleGroup)
        }.sorted { lhs, rhs in
            lhs.drawOrder == rhs.drawOrder ? lhs.category < rhs.category : lhs.drawOrder < rhs.drawOrder
        }
        func palette(_ key: String, _ index: Int) -> String {
            let values = manifest.palettes[key] ?? ["#FFFFFF"]
            return values[wrapped(index, count: values.count)]
        }
        return .init(pose: safePose, orderedLayers: resolved,
                     tintHex: ["skin": palette("skinTone", profile.skinTone),
                               "hair": palette("hairColor", profile.hairColor),
                               "outfit": palette("outfitColor", profile.outfitStyle),
                               "accent": palette("accent", profile.appearancePreset),
                               "skinDetail": palette("skinTone", profile.skinTone)],
                     bodyScale: profile.bodyScale, headScale: profile.headScale,
                     limbScale: profile.limbScale, hairScale: profile.hairScale)
    }
}

extension Color {
    init(swayHex: String) {
        let value = UInt64(swayHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0xFFFFFF
        self.init(red: Double((value >> 16) & 0xff) / 255,
                  green: Double((value >> 8) & 0xff) / 255,
                  blue: Double(value & 0xff) / 255)
    }
}
