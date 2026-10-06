import SwiftUI
import RealityKit
import UIKit
import SWAYcoreEngine

// SWAY-FINAL-AVATAR-001: workout/choreography owns WHAT + WHEN; renderer owns HOW.
struct SWAYAvatarDiagnostics: Sendable {
    var renderer: String
    var characterID: String
    var assetLoaded: Bool
    var animationName: String?
    var message: String?
}

struct SWAYAvatarMoveBinding: Codable, Hashable {
    let resource: String
    let beatsPerCycle: Double
    let loop: Bool
}

struct SWAYAvatarCharacterManifest: Codable {
    let characterID: String
    let version: Int
    let renderer: String
    let assetBaseName: String
    let skeletonContract: String
    let rootJoint: String
    let hipsJoint: String
    let authoredBPM: Double
    let animations: [String: SWAYAvatarMoveBinding]
    /// Only accepted production assets may enter the RealityKit consumer route.
    let runtimeApproved: Bool?

    /// Older v2 family assets use a different joint vocabulary; never relabel them as R2.
    func validateContract() throws {
        guard skeletonContract == "SWAYHumanoid-v1", rootJoint == "Root", hipsJoint == "Hips" else {
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[NSLocalizedDescriptionKey:"Character rig requires reconciliation with the R2 humanoid contract."])
        }
    }
}

enum SWAYAvatarResourceLocator {
    static func url(_ resource:String, characterID:String, animation:Bool=false, bundle:Bundle = .main)->URL? {
        let folder = characterID == "user" ? "Characters/UserAvatar" : "Characters/Lucia"
        let directories:[String?] = animation ? [folder+"/Animations",folder,nil] : [folder,nil]
        for directory in directories {
            for fileExtension in ["usdc","usdz","usd","usda","reality"] {
                if let url=bundle.url(forResource:resource,withExtension:fileExtension,subdirectory:directory) { return url }
            }
        }
        return nil
    }
}

@MainActor
protocol SWAYAvatarRendering: AnyObject {
    func load(character: SWAYAvatarCharacterManifest) async throws
    func prepare() async throws
    func showIdle()
    func play(moveID: String, transition: TimeInterval)
    func seek(toMusicalTime time: TimeInterval, bpm: Double)
    func setPlaybackRate(_ rate: Float)
    func setMirrored(_ mirrored: Bool)
    func pause()
    func resume()
    func unload()
    var diagnostics: SWAYAvatarDiagnostics { get }
}

enum SWAYAvatarManifestLoader {
    static func realityCharacter(_ id:String="lucia") throws -> SWAYAvatarCharacterManifest {
        let resource = id == "user" ? "user.character" : "lucia.character"
        let folder = id == "user" ? "Characters/UserAvatar" : "Characters/Lucia"
        guard let url=Bundle.main.url(forResource:resource,withExtension:"json",subdirectory:folder) ?? Bundle.main.url(forResource:resource,withExtension:"json") else {
            throw NSError(domain:"SWAYAvatar",code:404,userInfo:[NSLocalizedDescriptionKey:"\(id) Reality character manifest is missing from the app bundle."])
        }
        let manifest = try JSONDecoder().decode(SWAYAvatarCharacterManifest.self,from:Data(contentsOf:url))
        try manifest.validateContract()
        return manifest
    }
}

@MainActor
final class SWAYRealityAvatarRenderer: ObservableObject, SWAYAvatarRendering {
    private(set) var character:SWAYAvatarCharacterManifest?
    private(set) var entity:Entity?
    private var controller:AnimationPlaybackController?
    private var activeMoveID:String?
    private var animationByName:[String:AnimationResource]=[:]
    private var clipEntities:[Entity]=[]
    private var lastMessage:String?
    var diagnostics:SWAYAvatarDiagnostics { .init(renderer:"RealityKit",characterID:character?.characterID ?? "unloaded",assetLoaded:entity != nil,animationName:activeMoveID.flatMap{character?.animations[$0]?.resource},message:lastMessage) }

