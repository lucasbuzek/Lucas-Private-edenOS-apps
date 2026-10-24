import Foundation

struct DanceMove: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var aliases: [String] = []
    var difficulty: Int
    var impact: Int
    var bpmMin: Int
    var bpmMax: Int
    var space: Int
    var style: String
    var counts: Int = 8
    var startFoot: String = "either"
    var endFoot: String = "either"
    var provenance: String = "SWAY Official"
    var version: String = "1.0.0"
    var easierID: String? = nil
    var harderID: String? = nil
    var accessibilityVariantID: String? = nil
}


struct SwayCreation: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable { case combination = "Combination", routine = "Routine" }
    var id: String = "user.creation.\(UUID().uuidString)"
    var name: String
    var kind: Kind
    var moveIDs: [String]
    var createdAt: Date = Date()
}

struct Transition: Codable, Hashable {
    var from: String
    var to: String
    var quality: Int // 1...5
}

struct WorkoutStep: Identifiable, Codable, Hashable {
    var id = UUID()
    var move: DanceMove
    var counts: Int = 8
}

enum SwayContentOrigin: String, Codable {
    case bundled, userCreated, directShare, officialPack, community, studio
}

enum SwayContentKind: String, Codable {
    case move, variation, combination, routine, workout, challenge, program, character, avatar, beats, mixed
}

struct SwayContentDependency: Codable, Hashable {
    var identifier: String
    var minimumVersion: String? = nil
}

struct SwayPackageMetadata: Codable {
    var packageID: String = UUID().uuidString
    var title: String = "Shared SWAY Content"
    var createdAt: Date = Date()
    var origin: SwayContentOrigin = .userCreated
    var kind: SwayContentKind = .mixed
    var minimumCoreVersion: String = "0.9"
    var dependencies: [SwayContentDependency] = []
    var creatorID: String? = nil
    var creatorDisplayName: String? = nil
}

/// Portable Alpha content container. The same envelope is deliberately used by
/// direct Share Sheet/AirDrop imports and future official/community transports.
/// Distribution changes; choreography data does not.
struct SwayPackage: Codable, Identifiable {
    var format: String = "swaypack"
    var version: Int = 2
    var creator: String
    var moves: [DanceMove]
    var transitions: [Transition]
    var metadata: SwayPackageMetadata? = nil
    var creations: [SwayCreation]? = nil
    var id:String { metadata?.packageID ?? "\(creator)-\(version)" }

    func validate() throws {
        guard format == "swaypack" else { throw SwayPackageError.unsupportedFormat }
        guard (1...2).contains(version) else { throw SwayPackageError.unsupportedVersion(version) }
        guard moves.count <= 5000, transitions.count <= 20000, (creations?.count ?? 0) <= 2000 else { throw SwayPackageError.packageTooLarge }
        let ids = moves.map(\.id)
        guard Set(ids).count == ids.count else { throw SwayPackageError.duplicateIdentifiers }
        guard moves.allSatisfy({ !$0.id.isEmpty && !$0.name.isEmpty && (1...64).contains($0.counts) }) else { throw SwayPackageError.invalidContent }
        guard (creations ?? []).allSatisfy({ !$0.id.isEmpty && !$0.name.isEmpty && !$0.moveIDs.isEmpty && $0.moveIDs.count <= 256 }) else { throw SwayPackageError.invalidContent }
    }
}

enum SwayPackageError: LocalizedError {
    case unsupportedFormat, unsupportedVersion(Int), packageTooLarge, duplicateIdentifiers, invalidContent
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "This is not a SWAY content package."
        case .unsupportedVersion(let v): return "SWAY package version \(v) is not supported by this build."
        case .packageTooLarge: return "This SWAY package is larger than the Alpha safety limit."
        case .duplicateIdentifiers: return "The SWAY package contains duplicate content identifiers."
        case .invalidContent: return "The SWAY package contains invalid movement data."
        }
    }
}


// MARK: - SWAY Music Core 0.4
enum SwayMusicProvider: String, Codable, CaseIterable {
    case appleMusic, mediaLibrary, localFile, swayBeats, other
}

enum SwayMusicCapability: String, Codable, CaseIterable {
    case playback, metadata, pcmAnalysis, offline, playlistRead, playlistWrite
}

enum SwayTrackAvailability: String, Codable {
    case available, offline, streaming, unavailable, authorizationRequired
}

