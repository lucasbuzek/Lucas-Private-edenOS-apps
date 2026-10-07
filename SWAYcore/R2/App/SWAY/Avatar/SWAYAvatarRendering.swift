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
    static func folder(for characterID:String)->String? {
        SWAYCharacterRegistry.character(id: characterID)?.resourceFolder
    }
    static func url(_ resource:String, characterID:String, animation:Bool=false, bundle:Bundle = .main)->URL? {
        guard let folder = folder(for: characterID) else { return nil }
        let directories:[String?] = animation ? [folder+"/Animations",folder,nil] : [folder,nil]
        for directory in directories {
            for fileExtension in ["usdc","usdz","usd","usda","reality"] {
                if let url=bundle.url(forResource:resource,withExtension:fileExtension,subdirectory:directory) { return url }
            }
        }
        return nil
    }
}

struct SWAYCharacterRegistration: Hashable, Sendable {
    let id:String
    let displayName:String
    let resourceFolder:String
    let manifestResource:String
    let rigContract:String
}

/// The single consumer registry for every production dancer. All six entries use the
/// same articulated 23-joint contract; character choice changes art, never choreography.
enum SWAYCharacterRegistry {
    static let all:[SWAYCharacterRegistration] = [
        .init(id:"lucia",displayName:"Lucia",resourceFolder:"Characters/Lucia",manifestResource:"lucia.character",rigContract:"SWAYHumanoid-v1"),
        .init(id:"nandi",displayName:"Nandi",resourceFolder:"Characters/Nandi",manifestResource:"nandi.character",rigContract:"SWAYHumanoid-v1"),
        .init(id:"thabo",displayName:"Thabo",resourceFolder:"Characters/Thabo",manifestResource:"thabo.character",rigContract:"SWAYHumanoid-v1"),
        .init(id:"zuri",displayName:"Zuri",resourceFolder:"Characters/Zuri",manifestResource:"zuri.character",rigContract:"SWAYHumanoid-v1"),
        .init(id:"kyle",displayName:"Kyle",resourceFolder:"Characters/Kyle",manifestResource:"kyle.character",rigContract:"SWAYHumanoid-v1"),
        .init(id:"user",displayName:"Your Dancer",resourceFolder:"Characters/UserAvatar",manifestResource:"user.character",rigContract:"SWAYHumanoid-v1")
    ]
    static func character(id:String)->SWAYCharacterRegistration? { all.first { $0.id == id.lowercased() } }
}

/// Concrete names authored by AssetFactory. Exactly one mesh in each modular group is
/// enabled by the runtime. Material tokens are deliberately separate from mesh tokens.
struct SWAYResolvedCharacterAppearance: Equatable, Sendable {
    let visibleMeshes:Set<String>
    let materialTokens:[String:String]
    let bodyScale:Float
    let headScale:Float
    let limbScale:Float
    let hairScale:Float
}

enum SWAYCharacterAppearanceResolver {
    private static func index(_ value:Int,_ count:Int)->Int { ((value % count) + count) % count }
    static func resolve(_ profile:SwayCharacterProfile)->SWAYResolvedCharacterAppearance {
        let bodies:[SwayBodyStyle:String] = [.male:"yd_body_athletic",.neutral:"yd_body_balanced",.female:"yd_body_soft"]
        let body = bodies[profile.bodyStyle]!
        let faces=["yd_face_oval","yd_face_round","yd_face_angular"]
        let hair=["yd_hair_short","yd_hair_long","yd_hair_braids","yd_hair_afro","yd_hair_bun"]
        let tops=["yd_top_tee","yd_top_tank","yd_top_jacket"], bottoms=["yd_bottom_legging","yd_bottom_short","yd_bottom_jogger"]
        let shoes=["yd_shoes_trainers","yd_shoes_hightops","yd_shoes_barefoot"]
        let accessories=["yd_accessory_none","yd_accessory_cap","yd_accessory_headband","yd_accessory_wristbands","yd_accessory_gloves"]
        let visibleMeshes:Set<String> = [
            body, faces[index(profile.faceShape,faces.count)], hair[index(profile.hairStyle,hair.count)],
            tops[index(profile.outfitStyle,tops.count)], bottoms[index(profile.outfitStyle,bottoms.count)],
            shoes[index(profile.footwearStyle,shoes.count)], accessories[index(profile.accessoryStyle,accessories.count)],
            "yd_eyes_\(index(profile.eyeStyle,4))", "yd_brows_\(index(profile.browStyle,4))",
            "yd_nose_\(index(profile.noseStyle,4))", "yd_mouth_\(index(profile.mouthStyle,4))",
            "yd_facial_hair_\(index(profile.facialHairStyle,4))"
        ]
        let materialTokens:[String:String] = [
            "skin":"skin_\(index(profile.skinTone,6))", "hair":"hair_colour_\(index(profile.hairColor,6))",
            "outfit":"outfit_colour_\(index(profile.outfitStyle,5))", "appearance":"appearance_\(index(profile.appearancePreset,5))"
        ]
        return .init(visibleMeshes:visibleMeshes,materialTokens:materialTokens,
            bodyScale:Float(profile.bodyScale),headScale:Float(profile.headScale),
            limbScale:Float(profile.limbScale),hairScale:Float(profile.hairScale))
    }
}