    func load(character:SWAYAvatarCharacterManifest) async throws {
        try character.validateContract()
        guard character.runtimeApproved == true else {
            throw NSError(domain:"SWAYAvatar",code:403,userInfo:[NSLocalizedDescriptionKey:"Character is awaiting production visual approval."])
        }
        guard let baseURL=SWAYAvatarResourceLocator.url(character.assetBaseName,characterID:character.characterID) else {
            throw NSError(domain:"SWAYAvatar",code:404,userInfo:[NSLocalizedDescriptionKey:"Character base asset is missing from the app bundle."])
        }
        self.character=character
        let loaded=try await Entity(contentsOf:baseURL)
        entity=loaded
        animationByName=[:]
        clipEntities=[]
        for binding in character.animations.values {
            if let url=SWAYAvatarResourceLocator.url(binding.resource,characterID:character.characterID,animation:true),
               let clip = try? await Entity(contentsOf:url), let resource = clip.availableAnimations.first {
                animationByName[binding.resource] = resource
                clipEntities.append(clip)
            }
        }
        // Backward compatibility for authored assets that embed named clips in one container.
        for resource in loaded.availableAnimations { if let name=resource.name { animationByName[name]=resource } }
        let required=Set(character.animations.values.map(\.resource)), available=Set(animationByName.keys)
        let missing=required.subtracting(available)
        guard missing.isEmpty else { throw NSError(domain:"SWAYAvatar",code:422,userInfo:[NSLocalizedDescriptionKey:"Lucia is missing animations: \(missing.sorted().joined(separator:", "))"]) }
        lastMessage=nil
    }
    func prepare() async throws { guard entity != nil else { throw NSError(domain:"SWAYAvatar",code:409,userInfo:[NSLocalizedDescriptionKey:"Character must be loaded before prepare."]) } }
    func showIdle(){ play(moveID:"idle",transition:0.18) }
    func play(moveID:String,transition:TimeInterval){
        guard activeMoveID != moveID, let character, let entity, let binding=character.animations[moveID], let resource=animationByName[binding.resource] else { return }
        controller?.stop(blendOutDuration:min(0.15,transition))
        let playable=binding.loop ? resource.repeat() : resource
        controller=entity.playAnimation(playable,transitionDuration:transition,startsPaused:false)
        activeMoveID=moveID
    }
    func seek(toMusicalTime time:TimeInterval,bpm:Double){
        guard let controller, let character, let move=activeMoveID, let binding=character.animations[move] else{return}
        let cycle=max(0.001,binding.beatsPerCycle*60.0/max(SwayTimelineMath.minimumBPM,bpm))
        let phase=time.truncatingRemainder(dividingBy:cycle)/cycle
        controller.time=phase*controller.duration
        controller.speed=Float(max(0.25,min(4.0,bpm/character.authoredBPM)))
    }
    func setPlaybackRate(_ rate:Float){controller?.speed=rate}
    func setMirrored(_ mirrored:Bool){ guard let entity else{return}; var scale=entity.scale; scale.x=abs(scale.x)*(mirrored ? -1:1); entity.scale=scale }
    func pause(){controller?.pause()}
    func resume(){controller?.resume()}
    func unload(){controller?.stop();controller=nil;entity=nil;clipEntities=[];animationByName=[:];activeMoveID=nil}
}

// Production-stage view. It only activates when the actual rigged Lucia asset exists.
// Until then SWAY explicitly uses the cutout bridge; there is no fake 3D substitute.
struct SWAYRealityAvatarView:View {
    let characterID:String; let moveID:String; let musicalTime:TimeInterval; let bpm:Double; let paused:Bool; let mirrored:Bool
    @StateObject private var renderer=SWAYRealityAvatarRenderer()
    @State private var loadError:String?
    var body:some View {
        RealityView { content in
            do {
                let manifest=try SWAYAvatarManifestLoader.realityCharacter(characterID)
                try await renderer.load(character:manifest); try await renderer.prepare()
                if let entity=renderer.entity { content.add(entity); renderer.play(moveID:moveID,transition:0.16); renderer.seek(toMusicalTime:musicalTime,bpm:bpm); renderer.setMirrored(mirrored); if paused{renderer.pause()} }
            } catch { loadError=error.localizedDescription }
        } update:{ _ in
            renderer.play(moveID:moveID,transition:0.16); renderer.seek(toMusicalTime:musicalTime,bpm:bpm); renderer.setMirrored(mirrored); paused ? renderer.pause():renderer.resume()
        } placeholder:{ ProgressView().tint(.white) }
        .realityViewLayoutBehavior(.centered)
        .overlay(alignment:.bottom){ if let loadError { Text(loadError).font(.caption2).foregroundStyle(.secondary).padding(6).background(.black.opacity(0.5),in:Capsule()).padding(8) } }
    }
}