struct SwayRecordingIdentity: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var isrc: String?
    var musicBrainzRecordingID: String?
    var acoustID: String?
    var providerIDs: [String:String] = [:]
    var title: String
    var artist: String
    var duration: TimeInterval?
    var localFingerprint: String?
}

enum SwayAnalysisSource: String, Codable {
    case embeddedMetadata, providerMetadata, musicBrainz, acoustID, swayDerived, userCorrected
}

struct SwayTempoPoint: Codable, Hashable {
    var time: TimeInterval
    var bpm: Double
}

struct SwayTrackAnalysis: Identifiable, Codable {
    var id: UUID = UUID()
    var recording: SwayRecordingIdentity
    var schemaVersion: Int = 1
    var source: SwayAnalysisSource
    var confidence: Double
    var bpm: Double?
    var tempoMap: [SwayTempoPoint] = []
    var timeSignatureNumerator: Int?
    var timeSignatureDenominator: Int?
    var beatTimes: [TimeInterval] = []
    var downbeats: [TimeInterval] = []
    var phraseStarts: [TimeInterval] = []
    var sectionStarts: [TimeInterval] = []
    var energyCurve: [Double] = []
    var updatedAt: Date = Date()
}

struct SwayPlaylistEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var recording: SwayRecordingIdentity
    var choreographyID: String?
}

struct SwayPlaylist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var entries: [SwayPlaylistEntry] = []
    var nativeProvider: SwayMusicProvider?
    var nativePlaylistID: String?
}

struct SwayAudioMix: Codable {
    var master: Double = 1.0
    var music: Double = 1.0
    var beats: Double = 0.55
    var count: Double = 0.75
    var coach: Double = 0.8
}

enum SwayBeatStyle: String, Codable, CaseIterable, Identifiable {
    case simple = "Simple"
    case pop = "Pop"
    case house = "House"
    case disco = "Disco"
    case hipHop = "Hip-Hop"
    case latin = "Latin"
    case afro = "Afro"
    case percussion = "Percussion"
    case rock = "Rock"
    case minimal = "Minimal"
    var id: String { rawValue }
}

struct SwayBeatConfiguration: Codable {
    var style: SwayBeatStyle = .simple
    var bpm: Double = 120
    var intensity: Double = 0.5
    var complexity: Double = 0.35
    var swing: Double = 0
    var fills: Bool = true
    var phaseOffset: TimeInterval = 0
}


// MARK: - Character, Awards & shared session contract

enum SwayBodyStyle: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case neutral = "Neutral"
    case female = "Female"
    var id: String { rawValue }
}

struct SwayCharacterProfile: Codable {
    var bodyStyle: SwayBodyStyle = .neutral
    var portraitData: Data? = nil
    var skinTone: Int = 2
    var hairStyle: Int = 0
    var outfitStyle: Int = 0
    var appearancePreset: Int = 0
    var faceShape: Int = 0
    var eyeStyle: Int = 0
    var browStyle: Int = 0
    var noseStyle: Int = 0
    var mouthStyle: Int = 0
    var hairColor: Int = 0
    var facialHairStyle: Int = 0
    var accessoryStyle: Int = 0
    var footwearStyle: Int = 0

    enum CodingKeys: String, CodingKey { case bodyStyle, portraitData, skinTone, hairStyle, outfitStyle, appearancePreset, faceShape, eyeStyle, browStyle, noseStyle, mouthStyle, hairColor, facialHairStyle, accessoryStyle, footwearStyle }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bodyStyle = try c.decodeIfPresent(SwayBodyStyle.self, forKey:.bodyStyle) ?? .neutral
        portraitData = try c.decodeIfPresent(Data.self, forKey:.portraitData)
        skinTone = try c.decodeIfPresent(Int.self, forKey:.skinTone) ?? 2
        hairStyle = try c.decodeIfPresent(Int.self, forKey:.hairStyle) ?? 0
        outfitStyle = try c.decodeIfPresent(Int.self, forKey:.outfitStyle) ?? 0
        appearancePreset = try c.decodeIfPresent(Int.self, forKey:.appearancePreset) ?? 0
        faceShape = try c.decodeIfPresent(Int.self, forKey:.faceShape) ?? 0
        eyeStyle = try c.decodeIfPresent(Int.self, forKey:.eyeStyle) ?? 0
        browStyle = try c.decodeIfPresent(Int.self, forKey:.browStyle) ?? 0
        noseStyle = try c.decodeIfPresent(Int.self, forKey:.noseStyle) ?? 0
        mouthStyle = try c.decodeIfPresent(Int.self, forKey:.mouthStyle) ?? 0
        hairColor = try c.decodeIfPresent(Int.self, forKey:.hairColor) ?? 0
        facialHairStyle = try c.decodeIfPresent(Int.self, forKey:.facialHairStyle) ?? 0
        accessoryStyle = try c.decodeIfPresent(Int.self, forKey:.accessoryStyle) ?? 0
        footwearStyle = try c.decodeIfPresent(Int.self, forKey:.footwearStyle) ?? 0
    }
}

