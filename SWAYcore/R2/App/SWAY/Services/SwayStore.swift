import Foundation
import SwiftUI
import UIKit
import SWAYcoreEngine

@MainActor final class SwayRecoveryNotices: ObservableObject {
    static let shared = SwayRecoveryNotices()
    @Published var message: String?
    private init() {}
    func recovered(_ name: String, backupURL: URL) {
        message = "SWAY recovered \(name) defaults. Your unreadable file was preserved as \(backupURL.lastPathComponent)."
    }
}

@MainActor final class SwayStore: ObservableObject {
    @Published var moves: [DanceMove] = SwayStore.coreMoves
    @Published var transitions: [Transition] = SwayStore.coreTransitions
    @Published var learned: Set<String> = ["march","step-touch","hip-sway","heel-dig"]
    @Published var sessionsCompleted = 0
    @Published var totalMinutes = 0
    @Published var lowImpact = false
    @Published var smallSpace = true
    @Published var mirrored = true
    @Published var intensity = 2
    @Published var cameraTrackingEnabled = false
    @Published var showCameraFeed = false
    @Published var onboardingComplete = false
    @Published var moveComplexity = 1 // 1 Simple ... 5 Expert; property of choreography, never the person
    @Published var visualCueStrength = 2 // 0 Off, 1 Minimal, 2 Standard, 3 Strong
    @Published var automaticStyleThemes = true
    @Published var showWorkoutCounts = true
    @Published var showNextMove = true
    @Published var showCombo = true
    @Published var showCoachMessages = true
    @Published var showYouOverlay = true
    @Published var coachProfileID = "lucia"
    @Published var character = SwayCharacterProfile()
    @Published var unlockedAwards: Set<SwayAwardID> = []
    @Published var profile = SwayUserProfile()
    @Published var sessionResults:[SwaySessionResult] = []
    @Published var creations:[SwayCreation] = []
    @Published var pendingImport:SwayPackage? = nil
    @Published var importMessage:String? = nil

    private let saveURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("sway-state.json")

    init() { load() }

    func generate(minutes: Int, difficulty: Int, lowImpact: Bool, smallSpace: Bool) -> [WorkoutStep] {
        // Simple is an authored welcoming progression, not a label applied to the dancer.
        if difficulty <= 1 {
            let ids=["march","march","step-touch","step-touch","hip-sway","hip-sway","arm-reach","march"]
            let target=max(8,min(60,minutes*2))
            let sequence=ids.compactMap { id in moves.first(where:{$0.id==id}).map { WorkoutStep(move:$0,counts:8) } }
            return (0..<target).map { sequence[$0 % sequence.count] }
        }
        var pool = moves.filter { $0.difficulty <= difficulty && (!lowImpact || $0.impact <= 2) && (!smallSpace || $0.space <= 1) }
        if pool.isEmpty { pool = Array(moves.prefix(4)) }
        let target = max(8, min(60, minutes * 2))
        var result: [WorkoutStep] = []
        var current = pool.first!
        for _ in 0..<target {
            result.append(WorkoutStep(move: current, counts: current.counts))
            let candidates = pool.sorted { transitionQuality(from: current.id, to: $0.id) > transitionQuality(from: current.id, to: $1.id) }
            let familiar = candidates.filter { learned.contains($0.id) }
            // Bias toward familiar material, while introducing learnable moves.
            current = (Int.random(in: 0..<10) < 8 ? familiar.randomElement() : candidates.randomElement()) ?? pool.randomElement()!
        }
        return result
    }

    func transitionQuality(from: String, to: String) -> Int {
        transitions.first(where: {$0.from == from && $0.to == to})?.quality ?? (from == to ? 5 : 3)
    }

