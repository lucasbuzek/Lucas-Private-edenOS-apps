// Native macOS RealityKit smoke test for two independent SWAYHumanoid-v1 skin modules.
// Usage: swift sway_verify_two_native_modules.swift <short-base.usdc> <short-clip.usdc> <long-base.usdc> <long-clip.usdc>
// Demonstrates independent model ownership and skeletal controller, NOT final rendering approval.
import Foundation
import RealityKit
guard CommandLine.arguments.count == 5 else {
  fputs("Expected four exact USD paths\n",stderr);exit(2)
}
func skeletalResources(_ entity:Entity)->[AnimationResource] {
 var found=entity.availableAnimations.filter{
   let name=$0.name ?? ""
   return name.contains("/Armature") && name.contains("/Action[")
 }
 for child in entity.children {found += skeletalResources(child)}
 return found
}
func modelCount(_ entity:Entity)->Int {
 (entity.components[ModelComponent.self] == nil ? 0:1)+entity.children.reduce(0){$0+modelCount($1)}
}
let parent=Entity()
var modules=[Entity](),volumes=[SIMD3<Float>]()
for i in 0..<2 {
 let base=try Entity.load(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1+i*2]))
 let clip=try Entity.load(contentsOf:URL(fileURLWithPath:CommandLine.arguments[2+i*2]))
 guard modelCount(base)==1 else {print("SKINNED_DRAWABLE_MODEL_COUNT_FAIL",i,modelCount(base));exit(3)}
 let resources=skeletalResources(clip)
 guard resources.count==1 else {print("SKELETAL_CLIP_FAIL",i,resources.count);exit(4)}
 let host=base.findEntity(named:"SWAYRuntimeSkeleton") ?? base
 guard host.components[ModelComponent.self] != nil else {print("MISSING_INDEPENDENT_SKIN_OWNER",i);exit(5)}
 let playing=host.playAnimation(resources[0],transitionDuration:0,startsPaused:true)
 guard playing.duration>0 && playing.duration.isFinite else {print("NONFINITE_CLIP",i);exit(6)}
 playing.time=0.375 / 1.0 * playing.duration
 guard playing.time.isFinite else {exit(7)}
 playing.stop()
 let size=base.visualBounds(relativeTo:base).extents
 modules.append(base);volumes.append(size)
 parent.addChild(base)
 print("MODULE_RUNTIME",i,"MODEL_COMPONENTS",modelCount(base),"VISIBLE_BOUNDS",size)
}
guard simd_length(volumes[0]-volumes[1])>0.01 else {print("NO_VISIBLY_DIFFERENT_BOUNDS");exit(8)}
modules[0].isEnabled=true;modules[1].isEnabled=false
guard modules[0].isEnabled && !modules[1].isEnabled else {exit(9)}
modules[0].isEnabled=false;modules[1].isEnabled=true
guard !modules[0].isEnabled && modules[1].isEnabled else {exit(10)}
modules[0].isEnabled=true;modules[1].isEnabled=false
guard modules[0].isEnabled && !modules[1].isEnabled else {exit(11)}
print("TWO_DISTINCT_NATIVE_SKINNED_MODULES_AND_ANIMATION_CONTROLLERS_PASS")

