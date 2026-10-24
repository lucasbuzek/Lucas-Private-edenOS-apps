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
    /// A native customizable dancer must declare all actual skinned module meshes.
    let moduleMeshNames:[String]?
    /// On-demand independent module bases, never monolithic merged skin meshes.
    let moduleAssets:[String:String]?
    let maximumSimultaneousNativeModels:Int?

    /// Older v2 family assets use a different joint vocabulary; never relabel them as R2.
    func validateContract() throws {
        guard skeletonContract == "SWAYHumanoid-v1", rootJoint == "Root", hipsJoint == "Hips" else {
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[NSLocalizedDescriptionKey:"Character rig requires reconciliation with the R2 humanoid contract."])
        }
        if let assets=moduleAssets {
            guard characterID == "user", let names=moduleMeshNames,
                  Set(names)==Set(assets.keys), assets.count==44,
                  maximumSimultaneousNativeModels==12 else {
                throw NSError(domain:"SWAYAvatar",code:422,userInfo:[NSLocalizedDescriptionKey:"Invalid independent native module manifest."])
            }
            for (name,path) in assets where path != "Modules/\(name)/SWAYModule.usdc" {
                throw NSError(domain:"SWAYAvatar",code:422,userInfo:[NSLocalizedDescriptionKey:"Invalid native module resource location."])
            }
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

// The native USD importer merges meshes sharing one skeleton. Loading each
// contracted option as a separate skinned USD stage preserves an independently
// switchable ModelComponent while all stages use the same SWAYHumanoid-v1 clips.
// Only a manifest explicitly approved for the production runtime can reach here.
@MainActor
final class SWAYOnDemandNativeModules {
    let root = Entity()
    private let assets:[String:String]
    private let maximumResident:Int
    private var models:[String:Entity]=[:]
    private var playback:[AnimationPlaybackController]=[]
    private(set) var currentDuration:TimeInterval?

    init(character:SWAYAvatarCharacterManifest) throws {
        guard character.characterID == "user",
              character.runtimeApproved == true,
              let assets=character.moduleAssets,
              let names=character.moduleMeshNames,
              Set(assets.keys) == Set(names),
              assets.count == 44 else {
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                NSLocalizedDescriptionKey:"Approved 44-option native module contract required."])
        }
        let limit=character.maximumSimultaneousNativeModels ?? 12
        guard limit == 12 else {
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                NSLocalizedDescriptionKey:"Unsupported native avatar resident-model cap."])
        }
        for (name,path) in assets {
            guard name.hasPrefix("YD_"),path=="Modules/\(name)/SWAYModule.usdc" else {
                throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                    NSLocalizedDescriptionKey:"Unexpected native module path for \(name)."])
            }
        }
        self.assets=assets
        self.maximumResident=limit
        root.name="SWAYUserNativeModularRoot"
    }

    private func host(_ base:Entity)->Entity? {
        guard let skeleton=base.findEntity(named:"SWAYRuntimeSkeleton"),
              skeleton.components[ModelComponent.self] != nil else { return nil }
        return skeleton
    }
    private func countModels(_ value:Entity)->Int {
        (value.components[ModelComponent.self] == nil ? 0 : 1)
        + value.children.reduce(0) { $0 + countModels($1) }
    }

    // Restore visible modules synchronously after a cancelled/failed new load.
    // Only this root is reverted; never delete the last working user profile.
    // While a swap runs, detached old modules remain referenced for rollback:
    // device memory peak MUST still be measured before Alpha acceptance.
    private func restore(previous:[String:Entity]) {
        for (name,model) in models where previous[name] == nil {
            model.removeFromParent()
        }
        for (name,model) in previous {
            if model.parent == nil { root.addChild(model) }
            models[name]=model
        }
        for name in Array(models.keys) where previous[name] == nil {
            models.removeValue(forKey:name)
        }
        currentDuration=nil
    }

    func configure(visibleMeshes:Set<String>) async throws {
        let names=Set(visibleMeshes.map{$0.lowercased()})
        guard names.count<=maximumResident, !names.isEmpty else {
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                NSLocalizedDescriptionKey:"Profile exceeds the twelve-model native skinning limit."])
        }
        let lookup=Dictionary(uniqueKeysWithValues:assets.keys.map{($0.lowercased(),$0)})
        guard names.isSubset(of:Set(lookup.keys)) else {
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                NSLocalizedDescriptionKey:"Profile references a missing contracted skinned module."])
        }
        let selected=Set(names.compactMap{lookup[$0]})
        if Set(models.keys)==selected { return }
        // Preflight the complete selected profile before touching the scene.
        var resolvedURLs:[String:URL]=[:]
        for module in selected {
            let directory="Characters/UserAvatar/Modules/\(module)"
            guard let file=Bundle.main.url(forResource:"SWAYModule",withExtension:"usdc",subdirectory:directory)
                    ?? Bundle.main.url(forResource:"SWAYModule",withExtension:"usd",subdirectory:directory)
            else {
                throw NSError(domain:"SWAYAvatar",code:404,userInfo:[
                    NSLocalizedDescriptionKey:"Native YOUR DANCER model missing: \(module)"])
            }
            resolvedURLs[module]=file
        }
        // Keep old skinned entities only as a bounded rollback snapshot.
        // No more than 12 skinned entities remain ATTACHED to the scene.
        guard !Task.isCancelled else { throw CancellationError() }
        let previous=models
        for controller in playback { controller.stop() }
        playback=[]
        currentDuration=nil
        for obsolete in models.keys.filter({!selected.contains($0)}) {
            models[obsolete]?.removeFromParent()
            models.removeValue(forKey:obsolete)
        }
        do {
            for name in selected.sorted() where models[name] == nil {
                guard !Task.isCancelled else { throw CancellationError() }
                let model=try await Entity(contentsOf:resolvedURLs[name]!)
                guard host(model) != nil,countModels(model)==1 else {
                    throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                        NSLocalizedDescriptionKey:"RealityKit merged or lost native module \(name)."])
                }
                model.name="SWAYIndependentModule_\(name)"
                root.addChild(model)
                models[name]=model
            }
        } catch {
            restore(previous:previous)
            throw error
        }
        guard models.count==selected.count && models.count<=maximumResident else {
            restore(previous:previous)
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                NSLocalizedDescriptionKey:"Native profile module-set mismatch."])
        }
    }

    /// Actual RealityKit PBR tinting for runtime YOUR DANCER selections.
    /// Reuse imported UsdPreviewSurface PBR roughness/textures and recolor
    /// only its base tint, rather than swapping meshes or adding 2D overlays.
    func applyMaterialTokens(_ tokens:[String:String]) throws {
        func selected(_ key:String,_ prefix:String,_ count:Int)->Int? {
            guard let value=tokens[key] else { return nil }
            return (0..<count).first { value == "\(prefix)\($0)" }
        }
        guard let skin=selected("skin","skin_",6),
              let hair=selected("hair","hair_colour_",6),
              let outfit=selected("outfit","outfit_colour_",5),
              let appearance=selected("appearance","appearance_",5) else {
            throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                NSLocalizedDescriptionKey:"Unrecognized native YOUR DANCER material token."])
        }
        let skinColors:[UIColor] = [
            UIColor(red:0.98,green:0.79,blue:0.67,alpha:1),
            UIColor(red:0.86,green:0.62,blue:0.46,alpha:1),
            UIColor(red:0.68,green:0.43,blue:0.30,alpha:1),
            UIColor(red:0.47,green:0.28,blue:0.20,alpha:1),
            UIColor(red:0.31,green:0.18,blue:0.14,alpha:1),
            UIColor(red:0.22,green:0.12,blue:0.09,alpha:1)
        ]
        let hairColors:[UIColor] = [
            UIColor(red:0.16,green:0.08,blue:0.05,alpha:1),
            UIColor(red:0.27,green:0.13,blue:0.07,alpha:1),
            UIColor(red:0.08,green:0.06,blue:0.06,alpha:1),
            UIColor(red:0.38,green:0.12,blue:0.08,alpha:1),
            UIColor(red:0.64,green:0.28,blue:0.12,alpha:1),
            UIColor(red:0.73,green:0.57,blue:0.30,alpha:1)
        ]
        let outfitColors:[UIColor] = [
            UIColor(red:0.82,green:0.12,blue:0.48,alpha:1),
            UIColor(red:0.14,green:0.65,blue:0.78,alpha:1),
            UIColor(red:0.48,green:0.31,blue:0.86,alpha:1),
            UIColor(red:0.95,green:0.48,blue:0.17,alpha:1),
            UIColor(red:0.12,green:0.72,blue:0.47,alpha:1)
        ]
        let appearanceColors:[UIColor] = [
            UIColor(red:0.92,green:0.80,blue:0.70,alpha:1),
            UIColor(red:0.76,green:0.61,blue:0.48,alpha:1),
            UIColor(red:0.58,green:0.42,blue:0.34,alpha:1),
            UIColor(red:0.32,green:0.22,blue:0.20,alpha:1),
            UIColor(red:0.18,green:0.13,blue:0.13,alpha:1)
        ]
        var updates:[(Entity,ModelComponent)]=[]
        for (name,entity) in models {
            let lower=name.lowercased()
            let tint:UIColor
            if lower.hasPrefix("yd_hair_") || lower.hasPrefix("yd_brows_") ||
               lower.hasPrefix("yd_facial_hair_") {
                tint=hairColors[hair]
            } else if lower.hasPrefix("yd_top_") || lower.hasPrefix("yd_bottom_") ||
                      lower.hasPrefix("yd_accessory_") {
                tint=outfitColors[outfit]
            } else if lower.hasPrefix("yd_eyes_") || lower.hasPrefix("yd_mouth_") {
                tint=appearanceColors[appearance]
            } else if lower.hasPrefix("yd_shoes_") {
                // Neutral imported shoe materials remain authored PBR.
                continue
            } else {
                tint=skinColors[skin]
            }
            guard let host=host(entity),var component=host.components[ModelComponent.self] else {
                throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                    NSLocalizedDescriptionKey:"Missing skinned mesh while applying native material tokens."])
            }
            var materials:[any RealityKit.Material]=[]
            for original in component.materials {
                guard var pbr=original as? PhysicallyBasedMaterial else {
                    throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                        NSLocalizedDescriptionKey:"Imported native model has no PBR material."])
                }
                pbr.baseColor.tint=tint
                materials.append(pbr)
            }
            guard !materials.isEmpty else {
                throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                    NSLocalizedDescriptionKey:"Native material list is empty."])
            }
            component.materials=materials
            updates.append((host,component))
        }
        // Commit only after all imported model/material contracts validated.
        for (host,component) in updates { host.components.set(component) }
    }

    // Transaction boundary is the whole visual profile: module selection AND
    // PBR material validation must either both succeed or restore the prior
    // visible dancer. The old configure-only path remains private to this actor.
    func configure(visibleMeshes:Set<String>,materialTokens:[String:String]) async throws {
        let previous=models
        do {
            try Task.checkCancellation()
            try await configure(visibleMeshes:visibleMeshes)
            try Task.checkCancellation()
            try applyMaterialTokens(materialTokens)
        } catch {
            restore(previous:previous)
            throw error
        }
    }

    func play(_ resource:AnimationResource,loop:Bool,transition:TimeInterval) throws {
        guard !models.isEmpty else {return}
        for controller in playback {controller.stop()}
        playback=[]
        var duration:TimeInterval?
        for name in models.keys.sorted() {
            guard let skeleton=host(models[name]!) else {
                for controller in playback {controller.stop()}
                playback=[]
                currentDuration=nil
                throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                    NSLocalizedDescriptionKey:"Native module animation host is missing."])
            }
            let probe=skeleton.playAnimation(resource,transitionDuration:0,startsPaused:true)
            let oneShot=probe.duration
            probe.stop()
            guard oneShot.isFinite && oneShot > 0 &&
                  (duration == nil || abs(oneShot-duration!)<0.001) else {
                for controller in playback {controller.stop()}
                playback=[]
                currentDuration=nil
                throw NSError(domain:"SWAYAvatar",code:422,userInfo:[
                    NSLocalizedDescriptionKey:"Shared animation cannot bind consistently to module \(name)."])
            }
            duration=oneShot
            playback.append(skeleton.playAnimation(loop ? resource.repeat():resource,
                                                     transitionDuration:transition,startsPaused:false))
        }
        currentDuration=duration
    }
    func seek(phase:Double,cycle:Double) {
        guard let duration=currentDuration,duration.isFinite,duration>0,
              phase.isFinite,cycle.isFinite,cycle>0 else{return}
        for controller in playback {
            controller.time=duration*phase
            controller.speed=Float(duration/cycle)
        }
    }
    func setPlaybackRate(_ rate:Float){for controller in playback{controller.speed=rate}}
    func pause(){for controller in playback{controller.pause()}}
    func resume(){for controller in playback{controller.resume()}}
    func clear(){
        for controller in playback {controller.stop()}
        playback=[]
        currentDuration=nil
        for model in models.values {model.removeFromParent()}
        models=[:]
    }
}