    func addMove(name: String, style: String, difficulty: Int, basedOn baseMoveID: String = "step-touch") {
        // Alpha authoring keeps every user-created Move executable: it remixes an
        // authored movement definition instead of creating metadata with no pose data.
        var move = moves.first(where: { $0.id == baseMoveID && SwayCoachPoseEngine.supports(moveID:$0.id) })
            ?? moves.first(where: { SwayCoachPoseEngine.supports(moveID:$0.id) })
            ?? DanceMove(id:"step-touch",name:"Step Touch",difficulty:1,impact:1,bpmMin:80,bpmMax:140,space:1,style:"Pop")
        let executableBase=SwayCoachPoseEngine.canonicalMoveID(baseMoveID)
        move.id = "user.\(executableBase).\(UUID().uuidString.prefix(8))"
        move.name = name
        move.style = style
        move.difficulty = difficulty
        move.provenance = "My Move · based on \(baseMoveID)"
        moves.append(move)
        save()
    }

    func addCreation(name:String, kind:SwayCreation.Kind, moveIDs:[String]) {
        let clean=name.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !clean.isEmpty, !moveIDs.isEmpty else { return }
        creations.append(.init(name:clean,kind:kind,moveIDs:moveIDs)); save()
    }

    func duplicate(_ move: DanceMove) {
        var copy = move
        copy.id = "user.remix.\(UUID().uuidString.prefix(8))"
        copy.name += " Remix"
        copy.provenance = "Remix of \(move.provenance)"
        moves.append(copy); save()
    }

    @discardableResult
    func complete(minutes:Int,activeSeconds:TimeInterval,steps:[WorkoutStep],averageScore:Double = 0,maxCombo:Int = 0)->SwaySessionResult? {
        // A workout is complete only after meaningful participation: at least 60 s and 80% of plan.
        let plannedSeconds=Double(minutes*60)
        let completed=activeSeconds >= 60 && activeSeconds >= plannedSeconds*0.80
        guard completed else { return nil }
        let before=unlockedAwards
        sessionsCompleted += 1
        totalMinutes += max(1,Int(activeSeconds/60.0))
        steps.forEach { learned.insert($0.move.id) }
        evaluateAwards()
        let newlyUnlocked=Array(unlockedAwards.subtracting(before))
        let style=steps.first?.move.style ?? "Dance"
        let result=SwaySessionResult(durationMinutes:max(1,Int(activeSeconds/60.0)),style:style,moveIDs:steps.map{$0.move.id},
            averageScore:averageScore,maxCombo:maxCombo,achievements:newlyUnlocked)
        sessionResults.append(result)
        if sessionResults.count > 250 { sessionResults.removeFirst(sessionResults.count-250) }
        save()
        return result
    }

    static let awards: [SwayAward] = [
        .init(id:.firstDance,title:"First Dance",detail:"Complete your first SWAY session.",symbol:"figure.dance"),
        .init(id:.fiveDances,title:"Finding Your Groove",detail:"Complete 5 dance sessions.",symbol:"5.circle.fill"),
        .init(id:.tenDances,title:"Ten Dances",detail:"Complete 10 dance sessions.",symbol:"10.circle.fill"),
        .init(id:.sixtyMinutes,title:"One Hour of SWAY",detail:"Dance for 60 minutes in total.",symbol:"clock.fill"),
        .init(id:.firstMoveMastered,title:"Move Collector",detail:"Learn your first move.",symbol:"sparkles"),
        .init(id:.fiveMovesMastered,title:"Move Explorer",detail:"Learn 5 moves.",symbol:"square.grid.2x2.fill"),
        .init(id:.flowEight,title:"FLOW ×8",detail:"Keep an eight-count combo moving.",symbol:"waveform.path"),
        .init(id:.flowSixteen,title:"FLOW",detail:"Reach a sixteen-count flow.",symbol:"bolt.heart.fill"),
        .init(id:.firstSwayBeats,title:"Beat Dancer",detail:"Dance with SWAY Beats.",symbol:"metronome.fill"),
        .init(id:.explorer,title:"Explorer",detail:"Try different ways to dance.",symbol:"safari.fill"),
        .init(id:.keptMoving,title:"Kept Moving",detail:"Stayed active even when the choreography got tricky.",symbol:"figure.walk.motion"),
        .init(id:.comeback,title:"Comeback",detail:"Found the rhythm again after a difficult section.",symbol:"arrow.uturn.up.circle.fill"),
        .init(id:.inTheGroove,title:"In the Groove",detail:"Sustained movement and rhythm.",symbol:"waveform.path.ecg"),
        .init(id:.strongFinish,title:"Strong Finish",detail:"Kept moving through the final section.",symbol:"flag.checkered"),
        .init(id:.fullEnergy,title:"Full Energy",detail:"Brought strong observable movement to the dance.",symbol:"bolt.heart.fill"),
        .init(id:.recoverySmart,title:"Recovery Counts",detail:"Took a recovery break and came back ready.",symbol:"drop.fill")
    ]