private extension Entity {
    func forEachDescendant(_ visit:(Entity)->Void) {
        visit(self)
        for child in children { child.forEachDescendant(visit) }
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
        guard let registration=SWAYCharacterRegistry.character(id:id) else {
            throw NSError(domain:"SWAYAvatar",code:404,userInfo:[NSLocalizedDescriptionKey:"Unknown character \(id)."]) }
        let resource=registration.manifestResource, folder=registration.resourceFolder
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
    private(set) var resolvedAppearance:SWAYResolvedCharacterAppearance?
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
        guard missing.isEmpty else { throw NSError(domain:"SWAYAvatar",code:422,userInfo:[NSLocalizedDescriptionKey:"\(character.characterID) is missing animations: \(missing.sorted().joined(separator:", "))"]) }
        lastMessage=nil
    }
    func apply(profile:SwayCharacterProfile) {
        guard let entity else { return }
        let resolved=SWAYCharacterAppearanceResolver.resolve(profile)
        resolvedAppearance=resolved
        entity.forEachDescendant { child in
            let key=child.name.lowercased()
            if key.hasPrefix("yd_body_") || key.hasPrefix("yd_face_") || key.hasPrefix("yd_eyes_") || key.hasPrefix("yd_brows_") || key.hasPrefix("yd_nose_") || key.hasPrefix("yd_mouth_") || key.hasPrefix("yd_hair_") || key.hasPrefix("yd_facial_hair_") || key.hasPrefix("yd_top_") || key.hasPrefix("yd_bottom_") || key.hasPrefix("yd_shoes_") || key.hasPrefix("yd_accessory_") {
                child.isEnabled=resolved.visibleMeshes.contains(key)
            }
            if key == "body_root" { child.scale = SIMD3<Float>(repeating:resolved.bodyScale) }
            if key == "head_root" { child.scale = SIMD3<Float>(repeating:resolved.headScale) }
            if key == "limbs_root" { child.scale = SIMD3<Float>(repeating:resolved.limbScale) }
            if key == "hair_root" { child.scale = SIMD3<Float>(repeating:resolved.hairScale) }
        }
        applyMaterials(resolved,to:entity)
    }
    private func applyMaterials(_ appearance:SWAYResolvedCharacterAppearance,to root:Entity) {
        let palettes:[String:[UIColor]]=[
            "skin":[#colorLiteral(red:0.22,green:0.10,blue:0.06,alpha:1),#colorLiteral(red:0.38,green:0.19,blue:0.11,alpha:1),#colorLiteral(red:0.55,green:0.31,blue:0.20,alpha:1),#colorLiteral(red:0.72,green:0.47,blue:0.32,alpha:1),#colorLiteral(red:0.84,green:0.64,blue:0.48,alpha:1),#colorLiteral(red:0.94,green:0.79,blue:0.66,alpha:1)],
            "hair":[.black,.brown,.systemBrown,.systemOrange,.systemPurple,.systemBlue],
            "outfit":[.systemPink,.systemTeal,.systemPurple,.systemOrange,.systemGreen]
        ]
        root.forEachDescendant { child in
            guard var component=(child as? ModelEntity)?.model else { return }
            let name=child.name.lowercased()
            let slot=(name.contains("body") || name.contains("face") || name.contains("barefoot")) ? "skin" : name.contains("hair") ? "hair" : (name.contains("top") || name.contains("bottom")) ? "outfit" : nil
            guard let slot, let colors=palettes[slot], let token=appearance.materialTokens[slot], let index=Int(token.split(separator:"_").last ?? "0") else { return }
            let preset=Int(appearance.materialTokens["appearance"]?.split(separator:"_").last ?? "0") ?? 0
            component.materials=[SimpleMaterial(color:colors[index % colors.count],roughness:.float(Float(0.48 + Double(preset) * 0.1)),isMetallic:false)]
            (child as? ModelEntity)?.model=component
        }
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
    func unload(){controller?.stop();controller=nil;entity=nil;clipEntities=[];animationByName=[:];activeMoveID=nil;resolvedAppearance=nil}
}

// Production-stage view. It only activates when the actual rigged Lucia asset exists.
// Until then SWAY explicitly uses the cutout bridge; there is no fake 3D substitute.
struct SWAYRealityAvatarView:View {
    let characterID:String; let moveID:String; let musicalTime:TimeInterval; let bpm:Double; let paused:Bool; let mirrored:Bool
    var profile:SwayCharacterProfile?=nil
    @StateObject private var renderer=SWAYRealityAvatarRenderer()
    @State private var loadError:String?
    var body:some View {
        RealityView { content in
            do {
                let manifest=try SWAYAvatarManifestLoader.realityCharacter(characterID)
                try await renderer.load(character:manifest); try await renderer.prepare()
                if let entity=renderer.entity { if let profile { renderer.apply(profile:profile) }; content.add(entity); renderer.play(moveID:moveID,transition:0.16); renderer.seek(toMusicalTime:musicalTime,bpm:bpm); renderer.setMirrored(mirrored); if paused{renderer.pause()} }
            } catch { loadError=error.localizedDescription }
        } update:{ _ in
            if let profile { renderer.apply(profile:profile) }; renderer.play(moveID:moveID,transition:0.16); renderer.seek(toMusicalTime:musicalTime,bpm:bpm); renderer.setMirrored(mirrored); paused ? renderer.pause():renderer.resume()
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
    var profile:SwayCharacterProfile?=nil
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
                SWAYRealityAvatarView(characterID:characterID,moveID:realityMoveID,musicalTime:elapsed,bpm:bpm,paused:paused,mirrored:mirrored,profile:profile)
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
        SWAYCoachPuppetView(moveID:moveID,musicalTime:musicalTime,bpm:bpm)
            .scaleEffect(x:mirrored ? -1:1,y:1)
    }
}
