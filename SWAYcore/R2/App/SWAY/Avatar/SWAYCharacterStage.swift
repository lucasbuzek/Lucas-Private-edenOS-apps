import SwiftUI

// FROZEN INTEGRATION CONTRACT (2026-10-08) between the three parallel release tasks:
//   Task 1 AVATARS owns the implementation behind this file.
//   Task 2 MECHANICS supplies poses (SwayBodyPose, SwayCoachPoseEngine) and profile persistence.
//   Task 3 UI renders every character ONLY through SWAYCharacterStage and builds the
//   YOUR DANCER creator ONLY on SWAYAvatarCatalog.
// The public names and signatures below must not change without a recorded decision.
// Internals (bodies of these types) may be replaced freely by Task 1.

enum SWAYCharacterID: String, CaseIterable, Codable, Sendable {
    case lucia, nandi, thabo, zuri, kyle, yourDancer
    var displayName: String {
        switch self {
        case .lucia: return "Lucia"
        case .nandi: return "Nandi"
        case .thabo: return "Thabo"
        case .zuri: return "Zuri"
        case .kyle: return "Kyle"
        case .yourDancer: return "Your Dancer"
        }
    }
}

enum SWAYPoseSource {
    /// Coach/character performing an authored move on the shared musical clock.
    case move(id: String, musicalTime: TimeInterval, bpm: Double, paused: Bool)
    /// Live camera-tracked body (the YOU representation). `visible` false = tracking lost.
    case tracked(SwayBodyPose, visible: Bool)
    /// Neutral standing pose (menus, thumbnails, creator preview).
    case idle
}

struct SWAYCharacterStage: View {
    let character: SWAYCharacterID
    let source: SWAYPoseSource
    var profile: SwayCharacterProfile? = nil
    var mirrored: Bool = false

    var body: some View {
        content.scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }

    // Placeholder routing until Task 1 replaces it: every character currently renders the
    // Lucia puppet pilot. Task 1 must route `character` to its own part set.
    @ViewBuilder private var content: some View {
        switch source {
        case let .move(id, musicalTime, bpm, _):
            SWAYCoachPuppetView(moveID: id, musicalTime: musicalTime, bpm: bpm)
        case let .tracked(pose, visible):
            SWAYTrackedPuppetView(pose: pose, visible: visible, profile: profile)
        case .idle:
            SWAYCoachPuppetView(moveID: "step-touch", musicalTime: 0, bpm: 100)
        }
    }
}

enum SWAYAvatarCategory: String, CaseIterable, Codable, Sendable {
    case body, skin, face, hair, hairColor, top, bottom, shoes, accessory
    var displayName: String {
        switch self {
        case .body: return "Body"
        case .skin: return "Skin"
        case .face: return "Face"
        case .hair: return "Hair"
        case .hairColor: return "Hair Colour"
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .shoes: return "Shoes"
        case .accessory: return "Accessory"
        }
    }
}

struct SWAYAvatarOption: Identifiable, Hashable, Sendable {
    let id: String
    let category: SWAYAvatarCategory
    let index: Int
    let displayName: String
    /// false = art not delivered yet; UI must hide or visibly disable it, never fake it.
    let available: Bool
}

enum SWAYAvatarCatalog {
    /// Task 1 replaces this table with the real part-kit catalogue.
    private static let counts: [SWAYAvatarCategory: Int] = [
        .body: 1, .skin: 1, .face: 1, .hair: 1, .hairColor: 1, .top: 1, .bottom: 1, .shoes: 1, .accessory: 1
    ]

    static func options(_ category: SWAYAvatarCategory) -> [SWAYAvatarOption] {
        let count: Int = counts[category] ?? 0
        return (0..<count).map { (i: Int) -> SWAYAvatarOption in
            SWAYAvatarOption(id: category.rawValue + "_" + String(i), category: category, index: i,
                             displayName: category.displayName + " " + String(i + 1), available: i == 0)
        }
    }

    static func selectedIndex(_ category: SWAYAvatarCategory, in profile: SwayCharacterProfile) -> Int {
        switch category {
        case .body: return SwayBodyStyle.allCasesIndex(profile.bodyStyle)
        case .skin: return profile.skinTone
        case .face: return profile.faceShape
        case .hair: return profile.hairStyle
        case .hairColor: return profile.hairColor
        case .top, .bottom: return profile.outfitStyle
        case .shoes: return profile.footwearStyle
        case .accessory: return profile.accessoryStyle
        }
    }

    static func apply(_ option: SWAYAvatarOption, to profile: inout SwayCharacterProfile) {
        switch option.category {
        case .body: profile.bodyStyle = SwayBodyStyle.fromIndex(option.index)
        case .skin: profile.skinTone = option.index
        case .face: profile.faceShape = option.index
        case .hair: profile.hairStyle = option.index
        case .hairColor: profile.hairColor = option.index
        case .top, .bottom: profile.outfitStyle = option.index
        case .shoes: profile.footwearStyle = option.index
        case .accessory: profile.accessoryStyle = option.index
        }
    }
}

extension SwayBodyStyle {
    static func allCasesIndex(_ style: SwayBodyStyle) -> Int {
        let all: [SwayBodyStyle] = SwayBodyStyle.allCases
        return all.firstIndex(of: style) ?? 0
    }
    static func fromIndex(_ index: Int) -> SwayBodyStyle {
        let all: [SwayBodyStyle] = SwayBodyStyle.allCases
        return (index >= 0 && index < all.count) ? all[index] : .neutral
    }
}