    func unlock(_ award: SwayAwardID) {
        if unlockedAwards.insert(award).inserted { haptic(.medium); save() }
    }

    func evaluateAwards() {
        if sessionsCompleted >= 1 { unlockedAwards.insert(.firstDance) }
        if sessionsCompleted >= 5 { unlockedAwards.insert(.fiveDances) }
        if sessionsCompleted >= 10 { unlockedAwards.insert(.tenDances) }
        if totalMinutes >= 60 { unlockedAwards.insert(.sixtyMinutes) }
        if learned.count >= 1 { unlockedAwards.insert(.firstMoveMastered) }
        if learned.count >= 5 { unlockedAwards.insert(.fiveMovesMastered) }
    }

    func exportPackage() throws -> URL {
        let package = SwayPackage(creator: profile.nickname.isEmpty ? "Private User" : profile.nickname, moves: moves.filter{$0.provenance != "SWAY Official"}, transitions: transitions, metadata: SwayPackageMetadata(title: "My SWAY Moves", origin: .userCreated, kind: .mixed, creatorDisplayName: profile.nickname.isEmpty ? nil : profile.nickname), creations: creations)
        let data = try JSONEncoder.pretty.encode(package)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyMoves.swaypack")
        try data.write(to: url); return url
    }

    func prepareImport(from url:URL) throws {
        let data=try Data(contentsOf:url)
        let package=try JSONDecoder().decode(SwayPackage.self,from:data)
        try package.validate()
        pendingImport=package
    }

    func commitPendingImport() {
        guard let package=pendingImport else{return}
        for move in package.moves where !moves.contains(where: {$0.id == move.id}) { moves.append(move) }
        transitions.append(contentsOf: package.transitions.filter { !transitions.contains($0) })
        for item in package.creations ?? [] where !creations.contains(where:{$0.id == item.id}) { creations.append(item) }
        pendingImport=nil; importMessage="Added SWAY content to your library"; save()
    }

    func importPackage(from url: URL) throws { try prepareImport(from:url); commitPendingImport() }

    func exportBackup() throws -> URL {
        save()
        let data=try Data(contentsOf:saveURL)
        let safe=(profile.nickname.isEmpty ? "My" : profile.nickname).replacingOccurrences(of:"/",with:"-")
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("\(safe)-SWAY.swaybackup")
        try data.write(to:url,options:.atomic)
        return url
    }

    func restoreBackup(from url:URL) throws {
        let data=try Data(contentsOf:url)
        _=try JSONDecoder().decode(State.self,from:data)
        try FileManager.default.createDirectory(at:saveURL.deletingLastPathComponent(),withIntermediateDirectories:true)
        try data.write(to:saveURL,options:.atomic)
        load()
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) { UIImpactFeedbackGenerator(style: style).impactOccurred() }