@MainActor
final class SWAYRealityAvatarRenderer: ObservableObject, SWAYAvatarRendering {
    private(set) var character:SWAYAvatarCharacterManifest?
    private(set) var entity:Entity?
    private var controller:AnimationPlaybackController?
    private var animationHost:Entity?
    private var finiteClipDuration:TimeInterval?
    private var activeMoveID:String?
    private var animationByName:[String:AnimationResource]=[:]
    private var clipEntities:[Entity]=[]
    private var lastMessage:String?
    private var originalGroupScales:[String:SIMD3<Float>]=[:]
    private var nativeModules:SWAYOnDemandNativeModules?
    private var lastMusicalTime:TimeInterval=0
    private var lastBPM:Double=120
    private var wasPaused=false
    var diagnostics:SWAYAvatarDiagnostics { .init(renderer:"RealityKit",characterID:character?.characterID ?? "unloaded",assetLoaded:entity != nil,animationName:activeMoveID.flatMap{character?.animations[$0]?.resource},message:lastMessage) }

    // Blender/OpenUSD may export a clip as Armature/Action[0] rather than its
    // file name. Reject generic root scene/subtree animations. A concrete file
    // must expose exactly one named clip OR exactly one skeletal Action.
    private func namedClip(_ root: Entity, resource: String) -> AnimationResource? {
        var exact:[AnimationResource]=[]
        var skeletal:[AnimationResource]=[]
        func visit(_ node:Entity) {
            for anim in node.availableAnimations {
                let name=anim.name ?? ""
                if name.contains(resource) { exact.append(anim) }
                else if name.contains("/Armature") && name.contains("/Action[") {
                    skeletal.append(anim)
                }
            }
            for child in node.children { visit(child) }
        }
        visit(root)
        if exact.count == 1 { return exact[0] }
        if exact.isEmpty && skeletal.count == 1 { return skeletal[0] }
        return nil
    }

