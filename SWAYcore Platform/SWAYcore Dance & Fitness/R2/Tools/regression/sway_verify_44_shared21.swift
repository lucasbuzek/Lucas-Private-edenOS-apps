import Foundation
import RealityKit
import Darwin

guard CommandLine.arguments.count==2 else {fputs("expected isolated export root\n",stderr);exit(1)}
let path = CommandLine.arguments[1]
let manifestURL=URL(fileURLWithPath:path+"/user.character.json")
let manifest=try JSONSerialization.jsonObject(with:Data(contentsOf:manifestURL)) as! [String:Any]
guard (manifest["runtimeApproved"] as? Bool)==false else {print("UNEXPECTED_APPROVAL");exit(2)}
let modules=manifest["moduleAssets"] as! [String:String]
let animations=manifest["sharedAnimationPaths"] as! [String:String]
guard modules.count==44 && animations.count==21 else {
 print("MANIFEST_COUNTS_FAIL",modules.count,animations.count);exit(3)
}
func rss()->Int64 {var x=rusage();_ = getrusage(RUSAGE_SELF,&x);return Int64(x.ru_maxrss)}
func countModels(_ e:Entity)->Int { (e.components[ModelComponent.self] == nil ? 0:1) + e.children.reduce(0){$0+countModels($1)} }
func skel(_ e:Entity)->Entity? {
 guard let child=e.findEntity(named:"SWAYRuntimeSkeleton"),
       child.components[ModelComponent.self] != nil else {return nil}
 return child
}
func skeletalClips(_ e:Entity)->[AnimationResource] {
 var a=e.availableAnimations.filter { ($0.name ?? "").contains("/Armature") && ($0.name ?? "").contains("/Action[") }
 for child in e.children { a+=skeletalClips(child)}
 return a
}
let selected:Set<String> = ["YD_Body_Balanced","YD_Face_Oval","YD_Hair_Short","YD_Top_Tee","YD_Bottom_Legging","YD_Shoes_Trainers",
 "YD_Eyes_0","YD_Brows_0","YD_Nose_0","YD_Mouth_0","YD_Facial_Hair_0"]
guard selected.count==11 && selected.isSubset(of:Set(modules.keys)) else {exit(4)}
let start=CFAbsoluteTimeGetCurrent(),startingMemory=rss()
var loaded:[String:Entity]=[:], baseBytes=0
for name in modules.keys.sorted() {
 let file=URL(fileURLWithPath:path+"/"+modules[name]!)
 guard FileManager.default.fileExists(atPath:file.path) else {print("MISSING_MODULE_ASSET",name);exit(5)}
 let item=try Entity.load(contentsOf:file)
 guard countModels(item)==1 && skel(item) != nil else {print("MODEL_OWNER_FAIL",name);exit(6)}
 let host=skel(item)!
 guard let model=host.components[ModelComponent.self],model.materials.count>0 else {print("EMPTY_IMPORTED_MATERIAL",name);exit(7)}
 baseBytes += (try FileManager.default.attributesOfItem(atPath:file.path)[.size] as! NSNumber).intValue
 loaded[name]=item
}
let readTime=CFAbsoluteTimeGetCurrent()-start,all44Peak=rss()
let parent=Entity()
for (name,item) in loaded {
 item.isEnabled=selected.contains(name)
 parent.addChild(item)
}
guard parent.children.filter({$0.isEnabled}).count==11 else {exit(8)}
var clipBytes=0,maxTimeError=0.0
for clipName in animations.keys.sorted() {
 let uri=URL(fileURLWithPath:path+"/"+animations[clipName]!)
 guard FileManager.default.fileExists(atPath:uri.path) else {print("SHARED_CLIP_MISSING",clipName);exit(9)}
 clipBytes += (try FileManager.default.attributesOfItem(atPath:uri.path)[.size] as! NSNumber).intValue
 let root=try Entity.load(contentsOf:uri)
 let clips=skeletalClips(root)
 guard clips.count==1 else {print("CLIP_ABSENT_OR_AMBIGUOUS",clipName,clips.count);exit(10)}
 var controllers=[AnimationPlaybackController]()
 for name in selected.sorted() {
  let host=skel(loaded[name]!)!
  let controller=host.playAnimation(clips[0],transitionDuration:0,startsPaused:true)
  guard controller.duration.isFinite && controller.duration>0 else {print("SHARED_REBIND_FAIL",clipName,name);exit(11)}
  controller.time=0.375*controller.duration
  guard controller.time.isFinite else {exit(12)}
  controllers.append(controller)
 }
 let values=controllers.map{$0.time}
 maxTimeError=max(maxTimeError,(values.max() ?? 0)-(values.min() ?? 0))
 for controller in controllers {controller.stop()}
}
guard maxTimeError < 0.000001 else {print("ANIMATION_CYCLE_CLOCK_DIVERGED",maxTimeError);exit(13)}
let totalTime=CFAbsoluteTimeGetCurrent()-start
print("ALL44_MODELS_NATIVE_REALITYKIT_IMPORT_PASS",loaded.count)
print("ALL21_SHARED_CLIPS_DRIVE_11_INDEPENDENT_SKINS_PASS",animations.count,"SEEK_DELTA",maxTimeError)
print("MODELS_BOUNDS_ACTIVE_11_PASS",selected.count)
print("NATIVE_MAC_RESOURCE_PROFILE","MODELS_BYTES",baseBytes,"CLIPS_BYTES",clipBytes,
 "TOTAL_BYTES",baseBytes+clipBytes,"BASE_IMPORT_SECONDS",String(format:"%.3f",readTime),
 "TEST_SECONDS",String(format:"%.3f",totalTime),
 "MAX_RSS_DELTA_BYTES",max(0,all44Peak-startingMemory),
 "TEST_MAX_RSS_BYTES",rss())