    private struct State: Codable {
        var custom:[DanceMove]; var learned:Set<String>; var sessions:Int; var minutes:Int
        var character:SwayCharacterProfile? = nil
        var awards:Set<SwayAwardID>? = nil
        var profile:SwayUserProfile? = nil
        var results:[SwaySessionResult]? = nil
        var creations:[SwayCreation]? = nil
        var lowImpact:Bool? = nil; var smallSpace:Bool? = nil; var mirrored:Bool? = nil
        var intensity:Int? = nil; var cameraTrackingEnabled:Bool? = nil; var showCameraFeed:Bool? = nil
        var onboardingComplete:Bool? = nil; var moveComplexity:Int? = nil; var visualCueStrength:Int? = nil; var automaticStyleThemes:Bool? = nil
        var showWorkoutCounts:Bool?=nil; var showNextMove:Bool?=nil; var showCombo:Bool?=nil; var showCoachMessages:Bool?=nil; var showYouOverlay:Bool?=nil; var coachProfileID:String?=nil
    }
    func save() {
        try? FileManager.default.createDirectory(at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = State(custom:moves.filter{$0.provenance != "SWAY Official"}, learned:learned, sessions:sessionsCompleted, minutes:totalMinutes, character:character, awards:unlockedAwards, profile:profile, results:sessionResults, creations:creations, lowImpact:lowImpact, smallSpace:smallSpace, mirrored:mirrored, intensity:intensity, cameraTrackingEnabled:cameraTrackingEnabled, showCameraFeed:showCameraFeed, onboardingComplete:onboardingComplete, moveComplexity:moveComplexity, visualCueStrength:visualCueStrength, automaticStyleThemes:automaticStyleThemes, showWorkoutCounts:showWorkoutCounts, showNextMove:showNextMove, showCombo:showCombo, showCoachMessages:showCoachMessages, showYouOverlay:showYouOverlay, coachProfileID:coachProfileID)
        try? JSONEncoder.pretty.encode(state).write(to: saveURL)
    }
    private func load() {
        let state: State
        switch SwayCorruptSaveRecovery.load(State.self, from: saveURL) {
        case .missing: return
        case .loaded(let loaded): state = loaded
        case .corrupt(let backup): SwayRecoveryNotices.shared.recovered("profile, character, library and settings", backupURL: backup); return
        }
        moves += state.custom.filter { c in !moves.contains(where: {$0.id == c.id}) }; learned=state.learned; sessionsCompleted=state.sessions; totalMinutes=state.minutes
        if let savedCharacter=state.character { character=savedCharacter }
        if let awards=state.awards { unlockedAwards=awards }
        if let savedProfile=state.profile { profile=savedProfile }
        if let results=state.results { sessionResults=results }
        if let savedCreations=state.creations { creations=savedCreations }
        if let v=state.lowImpact { lowImpact=v }; if let v=state.smallSpace { smallSpace=v }
        if let v=state.mirrored { mirrored=v }; if let v=state.intensity { intensity=v }
        if let v=state.cameraTrackingEnabled { cameraTrackingEnabled=v }; if let v=state.showCameraFeed { showCameraFeed=v }
        if let v=state.onboardingComplete { onboardingComplete=v }; if let v=state.moveComplexity { moveComplexity=v }
        if let v=state.visualCueStrength { visualCueStrength=v }; if let v=state.automaticStyleThemes { automaticStyleThemes=v }
        if let v=state.showWorkoutCounts { showWorkoutCounts=v }; if let v=state.showNextMove { showNextMove=v }; if let v=state.showCombo { showCombo=v }; if let v=state.showCoachMessages { showCoachMessages=v }; if let v=state.showYouOverlay { showYouOverlay=v }; if let v=state.coachProfileID { coachProfileID=v }
        evaluateAwards()
    }

    func resetProgress() {
        learned=[]
        sessionsCompleted=0
        totalMinutes=0
        unlockedAwards=[]
        sessionResults=[]
        save()
    }

    static let coreMoves:[DanceMove] = [
        .init(id:"march", name:"March", difficulty:1, impact:1, bpmMin:80, bpmMax:150, space:1, style:"Foundation", harderID:"knee"),
        .init(id:"step-touch", name:"Step Touch", difficulty:1, impact:1, bpmMin:85, bpmMax:140, space:1, style:"Foundation", harderID:"double-step"),
        .init(id:"hip-sway", name:"Hip Sway", difficulty:1, impact:1, bpmMin:70, bpmMax:125, space:1, style:"Groove"),
        .init(id:"heel-dig", name:"Heel Dig", difficulty:1, impact:1, bpmMin:85, bpmMax:135, space:1, style:"Retro"),
        .init(id:"knee", name:"Knee Lift", difficulty:2, impact:2, bpmMin:90, bpmMax:145, space:1, style:"Cardio", easierID:"march"),
        .init(id:"double-step", name:"Double Step", difficulty:2, impact:2, bpmMin:90, bpmMax:140, space:2, style:"Pop", easierID:"step-touch", harderID:"grapevine"),
        .init(id:"grapevine", name:"Grapevine", difficulty:3, impact:2, bpmMin:95, bpmMax:135, space:2, style:"Dance", easierID:"double-step"),
        .init(id:"arm-reach", name:"Arm Reach", difficulty:1, impact:1, bpmMin:70, bpmMax:150, space:1, style:"Foundation"),
        .init(id:"v-step", name:"V-Step", difficulty:2, impact:1, bpmMin:90, bpmMax:135, space:1, style:"Cardio"),
        .init(id:"side-tap", name:"Side Tap", difficulty:1, impact:1, bpmMin:80, bpmMax:145, space:1, style:"Foundation"),
        .init(id:"box-step", name:"Box Step", difficulty:2, impact:1, bpmMin:85, bpmMax:130, space:1, style:"Dance"),
        .init(id:"mambo", name:"Mambo Step", difficulty:2, impact:1, bpmMin:90, bpmMax:135, space:1, style:"Latin"),
        .init(id:"cha-cha", name:"Cha-Cha Basic", difficulty:2, impact:1, bpmMin:95, bpmMax:135, space:1, style:"Latin"),
        .init(id:"squat-pulse", name:"Squat Pulse", difficulty:2, impact:2, bpmMin:80, bpmMax:125, space:1, style:"Strength"),
        .init(id:"side-lunge", name:"Side Lunge", difficulty:2, impact:2, bpmMin:75, bpmMax:120, space:2, style:"Strength"),
        .init(id:"cross-step", name:"Cross Step", difficulty:2, impact:1, bpmMin:90, bpmMax:140, space:2, style:"Dance"),
        .init(id:"body-roll", name:"Body Roll", difficulty:3, impact:1, bpmMin:70, bpmMax:115, space:1, style:"Groove"),
        .init(id:"jumping-jack", name:"Dance Jack", difficulty:3, impact:3, bpmMin:100, bpmMax:155, space:2, style:"Cardio", accessibilityVariantID:"step-touch"),
        .init(id:"skater", name:"Skater", difficulty:3, impact:3, bpmMin:100, bpmMax:150, space:2, style:"Cardio", accessibilityVariantID:"side-tap"),
        .init(id:"pivot-turn", name:"Pivot Turn", difficulty:3, impact:2, bpmMin:90, bpmMax:135, space:1, style:"Dance"),
        .init(id:"kick-ball-change", name:"Kick-Ball-Change", difficulty:4, impact:2, bpmMin:100, bpmMax:145, space:1, style:"Dance", easierID:"heel-dig"),
        .init(id:"salsa-basic", name:"Salsa Basic", difficulty:4, impact:2, bpmMin:95, bpmMax:135, space:2, style:"Latin", easierID:"mambo"),
        .init(id:"jazz-square", name:"Jazz Square", difficulty:4, impact:2, bpmMin:95, bpmMax:140, space:2, style:"Dance", easierID:"box-step"),
        .init(id:"power-knee", name:"Power Knee", difficulty:4, impact:3, bpmMin:105, bpmMax:155, space:1, style:"Cardio", easierID:"knee", accessibilityVariantID:"knee"),
        .init(id:"lateral-hop", name:"Lateral Hop", difficulty:5, impact:4, bpmMin:110, bpmMax:160, space:2, style:"Cardio", easierID:"skater", accessibilityVariantID:"side-tap"),
        .init(id:"turning-grapevine", name:"Turning Grapevine", difficulty:5, impact:3, bpmMin:100, bpmMax:145, space:2, style:"Dance", easierID:"grapevine", accessibilityVariantID:"grapevine")
    ]
    static let coreTransitions:[Transition] = [
        .init(from:"march",to:"step-touch",quality:5), .init(from:"step-touch",to:"hip-sway",quality:5),
        .init(from:"hip-sway",to:"side-tap",quality:5), .init(from:"side-tap",to:"knee",quality:4),
        .init(from:"step-touch",to:"double-step",quality:5), .init(from:"double-step",to:"grapevine",quality:5),
        .init(from:"knee",to:"march",quality:5), .init(from:"v-step",to:"march",quality:4),
        .init(from:"grapevine",to:"turning-grapevine",quality:5), .init(from:"mambo",to:"salsa-basic",quality:5),
        .init(from:"box-step",to:"jazz-square",quality:5), .init(from:"knee",to:"power-knee",quality:5),
        .init(from:"skater",to:"lateral-hop",quality:4), .init(from:"heel-dig",to:"kick-ball-change",quality:5)
    ]
}

extension JSONEncoder { static var pretty: JSONEncoder { let e=JSONEncoder(); e.outputFormatting=[.prettyPrinted,.sortedKeys]; return e } }


// MARK: - Analysis-only music persistence
@MainActor
final class SwayMusicDataStore: ObservableObject {
    @Published var playlists: [SwayPlaylist] = []
    @Published var analyses: [SwayTrackAnalysis] = []
    @Published var mix = SwayAudioMix()
    @Published var beatConfiguration = SwayBeatConfiguration()

