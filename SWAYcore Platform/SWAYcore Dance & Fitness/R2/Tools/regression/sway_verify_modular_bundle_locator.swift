// Gate B: actual Foundation.Bundle resource resolution for isolated SWAY 44/21.
// Uses an UNSIGNED synthetic bundle, not the active SWAY.app. Fails closed.
import Foundation
import RealityKit
import Darwin

guard CommandLine.arguments.count == 2 else {
    fputs("Expected one isolated .bundle path\n", stderr); exit(2)
}
let path=CommandLine.arguments[1]
guard let bundle=Bundle(path:path) else {print("BUNDLE_INVALID");exit(3)}
let folder="Characters/UserAvatar"
guard let manifestURL=bundle.url(forResource:"user.character",withExtension:"json",subdirectory:folder),
      let data=try? Data(contentsOf:manifestURL),
      let manifest=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any] else {
    print("APP_MANIFEST_LOOKUP_FAIL");exit(4)
}
guard (manifest["runtimeApproved"] as? Bool)==false,
      (manifest["visualQuality"] as? String)=="UNREVIEWED",
      (manifest["maximumSimultaneousNativeModels"] as? Int)==12 else {
    print("UNAPPROVED_RESOURCE_GATE_CHANGED");exit(5)
}
guard let modules=manifest["moduleAssets"] as? [String:String],
      let animations=manifest["sharedAnimationPaths"] as? [String:String],
      modules.count==44, animations.count==21 else {
    print("MODULE_CLIP_MANIFEST_COUNTS_FAIL");exit(6)
}
var moduleURLs=[URL](), clipURLs=[URL]()
for (name,resource) in modules.sorted(by:{$0.key<$1.key}) {
    guard resource=="Modules/\(name)/SWAYModule.usdc",
          let url=bundle.url(forResource:"SWAYModule",withExtension:"usdc",
            subdirectory:folder+"/Modules/"+name) else {
        print("BUNDLE_NATIVE_MODULE_MISSING",name);exit(7)
    }
    moduleURLs.append(url)
}
for (move,resource) in animations.sorted(by:{$0.key<$1.key}) {
    let base=(resource as NSString).lastPathComponent.replacingOccurrences(of:".usdc",with:"")
    guard resource=="Animations/"+base+".usdc",
          let url=bundle.url(forResource:base,withExtension:"usdc",subdirectory:folder+"/Animations") else {
        print("BUNDLE_NATIVE_CLIP_MISSING",move);exit(8)
    }
    clipURLs.append(url)
}
print("UNAPPROVED_BUNDLE_PATHS_PASS",moduleURLs.count,clipURLs.count)
let sample=moduleURLs[0]
do {
    let entity=try await Entity(contentsOf:sample)
    guard entity.findEntity(named:"SWAYRuntimeSkeleton") != nil else {
        print("BUNDLE_SKINNED_NATIVE_ROOT_MISSING");exit(9)
    }
    print("BUNDLE_REALITYKIT_ACTUAL_MODULE_IMPORT_PASS",sample.lastPathComponent)
} catch {
    print("BUNDLE_NATIVE_REALITYKIT_IMPORT_FAIL",error.localizedDescription)
    exit(10)
}
