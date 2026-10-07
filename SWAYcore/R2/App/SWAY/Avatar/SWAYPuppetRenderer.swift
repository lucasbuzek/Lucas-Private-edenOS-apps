import SwiftUI
import Vision
import SWAYcoreEngine

/// The eight authored-TV camera headings. Right-hand headings reuse mirrored art;
/// this is an intentional turnaround rule, not a synthesized 3D rotation.
enum SWAYPuppetAngle: Int, CaseIterable, Equatable {
    case front, frontRight, right, backRight, back, backLeft, left, frontLeft

    var authoredName: String {
        switch self {
        case .front: return "front"
        case .frontRight: return "side_right" // reviewed nearest-angle fallback
        case .right: return "side_right"
        case .backRight, .backLeft: return "back" // reviewed nearest-angle fallback
        case .back: return "back"
        case .left: return "side_left"
        case .frontLeft: return "side_left" // reviewed nearest-angle fallback
        }
    }
    var mirrored: Bool { self == .frontLeft || self == .left || self == .backLeft }
}

/// Stateful quantizer with a ten-degree dead band around each 45-degree sector.
/// A heading must cross past the dead band before television-style art swaps.
struct SWAYPuppetAngleSelector {
    private(set) var angle: SWAYPuppetAngle = .front
    var hysteresisDegrees = 10.0

    mutating func select(yawRadians: Double) -> SWAYPuppetAngle {
        guard yawRadians.isFinite else { return angle }
        let degrees = (yawRadians * 180 / .pi).truncatingRemainder(dividingBy: 360)
        let normalized = degrees < 0 ? degrees + 360 : degrees
        let center = Double(angle.rawValue) * 45
        var delta = normalized - center
        if delta > 180 { delta -= 360 }; if delta < -180 { delta += 360 }
        if abs(delta) > 22.5 + hysteresisDegrees {
            angle = SWAYPuppetAngle(rawValue: Int((normalized / 45).rounded()) % 8) ?? .front
        }
        return angle
    }
}

/// Platform-independent geometry shared by the renderer and its reference
/// compositor. Values are in canvas pixels; the asset pivot is normalized to
/// the unrotated asset bounds.
struct SWAYPuppetPartPlacement: Equatable {
    let center: CGPoint
    let size: CGSize
    let rotationRadians: Double
}

enum SWAYPuppetMath {
    static func canvasPoint(_ normalized: CGPoint, canvasSize: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * canvasSize.width, y: normalized.y * canvasSize.height)
    }

    static func pivotedPlacement(
        joint: CGPoint,
        canvasSize: CGSize,
        assetSize: CGSize,
        assetPivot: CGPoint
    ) -> SWAYPuppetPartPlacement {
        let target = canvasPoint(joint, canvasSize: canvasSize)
        let centerOffset = CGPoint(
            x: (0.5 - assetPivot.x) * assetSize.width,
            y: (0.5 - assetPivot.y) * assetSize.height
        )
        return SWAYPuppetPartPlacement(
            center: CGPoint(x: target.x + centerOffset.x, y: target.y + centerOffset.y),
            size: assetSize,
            rotationRadians: 0
        )
    }

    static func limbPlacement(
        proximal: CGPoint,
        distal: CGPoint,
        canvasSize: CGSize,
        widthFraction: CGFloat
    ) -> SWAYPuppetPartPlacement {
        let start: CGPoint = canvasPoint(proximal, canvasSize: canvasSize)
        let end: CGPoint = canvasPoint(distal, canvasSize: canvasSize)
        let deltaX: CGFloat = end.x - start.x
        let deltaY: CGFloat = end.y - start.y
        let length: CGFloat = hypot(deltaX, deltaY)
        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let rotation = Double(atan2(deltaY, deltaX) - .pi / 2)
        return SWAYPuppetPartPlacement(
            center: center,
            size: CGSize(width: canvasSize.width * widthFraction, height: length),
            rotationRadians: rotation
        )
    }
}

/// Converts Vision's estimator-specific names into the 23-joint contract and
/// retains the last reliable value for dropped joints. Never invents toes.
struct SWAYVisionPuppetMapper {
    private(set) var lastGood: [String: SwayMappedJoint] = [:]

    mutating func map(_ pose: SwayBodyPose) -> [String: SwayMappedJoint] {
        let input = Dictionary(uniqueKeysWithValues: pose.joints.values.map {
            ($0.name.rawValue.rawValue, (point: SwayPoint(x: Double($0.point.x), y: Double($0.point.y)), confidence: Double($0.confidence)))
        })
        let current = SwayPoseMapper.map(input)
        for (name, joint) in current { lastGood[name] = joint }
        return lastGood
    }

    /// Conservative 2D yaw estimate. Width compression estimates magnitude;
    /// shoulder ordering supplies direction. Ambiguous/missing torsos are UNKNOWN.
    static func estimatedYaw(_ pose: SwayBodyPose) -> Double? {
        guard let ls=pose.joints[.leftShoulder], let rs=pose.joints[.rightShoulder],
              let lh=pose.joints[.leftHip], let rh=pose.joints[.rightHip],
              [ls,rs,lh,rh].allSatisfy({$0.confidence >= 0.25}) else { return nil }
        let shoulder = abs(Double(rs.point.x - ls.point.x))
        let hip = abs(Double(rh.point.x - lh.point.x))
        let width = max(shoulder, hip)
        let ratio = min(1, width / 0.28)
        let magnitude = acos(ratio)
        let direction = rs.point.x >= ls.point.x ? 1.0 : -1.0
        return direction * magnitude
    }
}

