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

    // Frozen public stage API; the production-capable COACH and YOUR DANCER
    // use the common approval-gated RealityKit adapter. Do not double mirror:
    // this stage already applies the user's mirror choice to its entire content.
    // Unapproved historical art remains only a development bridge, never a 3D PASS.
    @ViewBuilder private var content: some View {
        switch source {
        case let .move(id, musicalTime, bpm, paused):
            if character == .lucia || character == .yourDancer {
                SWAYAvatarStageView(
                    role: character == .lucia ? .coach : .user,
                    moveID: id, elapsed: musicalTime, bpm: bpm,
                    paused: paused, mirrored: false, profile: profile,
                    cutout: AnyView(
                        SWAYCoachPuppetView(moveID: id, musicalTime: musicalTime, bpm: bpm,
                                            character: character.rawValue, profile: profile)
                            .transaction { transaction in
                                if paused { transaction.animation = nil }
                            }
                    ))
            } else {
                SWAYCoachPuppetView(moveID: id, musicalTime: musicalTime, bpm: bpm,
                                    character: character.rawValue, profile: profile)
                    .transaction { transaction in
                        if paused { transaction.animation = nil }
                    }
            }
        case let .tracked(pose, visible):
            // Live tracked YOU is a distinct role and must not be impersonated
            // by a static/customizable avatar. Preserve the existing tracking path.
            SWAYTrackedPuppetView(pose: pose, visible: visible, profile: profile, character: character.rawValue)
        case .idle:
            if character == .lucia || character == .yourDancer {
                SWAYAvatarStageView(
                    role: character == .lucia ? .coach : .user,
                    moveID: "idle", elapsed: 0, bpm: 100, paused: true, mirrored: false, profile: profile,
                    cutout: AnyView(
                        SWAYCoachPuppetView(moveID: "step-touch", musicalTime: 0, bpm: 100,
                                            character: character.rawValue, profile: profile)
                    ))
            } else {
                SWAYCoachPuppetView(moveID: "step-touch", musicalTime: 0, bpm: 100,
                                    character: character.rawValue, profile: profile)
            }
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
        case .top: return "Outfit"
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
    /// Only bundled, visibly distinct art is selectable. No fake Create-a-Dancer options.
    /// Outfit selects a coordinated top + bottom + accent palette; other categories stay hidden
    /// until their separate, authored assets exist.
    static func options(_ category: SWAYAvatarCategory) -> [SWAYAvatarOption] {
        let labels: [String]
        switch category {
        case .skin: labels = ["Light", "Medium", "Umber"]
        case .top: labels = ["Emerald", "Ocean", "Violet"]
        default: return []
        }
        return labels.enumerated().map { index, name in
            SWAYAvatarOption(id: category.rawValue + "_" + String(index),
                             category: category, index: index,
                             displayName: name, available: true)
        }
    }

    static func selectedIndex(_ category: SWAYAvatarCategory, in profile: SwayCharacterProfile) -> Int {
        switch category {
        case .body: return SwayBodyStyle.allCasesIndex(profile.bodyStyle)
        case .skin: return max(0, min(2, profile.skinTone))
        case .face: return profile.faceShape
        case .hair: return profile.hairStyle
        case .hairColor: return profile.hairColor
        case .top, .bottom: return max(0, min(2, profile.outfitStyle))
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
