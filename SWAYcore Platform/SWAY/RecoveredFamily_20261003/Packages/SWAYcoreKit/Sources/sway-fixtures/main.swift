import Foundation
import SWAYcoreKit

// Emits the single movement truth (rest skeleton + all bundled moves) for the Blender pipeline.
// Usage: sway-fixtures <output.json>
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "movements.json"
func vec(_ v: Vec3) -> [Double] { [v.x, v.y, v.z] }
var rest: [String: [Double]] = [:]
for (j, v) in Proportions.rest { rest[j.rawValue] = vec(v) }
var parents: [String: String] = [:]
for (c, p) in Skeleton.parent { parents[c.rawValue] = p.rawValue }
var children: [String: String] = [:]
for (j, c) in Skeleton.primaryChild { children[j.rawValue] = c.rawValue }
let moves: [[String: Any]] = MoveLibrary.all.map { m in
    ["id": m.id, "name": m.name, "beatsPerCycle": m.beatsPerCycle,
     "keyframes": m.keyframes.map { k -> [String: Any] in
        var pose: [String: [Double]] = [:]
        for j in SWAYJoint.allCases { if let p = k.pose.position(j) { pose[j.rawValue] = vec(p) } }
        return ["count": k.count, "pose": pose] }]
}
let doc: [String: Any] = ["contract": RigContract.contractName, "units": "torso-length", "joints": SWAYJoint.allCases.map(\.rawValue),
                          "rest": rest, "parent": parents, "primaryChild": children, "movements": moves]
let data = try JSONSerialization.data(withJSONObject: doc, options: [.sortedKeys, .prettyPrinted])
try data.write(to: URL(fileURLWithPath: out))
print("wrote \(out): \(moves.count) movements")
