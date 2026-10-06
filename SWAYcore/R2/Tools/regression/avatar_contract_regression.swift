import Foundation
@main struct AvatarContractRegression {
 static func main() throws {
  func manifest(_ contract:String,_ root:String="Root",_ hips:String="Hips")->SWAYAvatarCharacterManifest {
   SWAYAvatarCharacterManifest(characterID:"lucia",version:2,renderer:"realitykit",assetBaseName:"LuciaReality",skeletonContract:contract,rootJoint:root,hipsJoint:hips,authoredBPM:120,animations:[:],runtimeApproved:false)
  }
  try manifest("SWAYHumanoid-v1").validateContract()
  do { try manifest("SWAYHumanoid-v2").validateContract();fatalError("historical v2 accepted as R2 v1") } catch {}
  do { try manifest("SWAYHumanoid-v1","root","hips").validateContract();fatalError("mismatched joints accepted") } catch {}
  let fm=FileManager.default, temporary=fm.temporaryDirectory.appendingPathComponent("sway-resource-"+UUID().uuidString+".bundle")
  defer { try? fm.removeItem(at:temporary) }
  let resources=temporary.appendingPathComponent("Contents/Resources")
  let animations=resources.appendingPathComponent("Characters/Lucia/Animations")
  try fm.createDirectory(at:animations,withIntermediateDirectories:true)
  try Data("<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>CFBundleIdentifier</key><string>test.sway.resources</string><key>CFBundlePackageType</key><string>BNDL</string></dict></plist>".utf8).write(to:temporary.appendingPathComponent("Contents/Info.plist"))
  let base=resources.appendingPathComponent("Characters/Lucia/LuciaReality.usdc"),clip=animations.appendingPathComponent("sway_knee_lift_v1.usdc")
  try Data("resolver fixture only".utf8).write(to:base);try Data("resolver fixture only".utf8).write(to:clip)
  let bundle=Bundle(url:temporary)!
  precondition(SWAYAvatarResourceLocator.url("LuciaReality",characterID:"lucia",bundle:bundle)?.standardizedFileURL == base.standardizedFileURL)
  precondition(SWAYAvatarResourceLocator.url("sway_knee_lift_v1",characterID:"lucia",animation:true,bundle:bundle)?.standardizedFileURL == clip.standardizedFileURL)
  precondition(SWAYAvatarResourceLocator.url("missing",characterID:"lucia",bundle:bundle) == nil)
  precondition(SWAYAvatarResourceLocator.url("sway_knee_lift_v1",characterID:"user",animation:true,bundle:bundle) == nil)
  precondition(manifest("SWAYHumanoid-v1").runtimeApproved == false)
  print("PASS actual bundle lookup resolves nested USDC base/clips without cross-character leakage; approval unchanged")
  print("PASS actual R2 manifest contract rejects unreconciled historical v2/joint names; approval unchanged")
 }
}