enum SwayAwardID: String, Codable, CaseIterable {
    case firstDance, fiveDances, tenDances, sixtyMinutes, firstMoveMastered,
         fiveMovesMastered, flowEight, flowSixteen, firstSwayBeats, explorer,
         keptMoving, comeback, inTheGroove, strongFinish, fullEnergy, recoverySmart
}

struct SwayAward: Identifiable, Codable, Hashable {
    var id: SwayAwardID
    var title: String
    var detail: String
    var symbol: String
}

enum SwaySessionCommand: Codable, Equatable {
    case start
    case pause
    case resume
    case end
    case easier
    case harder
    case setIntensity(Int)
    case setBeatsEnabled(Bool)
    case setBeatsVolume(Double)
}

enum SwaySessionPhase: String, Codable {
    case idle, countdown, dancing, paused, completed, endedEarly
}

struct SwaySessionSnapshot: Codable, Equatable {
    var phase: SwaySessionPhase = .idle
    var moveName: String = ""
    var nextMoveName: String = ""
    var count: Int = 1
    var bar: Int = 0
    var phrase: Int = 0
    var combo: Int = 0
    var flow = false
    var intensity: Int = 2
    var cameraMessage: String = "Camera optional"
    var musicTitle: String = ""
    var bpm: Double = 120
}



// MARK: - Shared Sessions / SWAY Master
// One participant == one user on one independent SWAY device.
// Camera/pose analysis stays local. The transport exchanges compact session state only.
enum SwaySharedSessionTier: String, Codable, CaseIterable {
    case individual = "Individual"
    case together = "Dance Together"
    case household = "Family / Household"
    case master = "SWAY Master"

    var includedParticipantLimit: Int? {
        switch self {
        case .individual: return 1
        case .together: return 2
        case .household: return 6
        case .master: return nil       // capacity is declared by the active professional transport/plan
        }
    }
}

enum SwaySharedSessionRole: String, Codable {
    case host, participant
}

enum SwaySharedSessionTransport: String, Codable, CaseIterable {
    case local = "Nearby / LAN"
    case sharePlay = "SharePlay"
    case hosted = "Hosted"
}

enum SwayParticipantPresence: String, Codable {
    case invited, joining, ready, dancing, paused, finished, disconnected
}

struct SwaySharedParticipant: Identifiable, Codable, Equatable {
    var id: UUID
    var displayName: String
    var role: SwaySharedSessionRole
    var presence: SwayParticipantPresence
    var score: Double? = nil
    var combo: Int? = nil
    // No camera frames, face identity, or continuous pose/skeleton stream belongs here.
}

struct SwaySharedSessionDescriptor: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var hostID: UUID
    var tier: SwaySharedSessionTier = .together
    var transport: SwaySharedSessionTransport = .local
    var routineID: String? = nil
    var recordingReference: String? = nil
    var participants: [SwaySharedParticipant] = []
    var createdAt: Date = Date()

    var participantCount: Int { participants.count }
    var consumerCapacityReached: Bool {
        if let limit=tier.includedParticipantLimit { return participantCount >= limit }; return false
    }
}

struct SwaySharedSessionEvent: Codable, Equatable {
    var sessionID: UUID
    var sequence: UInt64
    var timestamp: TimeInterval
    var snapshot: SwaySessionSnapshot
}

protocol SwaySharedSessionEntitlementResolving {
    var hasMasterHostEntitlement: Bool { get }
    func mayHost(participantCount: Int) -> Bool
}

struct SwayPrivateSharedSessionEntitlementResolver: SwaySharedSessionEntitlementResolving {
    // Private/testing builds exercise Master flows without StoreKit.
    // Public distribution replaces this with verified StoreKit subscription entitlement.
    var hasMasterHostEntitlement: Bool = true
    func mayHost(participantCount: Int) -> Bool {
        participantCount <= 2 || hasMasterHostEntitlement
    }
}