    private let url: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("sway-music-data.json")
        load()
    }

    private struct Snapshot: Codable {
        var playlists: [SwayPlaylist]
        var analyses: [SwayTrackAnalysis]
        var mix: SwayAudioMix
        var beatConfiguration: SwayBeatConfiguration
    }

    func save() {
        let snapshot = Snapshot(playlists: playlists, analyses: analyses, mix: mix, beatConfiguration: beatConfiguration)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func load() {
        let snapshot: Snapshot
        switch SwayCorruptSaveRecovery.load(Snapshot.self, from: url) {
        case .missing: return
        case .loaded(let loaded): snapshot = loaded
        case .corrupt(let backup): SwayRecoveryNotices.shared.recovered("music library", backupURL: backup); return
        }
        playlists = snapshot.playlists
        analyses = snapshot.analyses
        mix = snapshot.mix
        beatConfiguration = snapshot.beatConfiguration
    }

    func analysis(for recording: SwayRecordingIdentity) -> SwayTrackAnalysis? {
        analyses.first {
            if let a = $0.recording.isrc, let b = recording.isrc, a == b { return true }
            if let a = $0.recording.musicBrainzRecordingID, let b = recording.musicBrainzRecordingID, a == b { return true }
            return !$0.recording.providerIDs.isEmpty &&
                !$0.recording.providerIDs.filter { recording.providerIDs[$0.key] == $0.value }.isEmpty
        }
    }
}

extension SwayMusicDataStore {
    func upsert(_ analysis:SwayTrackAnalysis) {
        if let i=analyses.firstIndex(where:{$0.recording.id == analysis.recording.id}) { analyses[i]=analysis }
        else { analyses.append(analysis) }
        save()
    }
    func createPlaylist(name:String)->SwayPlaylist {
        let p=SwayPlaylist(name:name); playlists.append(p); save(); return p
    }
    func add(_ recording:SwayRecordingIdentity,to playlistID:UUID,choreographyID:String?=nil) {
        guard let i=playlists.firstIndex(where:{$0.id==playlistID}) else{return}
        playlists[i].entries.append(.init(recording:recording,choreographyID:choreographyID)); save()
    }
}


@MainActor
final class SwayPackStore:ObservableObject {
    @Published var installed:[SwayContentPack]=[]
    @Published var state=SwayPackLibraryState()
    private let entitlement:SwayPackEntitlementResolving=SwayPrivatePackEntitlementResolver()
    private var stateURL:URL {
        let dir=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
        try? FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        return dir.appendingPathComponent("sway-packs.json")
    }