/// Native SwiftUI cut-out renderer. Each bitmap is attached between the same
/// proximal/distal SWAYHumanoid-v1 joints that drive matching and tracking.
struct SWAYPuppetRenderer: View {
    let joints: [String: CGPoint]
    let angle: SWAYPuppetAngle
    var profile: SwayCharacterProfile? = nil
    var trackingAvailable = true

    private let segments:[(String,String,String)] = [
        ("leftUpperArm","LeftUpperArm","LeftLowerArm"),("leftLowerArm","LeftLowerArm","LeftHand"),
        ("rightUpperArm","RightUpperArm","RightLowerArm"),("rightLowerArm","RightLowerArm","RightHand"),
        ("leftThigh","LeftUpperLeg","LeftLowerLeg"),("leftCalf","LeftLowerLeg","LeftFoot"),
        ("rightThigh","RightUpperLeg","RightLowerLeg"),("rightCalf","RightLowerLeg","RightFoot")]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, part in
                    if let a=joints[part.1], let b=joints[part.2] { limb(part.0,a,b,size:geometry.size) }
                }
                if let hip=joints["Hips"] { pivoted(asset("pelvis"), at:hip, size:geometry.size, width:0.20) }
                if let neck=joints["Neck"], let hip=joints["Hips"] { limb("torso",neck,hip,size:geometry.size,width:0.22) }
                if let hand=joints["LeftHand"] { pivoted(asset("leftHand"),at:hand,size:geometry.size,width:0.08) }
                if let hand=joints["RightHand"] { pivoted(asset("rightHand"),at:hand,size:geometry.size,width:0.08) }
                if let foot=joints["LeftFoot"] { pivoted(asset("leftShoe"),at:foot,size:geometry.size,width:0.12) }
                if let foot=joints["RightFoot"] { pivoted(asset("rightShoe"),at:foot,size:geometry.size,width:0.12) }
                if let head=joints["Head"] { pivoted(asset("head"),at:head,size:geometry.size,width:0.22) }
                if !trackingAvailable { Text("TRACKING UNKNOWN").font(.caption.bold()).padding(8).background(.black.opacity(0.7),in:Capsule()) }
            }.scaleEffect(x:angle.mirrored ? -1 : 1,y:1)
        }.accessibilityLabel(trackingAvailable ? "Articulated puppet" : "Puppet tracking unknown")
    }

    private func asset(_ part:String)->String {
        // Filenames include character, view and option because Xcode copies folder
        // resources into a flat bundle. Missing alternates honestly use base art.
        "lucia_\(angle.authoredName)_base_\(part)"
    }
    private func point(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        SWAYPuppetMath.canvasPoint(p, canvasSize: size)
    }
    private func limb(_ part: String, _ a: CGPoint, _ b: CGPoint, size: CGSize, width: CGFloat = 0.08) -> some View {
        let placement: SWAYPuppetPartPlacement = SWAYPuppetMath.limbPlacement(
            proximal: a,
            distal: b,
            canvasSize: size,
            widthFraction: width
        )
        return Image(asset(part)).resizable().scaledToFill()
            .frame(width: placement.size.width, height: placement.size.height).clipped()
            .rotationEffect(.radians(placement.rotationRadians)).position(placement.center)
    }
    private func pivoted(_ name:String,at p:CGPoint,size:CGSize,width:CGFloat)->some View {
        Image(name).resizable().scaledToFit().frame(width:size.width*width).position(point(p,size))
    }
}

extension SwayCoachPose {
    var puppetJoints:[String:CGPoint] {
        let chest=CGPoint(x:(leftShoulder.x+rightShoulder.x)/2,y:(leftShoulder.y+rightShoulder.y)/2)
        return ["Root":hip,"Hips":hip,"Spine":CGPoint(x:(hip.x+chest.x)/2,y:(hip.y+chest.y)/2),"Chest":chest,"Neck":neck,"Head":head,
                "LeftUpperArm":leftShoulder,"LeftLowerArm":leftElbow,"LeftHand":leftHand,"RightUpperArm":rightShoulder,"RightLowerArm":rightElbow,"RightHand":rightHand,
                "LeftUpperLeg":CGPoint(x:hip.x - 0.04,y:hip.y),"LeftLowerLeg":leftKnee,"LeftFoot":leftFoot,
                "RightUpperLeg":CGPoint(x:hip.x + 0.04,y:hip.y),"RightLowerLeg":rightKnee,"RightFoot":rightFoot]
    }
}

struct SWAYCoachPuppetView: View {
    let moveID:String; let musicalTime:TimeInterval; let bpm:Double
    @State private var selector=SWAYPuppetAngleSelector()
    var body: some View {
        let pose=SwayCoachPoseEngine.pose(moveID:moveID,musicalTime:musicalTime,bpm:bpm)
        let selected=selector.angle
        SWAYPuppetRenderer(joints:pose.puppetJoints,angle:selected)
            .onChange(of:pose.bodyYaw) { _, yaw in _=selector.select(yawRadians:yaw) }
    }
}

struct SWAYTrackedPuppetView: View {
    let pose:SwayBodyPose; let visible:Bool; var profile:SwayCharacterProfile?=nil
    @State private var mapper=SWAYVisionPuppetMapper()
    @State private var selector=SWAYPuppetAngleSelector()
    var body: some View {
        let mapped=mapper.lastGood.mapValues { CGPoint(x:$0.point.x,y:$0.point.y) }
        SWAYPuppetRenderer(joints:mapped,angle:selector.angle,profile:profile,trackingAvailable:visible)
            .opacity(mapped.isEmpty ? 0 : 1)
            .onAppear { update() }
            .onChange(of:pose.sequence) { _, _ in
                update()
            }
    }
    private func update() {
        _=mapper.map(pose)
        if let yaw=SWAYVisionPuppetMapper.estimatedYaw(pose) { _=selector.select(yawRadians:yaw) }
    }
}