struct SWAYCutoutPartContract:Codable { let assetName:String; let pixelSize:[Int]; let alphaBounds:[Int]; let pivots:[String:[Double]] }
struct SWAYCutoutManifest:Codable { let characterID:String; let version:Int; let renderer:String; let parts:[String:SWAYCutoutPartContract] }
struct SWAYCutoutValidationIssue:Identifiable { let id=UUID(); let part:String; let message:String }

enum SWAYCutoutAssetValidator {
    static func validateLucia()->[SWAYCutoutValidationIssue] {
        guard let url=Bundle.main.url(forResource:"lucia.cutout.manifest",withExtension:"json",subdirectory:"Characters/Lucia") ?? Bundle.main.url(forResource:"lucia.cutout.manifest",withExtension:"json"),
              let data=try? Data(contentsOf:url), let manifest=try? JSONDecoder().decode(SWAYCutoutManifest.self,from:data) else { return [.init(part:"manifest",message:"Lucia cutout manifest missing or invalid")] }
        var issues:[SWAYCutoutValidationIssue]=[]
        for (name,part) in manifest.parts {
            guard let image=UIImage(named:part.assetName), let cg=image.cgImage else { issues.append(.init(part:name,message:"Missing image \(part.assetName)")); continue }
            if cg.width != part.pixelSize[0] || cg.height != part.pixelSize[1] { issues.append(.init(part:name,message:"Pixel size \(cg.width)x\(cg.height) != manifest \(part.pixelSize[0])x\(part.pixelSize[1])")) }
            for (pivot,xy) in part.pivots where xy.count != 2 || xy.contains(where:{$0 < 0 || $0 > 1}) { issues.append(.init(part:name,message:"Invalid pivot \(pivot)")) }
        }
        return issues
    }
}

struct SWAYAvatarStageView:View {
    enum Role { case coach, user }
    let role:Role; let moveID:String; let elapsed:TimeInterval; let bpm:Double; let paused:Bool; let mirrored:Bool
    let cutout:AnyView
    private var characterID:String { role == .coach ? "lucia" : "user" }
    private var realityMoveID:String? {
        guard let manifest = try? SWAYAvatarManifestLoader.realityCharacter(characterID),
              manifest.runtimeApproved == true,
              SWAYAvatarResourceLocator.url(manifest.assetBaseName,characterID:characterID) != nil else { return nil }
        let canonical = SwayCoachPoseEngine.canonicalMoveID(moveID)
        return manifest.animations[canonical] == nil ? nil : canonical
    }
    var body:some View {
        Group {
            if let realityMoveID {
                SWAYRealityAvatarView(characterID:characterID,moveID:realityMoveID,musicalTime:elapsed,bpm:bpm,paused:paused,mirrored:mirrored)
            } else {
                // Never expose the engineering primitive mannequin to users.
                // Missing authored Reality assets fall back to the established illustrated rig.
                cutout
            }
        }
    }
}

/// Shared consumer COACH route: an accepted RealityKit rig when available,
/// otherwise Lucia's existing authored illustrated pose atlas.
struct SWAYCoachAvatarView:View {
    let moveID:String
    let musicalTime:TimeInterval
    let bpm:Double
    let paused:Bool
    let mirrored:Bool

    var body:some View {
        SWAYAvatarStageView(role:.coach,moveID:moveID,elapsed:musicalTime,bpm:bpm,paused:paused,mirrored:mirrored,
            cutout:AnyView(SWAYSkeletal2DAvatarView(role:.coach,moveID:moveID,musicalTime:musicalTime,bpm:bpm,paused:paused,mirrored:mirrored)))
    }
}