    func load(character:SWAYAvatarCharacterManifest) async throws {
        try character.validateContract()
        guard character.runtimeApproved == true else {
            throw NSError(domain:"SWAYAvatar",code:403,userInfo:[NSLocalizedDescriptionKey:"Character is awaiting production visual approval."])
        }
        self.character=character
        let loaded:Entity
        if character.moduleAssets != nil {
            // Only a future explicitly approved contract reaches this route.
            let moduleStage=try SWAYOnDemandNativeModules(character:character)
            nativeModules=moduleStage
            loaded=moduleStage.root
            animationHost=nil
        } else {
            guard let baseURL=SWAYAvatarResourceLocator.url(character.assetBaseName,characterID:character.characterID) else {
                throw NSError(domain:"SWAYAvatar",code:404,userInfo:[NSLocalizedDescriptionKey:"Character base asset is missing from the app bundle."])
            }
            loaded=try await Entity(contentsOf:baseURL)
            animationHost=loaded.findEntity(named:"SWAYRuntimeSkeleton")
                ?? loaded.findEntity(named:"SWAYHumanoid_v1") ?? loaded
        }
        entity=loaded
        animationByName=[:]
        clipEntities=[]
        for binding in character.animations.values {
            if let url=SWAYAvatarResourceLocator.url(binding.resource,characterID:character.characterID,animation:true),
               let clip = try? await Entity(contentsOf:url),
               let resource = namedClip(clip, resource: binding.resource) {
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
    // Applies actual named, skin-weighted YOUR DANCER USD modules. Every mesh
    // selection is explicit; absent modules fail instead of showing substitutes.
    // Scaling is always relative to imported rest scale, never cumulative.
    func applyAppearance(_ profile:SwayCharacterProfile) async throws {
        guard character?.characterID == "user" else { return }
        if let nativeModules {
            let resolved=SWAYCharacterAppearanceResolver.resolve(profile)
            let previousMove=activeMoveID
            do {
                try await nativeModules.configure(visibleMeshes:resolved.visibleMeshes,
                                                  materialTokens:resolved.materialTokens)
            } catch {
                // A cancelled appearance change must not leave the prior
                // character silently frozen after the rollback of its mesh set.
                if let previousMove {
                    activeMoveID=nil
                    play(moveID:previousMove,transition:0.12)
                    seek(toMusicalTime:lastMusicalTime,bpm:lastBPM)
                    if wasPaused { pause() }
                }
                throw error
            }
            activeMoveID=nil
            if let previousMove {
                play(moveID:previousMove,transition:0.12)
                seek(toMusicalTime:lastMusicalTime,bpm:lastBPM)
                if wasPaused { pause() }
            }
            return
        }
        guard let entity else {
            throw NSError(domain:"SWAYAvatar",code:409,userInfo:[NSLocalizedDescriptionKey:"Your Dancer is not loaded."])
        }
        let resolved=SWAYCharacterAppearanceResolver.resolve(profile)
        let scales:[String:Float]=[
            "body_root":resolved.bodyScale, "head_root":resolved.headScale,
            "limbs_root":resolved.limbScale, "hair_root":resolved.hairScale
        ]
        // Blender's USD may contain 44 named transform nodes but RealityKit
        // merge their skin geometry into ONE ModelComponent on the skeleton.
        // In that case isEnabled on a transform does NOT hide its skinned mesh.
        // Only allow native profile switching after each option has an actual
        // independently controllable RealityKit ModelComponent.
        guard let declared=character?.moduleMeshNames, !declared.isEmpty else {
            throw NSError(domain:"SWAYAvatar",code:422,
                          userInfo:[NSLocalizedDescriptionKey:"Native YOUR DANCER modular contract missing."])
        }
        var controllable:[String:Entity]=[:]
        var transformRoots:[String:Entity]=[:]
        func locate(_ node:Entity) {
            let name=node.name.lowercased()
            if name.hasPrefix("yd_") && node.components[ModelComponent.self] != nil {
                let key=name.hasSuffix("_runtime") ? String(name.dropLast("_runtime".count)) : name
                controllable[key]=node
            }
            if scales[name] != nil { transformRoots[name]=node }
            for child in node.children { locate(child) }
        }
        locate(entity)
        let expected=Set(declared.map{ $0.lowercased() })
        let missing=expected.subtracting(Set(controllable.keys))
        guard missing.isEmpty && expected.isSuperset(of:resolved.visibleMeshes) else {
            throw NSError(domain:"SWAYAvatar",code:422,
                          userInfo:[NSLocalizedDescriptionKey:"Native USD geometry cannot be switched per option in RealityKit: \(missing.count) missing independent models."])
        }
        for (key,node) in controllable {
            node.isEnabled=resolved.visibleMeshes.contains(key)
        }
        for (name,factor) in scales {
            guard let node=transformRoots[name] else { continue }
            let rest=originalGroupScales[name] ?? node.scale
            originalGroupScales[name]=rest
            node.scale=SIMD3<Float>(rest.x*factor,rest.y*factor,rest.z*factor)
        }
    }
    func prepare() async throws { guard entity != nil else { throw NSError(domain:"SWAYAvatar",code:409,userInfo:[NSLocalizedDescriptionKey:"Character must be loaded before prepare."]) } }
    func showIdle(){ play(moveID:"idle",transition:0.18) }
    func play(moveID:String,transition:TimeInterval){
        guard activeMoveID != moveID, let character,
              let binding=character.animations[moveID],
              let resource=animationByName[binding.resource] else { return }
        if let nativeModules {
            do {
                try nativeModules.play(resource,loop:binding.loop,transition:transition)
                activeMoveID=moveID
                finiteClipDuration=nativeModules.currentDuration
                lastMessage=nil
            } catch {
                activeMoveID=nil
                lastMessage=error.localizedDescription
            }
            return
        }
        guard let host=animationHost else {return}
        controller?.stop(blendOutDuration:min(0.15,transition))
        // RealityKit's repeating controller reports infinite duration. Probe the
        // one-shot skeletal clip first: seek must never multiply by infinity.
        let probe=host.playAnimation(resource,transitionDuration:0,startsPaused:true)
        let duration=probe.duration
        probe.stop()
        guard duration.isFinite && duration > 0 else {
            lastMessage="Invalid native skeletal clip duration for \(binding.resource)"
            activeMoveID=nil;finiteClipDuration=nil;controller=nil
            return
        }
        finiteClipDuration=duration
        controller=host.playAnimation(binding.loop ? resource.repeat() : resource,
                                      transitionDuration:transition,startsPaused:false)
        activeMoveID=moveID
        lastMessage=nil
    }
    func seek(toMusicalTime time:TimeInterval,bpm:Double){
        lastMusicalTime=time;lastBPM=bpm
        guard let character, let move=activeMoveID,
              let binding=character.animations[move],let duration=finiteClipDuration,
              duration.isFinite && duration > 0,time.isFinite,bpm.isFinite else{return}
        let cycle=max(0.001,binding.beatsPerCycle*60.0/max(SwayTimelineMath.minimumBPM,bpm))
        let phase=max(0,time).truncatingRemainder(dividingBy:cycle)/cycle
        if let nativeModules {
            nativeModules.seek(phase:phase,cycle:cycle)
            return
        }
        guard let controller else{return}
        controller.time=phase*duration
        controller.speed=Float(duration/cycle)
    }
    func setPlaybackRate(_ rate:Float){
        controller?.speed=rate
        nativeModules?.setPlaybackRate(rate)
    }
    func setMirrored(_ mirrored:Bool){ guard let entity else{return}; var scale=entity.scale; scale.x=abs(scale.x)*(mirrored ? -1:1); entity.scale=scale }
    func pause(){wasPaused=true;controller?.pause();nativeModules?.pause()}
    func resume(){wasPaused=false;controller?.resume();nativeModules?.resume()}
    func unload(){
        controller?.stop();controller=nil
        nativeModules?.clear();nativeModules=nil
        entity=nil;animationHost=nil;finiteClipDuration=nil;clipEntities=[];animationByName=[:];activeMoveID=nil;originalGroupScales=[:]
        character=nil
    }
}

// Production-stage view. It only activates when the actual rigged Lucia asset exists.
// Until then SWAY explicitly uses the cutout bridge; there is no fake 3D substitute.
struct SWAYRealityAvatarView:View {
    let characterID:String; let moveID:String; let musicalTime:TimeInterval; let bpm:Double; let paused:Bool; let mirrored:Bool
    var profile:SwayCharacterProfile?=nil
    @StateObject private var renderer=SWAYRealityAvatarRenderer()
    @State private var loadError:String?
    private var appearanceKey:String {
        guard characterID=="user" else{return "coach"}
        let p=profile ?? SwayCharacterProfile()
        let a=SWAYCharacterAppearanceResolver.resolve(p)
        return a.visibleMeshes.sorted().joined(separator:"|")
            + "|" + a.materialTokens.keys.sorted().map{"\($0):\(a.materialTokens[$0] ?? "")"}.joined(separator:"|")
            + "|\(a.bodyScale)|\(a.headScale)|\(a.limbScale)|\(a.hairScale)"
    }
    var body:some View {
        RealityView { content in
            do {
                let manifest=try SWAYAvatarManifestLoader.realityCharacter(characterID)
                try await renderer.load(character:manifest); try await renderer.prepare()
                if characterID == "user" { try await renderer.applyAppearance(profile ?? SwayCharacterProfile()) }
                if let entity=renderer.entity { content.add(entity); renderer.play(moveID:moveID,transition:0.16); renderer.seek(toMusicalTime:musicalTime,bpm:bpm); renderer.setMirrored(mirrored); if paused{renderer.pause()} }
            } catch { loadError=error.localizedDescription }
        } update:{ _ in
            renderer.play(moveID:moveID,transition:0.16); renderer.seek(toMusicalTime:musicalTime,bpm:bpm); renderer.setMirrored(mirrored); paused ? renderer.pause():renderer.resume()
        } placeholder:{ ProgressView().tint(.white) }
        .realityViewLayoutBehavior(.centered)
        .task(id:appearanceKey) {
            guard characterID=="user",renderer.character != nil else{return}
            do { try await renderer.applyAppearance(profile ?? SwayCharacterProfile()) }
            catch { loadError=error.localizedDescription }
        }
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
    var profile:SwayCharacterProfile?=nil
    let cutout:AnyView
    private var characterID:String { role == .coach ? "lucia" : "user" }
    private var realityMoveID:String? {
        guard let manifest = try? SWAYAvatarManifestLoader.realityCharacter(characterID),
              manifest.runtimeApproved == true else { return nil }
        // Independent modular stages have NO monolithic base USD; their paths
        // are validated by the manifest and checked per selected module at load.
        // Preserve the existing base-asset preflight for Lucia/legacy characters.
        if manifest.moduleAssets == nil &&
           SWAYAvatarResourceLocator.url(manifest.assetBaseName,characterID:characterID) == nil {
            return nil
        }
        let canonical = moveID == "idle" ? "idle" : SwayCoachPoseEngine.canonicalMoveID(moveID)
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
        SWAYAvatarStageView(role:.coach,moveID:moveID,elapsed:musicalTime,bpm:bpm,paused:paused,mirrored:mirrored,
            cutout:AnyView(SWAYSkeletal2DAvatarView(role:.coach,moveID:moveID,musicalTime:musicalTime,bpm:bpm,paused:paused,mirrored:mirrored)))
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
        let accessories=["","yd_accessory_cap","yd_accessory_headband","yd_accessory_wristbands","yd_accessory_gloves"]
        var choices:[String] = [
            body, faces[index(profile.faceShape,faces.count)], hair[index(profile.hairStyle,hair.count)],
            tops[index(profile.outfitStyle,tops.count)], bottoms[index(profile.outfitStyle,bottoms.count)],
            shoes[index(profile.footwearStyle,shoes.count)],
            "yd_eyes_\(index(profile.eyeStyle,4))", "yd_brows_\(index(profile.browStyle,4))",
            "yd_nose_\(index(profile.noseStyle,4))", "yd_mouth_\(index(profile.mouthStyle,4))",
            "yd_facial_hair_\(index(profile.facialHairStyle,4))"
        ]
        let accessory=accessories[index(profile.accessoryStyle,accessories.count)]
        if !accessory.isEmpty { choices.append(accessory) }
        let visibleMeshes=Set(choices)
        let materialTokens:[String:String] = [
            "skin":"skin_\(index(profile.skinTone,6))", "hair":"hair_colour_\(index(profile.hairColor,6))",
            "outfit":"outfit_colour_\(index(profile.outfitStyle,5))", "appearance":"appearance_\(index(profile.appearancePreset,5))"
        ]
        return .init(visibleMeshes:visibleMeshes,materialTokens:materialTokens,
            bodyScale:Float(profile.bodyScale),headScale:Float(profile.headScale),
            limbScale:Float(profile.limbScale),hairScale:Float(profile.hairScale))
    }
}