    init(){ load(); installBuiltInsIfNeeded() }

    var available:[SwayContentPack] { installed.filter{entitlement.isUnlocked($0.manifest)} }

    func install(_ pack:SwayContentPack) throws {
        guard !pack.manifest.id.isEmpty,!pack.manifest.version.isEmpty else {
            throw NSError(domain:"SWAYPack",code:1,userInfo:[NSLocalizedDescriptionKey:"Invalid pack manifest"])
        }
        if let i=installed.firstIndex(where:{$0.id==pack.id}) {
            installed[i]=pack
        } else { installed.append(pack) }
        state.installedPackIDs.insert(pack.id); save()
    }

    func importPack(from url:URL) throws {
        let access=url.startAccessingSecurityScopedResource()
        defer{if access{url.stopAccessingSecurityScopedResource()}}
        let data=try Data(contentsOf:url)
        try install(JSONDecoder().decode(SwayContentPack.self,from:data))
    }

    func exportURL(for pack:SwayContentPack) throws -> URL {
        guard pack.manifest.redistributable else {
            throw NSError(domain:"SWAYPack",code:2,userInfo:[NSLocalizedDescriptionKey:"This pack is not redistributable."])
        }
        let safe=pack.manifest.name.replacingOccurrences(of:" ",with:"_")
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("\(safe).swaypack")
        let enc=JSONEncoder(); enc.outputFormatting=[.prettyPrinted,.sortedKeys]
        try enc.encode(pack).write(to:url,options:.atomic); return url
    }