// MARK: - Full 0.4 music / scoring models
struct SwayResolvedRecording: Codable {
    var identity:SwayRecordingIdentity
    var confidence:Double
    var source:SwayAnalysisSource
}

struct SwayBeatGrid: Codable {
    var bpm:Double
    var beats:[TimeInterval]
    var downbeats:[TimeInterval]
    var phraseStarts:[TimeInterval]
    var confidence:Double
}

struct SwayReferencePose: Codable {
    var moveID:String
    var count:Int
    var jointAngles:[String:Double]
}

struct SwayPoseScore: Codable {
    var state:SwayMatchState
    var timing:Double
    var shape:Double
    var direction:Double
    var range:Double
    var continuity:Double
    var confidence:Double
    var total:Double
}


// MARK: - Style-aware content packs, sharing & future distribution entitlements

enum SwayDanceStyle: String, Codable, CaseIterable, Identifiable {
    case starter="Starter", hipHop="Hip-Hop", amapiano="Amapiano", house="House",
         disco="Disco", afro="Afro / Afrobeats", latin="Latin", salsa="Salsa",
         bachata="Bachata", reggaeton="Reggaeton", dancehall="Dancehall",
         kpop="K-Pop", jazz="Jazz", contemporary="Contemporary",
         balletFitness="Ballet-inspired Fitness", street="Street", shuffle="Shuffle",
         ballroom="Ballroom", lineDance="Line Dance", bellyDance="Belly Dance",
         poleFitness="Pole Dance / Pole Fitness", chairDance="Chair Dance",
         lowImpact="Low Impact", party="Party", freestyle="Freestyle"
    var id:String { rawValue }
}

enum SwayDanceMode: String, Codable, CaseIterable, Identifiable {
    case learn="Learn", choreography="Follow Choreography", freestyle="Freestyle",
         fitness="Fitness", challenge="Challenge", adaptive="Adaptive", styleRemix="Style Remix"
    var id:String { rawValue }
}

enum SwayPackEntitlement: String, Codable, CaseIterable {
    case free="FREE", included="INCLUDED", iap="IAP", creator="CREATOR",
         privatePack="PRIVATE", test="TEST"
}

struct SwayEquipmentRequirement: Codable, Hashable {
    var id:String
    var name:String
    var required:Bool
    var safetyNote:String?
}

struct SwayPackManifest: Codable, Identifiable {
    var id:String
    var name:String
    var version:String
    var creator:String
    var primaryStyle:SwayDanceStyle
    var styles:[SwayDanceStyle]
    var modes:[SwayDanceMode]
    var entitlement:SwayPackEntitlement
    var futureStoreProductID:String?
    var redistributable:Bool
    var minimumFitnessLevel:Int
    var minimumDanceLevel:Int
    var equipment:[SwayEquipmentRequirement]
    var moveIDs:[String]
    var recordingReferences:[SwayRecordingIdentity]
    var accessibilityTags:[String]
    var provenance:String
}

struct SwayContentPack: Codable, Identifiable {
    var id:String { manifest.id }
    var manifest:SwayPackManifest
    var moves:[DanceMove]
    var routines:[SwayPackage]
}

struct SwayPackLibraryState: Codable {
    var installedPackIDs:Set<String>=[]
    var selectedStyle:SwayDanceStyle?=nil
    var selectedMode:SwayDanceMode = .choreography
}

// Distribution policy is deliberately separate from content.
// Private/experimental builds unlock test content; public builds can later
// replace this resolver with StoreKit-backed entitlement verification.
protocol SwayPackEntitlementResolving {
    func isUnlocked(_ manifest:SwayPackManifest)->Bool
}
struct SwayPrivatePackEntitlementResolver:SwayPackEntitlementResolving {
    func isUnlocked(_ manifest:SwayPackManifest)->Bool { true }
}


// MARK: - Workout lifecycle, scoring stream and route recovery
enum SwayWorkoutLifecycleState:String,Codable { case prepared,countdown,active,paused,cooldown,finished }
struct SwayWorkoutSummary:Codable,Identifiable {
    var id=UUID(); var startedAt=Date(); var endedAt:Date?; var activeSeconds:TimeInterval=0
    var averageScore:Double=0; var validSamples:Int=0; var unknownSamples:Int=0
}
struct SwayLatencyProfile:Codable {
    var audioOutputSeconds:Double=0
    var cameraSeconds:Double=0
    var displaySeconds:Double=0
}