    func save(){
        let enc=JSONEncoder()
        if let data=try? enc.encode(Persisted(installed:installed,state:state)){try? data.write(to:stateURL,options:.atomic)}
    }
    func load(){
        let x:Persisted
        switch SwayCorruptSaveRecovery.load(Persisted.self,from:stateURL) {
        case .missing:return
        case .loaded(let loaded):x=loaded
        case .corrupt(let backup):SwayRecoveryNotices.shared.recovered("content library",backupURL:backup);return
        }
        installed=x.installed; state=x.state
    }
    private struct Persisted:Codable { var installed:[SwayContentPack]; var state:SwayPackLibraryState }

    private func installBuiltInsIfNeeded(){
        for p in Self.testingPacks where !installed.contains(where:{$0.id==p.id}) { try? install(p) }
    }

    static var testingPacks:[SwayContentPack] {
        func pack(_ id:String,_ name:String,_ style:SwayDanceStyle,_ modes:[SwayDanceMode],
                  equipment:[SwayEquipmentRequirement]=[])->SwayContentPack {
            .init(manifest:.init(id:id,name:name,version:"0.1-test",creator:"SWAY",
                primaryStyle:style,styles:[style],modes:modes,entitlement:.test,
                futureStoreProductID:"com.sway.pack.\(id)",redistributable:true,
                minimumFitnessLevel:1,minimumDanceLevel:1,equipment:equipment,
                moveIDs:[],recordingReferences:[],
                accessibilityTags:["adaptive","reduced-range","slower-footwork"],
                provenance:"SWAY Private Test Pack"),moves:[],routines:[])
        }
        return [
            pack("starter","SWAY Starter",.starter,[.learn,.choreography,.fitness,.adaptive]),
            pack("hiphop","Hip-Hop Lab",.hipHop,[.learn,.choreography,.freestyle,.challenge,.adaptive]),
            pack("amapiano","Amapiano Lab",.amapiano,[.learn,.choreography,.freestyle,.fitness]),
            pack("latin","Latin Lab",.latin,[.learn,.choreography,.fitness,.styleRemix]),
            pack("pole","Pole Fitness Lab",.poleFitness,[.learn,.choreography,.fitness,.adaptive],
                 equipment:[.init(id:"pole",name:"Secure dance/fitness pole",required:true,
                    safetyNote:"Use only a correctly installed pole and choreography appropriate to your experience.")]),
            pack("lowimpact","Low Impact",.lowImpact,[.learn,.fitness,.adaptive]),
            pack("party","Party",.party,[.choreography,.freestyle,.challenge])
        ]
    }
}
