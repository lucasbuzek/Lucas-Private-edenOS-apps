import SwiftUI
import UIKit
import QuartzCore
import SWAYcoreEngine

/// Canonical COACH pose sampled from absolute musical time.
/// Renderer and matcher both consume this model; neither accumulates frame deltas.
struct SwayCoachPose {
    var head, neck, leftShoulder, rightShoulder, leftElbow, rightElbow, leftHand, rightHand, hip, leftKnee, rightKnee, leftFoot, rightFoot: CGPoint
    /// Spatial heading in radians, sampled from the same musical time as joints.
    /// Existing 2D reference joints remain available to camera matching.
    var bodyYaw: Double = 0
    static let neutral = SwayCoachPose(
        head:.init(x:0.5,y:0.12), neck:.init(x:0.5,y:0.24),
        leftShoulder:.init(x:0.40,y:0.28), rightShoulder:.init(x:0.60,y:0.28),
        leftElbow:.init(x:0.35,y:0.43), rightElbow:.init(x:0.65,y:0.43),
        leftHand:.init(x:0.33,y:0.58), rightHand:.init(x:0.67,y:0.58),
        hip:.init(x:0.5,y:0.56), leftKnee:.init(x:0.44,y:0.73), rightKnee:.init(x:0.56,y:0.73),
        leftFoot:.init(x:0.42,y:0.91), rightFoot:.init(x:0.58,y:0.91))
}

enum SwayCoachPoseEngine {
    private static let authoredMoveIDs:Set<String> = ["march","step-touch","double-step","side-tap","hip-sway","heel-dig","knee","grapevine","arm-reach","v-step","box-step","mambo","cha-cha","squat-pulse","side-lunge","cross-step","body-roll","jumping-jack","skater","pivot-turn","kick-ball-change","salsa-basic","jazz-square","power-knee","lateral-hop","turning-grapevine"]
    static func canonicalMoveID(_ moveID:String)->String {
        let lower=moveID.lowercased()
        if authoredMoveIDs.contains(lower) { return lower }
        // Alpha-authored Moves encode their executable foundation in the ID so the
        // choreography survives persistence, AirDrop and .swaypack import without a
        // hidden runtime registry. Example: user.step-touch.A1B2C3.
        if lower.hasPrefix("user.") {
            let tail=String(lower.dropFirst(5))
            if let match=authoredMoveIDs.sorted(by:{$0.count>$1.count}).first(where:{tail.hasPrefix($0+".")}) { return match }
        }
        return lower
    }
    static func supports(moveID:String)->Bool { authoredMoveIDs.contains(canonicalMoveID(moveID)) }

    /// Pure deterministic choreography: the same musical time always returns the same pose.
    static func pose(moveID: String, musicalTime: TimeInterval, bpm: Double) -> SwayCoachPose {
        let secondsPerBeat = 60.0 / max(SwayTimelineMath.minimumBPM, bpm)
        let beatPosition = max(0, musicalTime) / secondsPerBeat
        let beatIndex = Int(floor(beatPosition))
        let f = beatPosition - floor(beatPosition)
        let pulse = (1.0 - cos(f * .pi * 2.0)) * 0.5
        let side = sin((beatPosition / 2.0) * .pi * 2.0)
        let smooth = { (x: Double) -> Double in x*x*(3.0-2.0*x) }
        var p = SwayCoachPose.neutral

        switch canonicalMoveID(moveID) {
        case "march":
            if beatIndex % 2 == 0 {
                p.leftKnee.y -= 0.16*pulse; p.leftFoot.y -= 0.20*pulse
                p.rightElbow.x -= 0.055*pulse; p.leftElbow.x += 0.04*pulse
            } else {
                p.rightKnee.y -= 0.16*pulse; p.rightFoot.y -= 0.20*pulse
                p.leftElbow.x += 0.055*pulse; p.rightElbow.x -= 0.04*pulse
            }
            p.hip.y -= 0.012*pulse
        case "step-touch":
            let dx=0.085*side; p.hip.x += dx*0.45; p.neck.x += dx*0.30
            p.leftFoot.x -= max(0,-dx); p.rightFoot.x += max(0,dx)
            p.leftHand.x -= 0.07*side; p.rightHand.x -= 0.07*side
        case "double-step":
            let pair = beatIndex % 4; let dir = pair < 2 ? -1.0 : 1.0
            let travel=dir * (0.045 + 0.045*pulse); p.hip.x += travel; p.neck.x += travel*0.7
            if pair % 2 == 0 { p.leftFoot.x += travel*1.6 } else { p.rightFoot.x += travel*1.6 }
            p.leftHand.y -= 0.08*pulse; p.rightHand.y -= 0.08*pulse
        case "side-tap":
            let dir = beatIndex % 2 == 0 ? -1.0 : 1.0
            if dir < 0 { p.leftFoot.x -= 0.14*pulse } else { p.rightFoot.x += 0.14*pulse }
            p.hip.x += dir*0.025*pulse; p.leftHand.x -= dir*0.04*pulse; p.rightHand.x -= dir*0.04*pulse
        case "hip-sway":
            p.hip.x += 0.095*side; p.neck.x -= 0.03*side; p.leftHand.y=0.49; p.rightHand.y=0.49
        case "heel-dig":
            let reach=0.11*pulse
            if beatIndex%2==0 { p.leftFoot.x -= reach; p.leftFoot.y -= 0.025*pulse }
            else { p.rightFoot.x += reach; p.rightFoot.y -= 0.025*pulse }
        case "knee":
            if beatIndex%2==0 { p.leftKnee.y -= 0.18*pulse; p.leftFoot.y -= 0.22*pulse }
            else { p.rightKnee.y -= 0.18*pulse; p.rightFoot.y -= 0.22*pulse }
        case "grapevine":
            let targets:[(Double,Double,Double)] = [(-0.08,0.40,0.58),(-0.04,0.54,0.46),(0.08,0.42,0.60),(0.04,0.54,0.46)]
            let i=beatIndex%4, n=(i+1)%4, t=smooth(f), a=targets[i], b=targets[n]
            let lerp={ (x:Double,y:Double)->Double in x+(y-x)*t }
            let travel=lerp(a.0,b.0); p.hip.x += travel; p.neck.x += travel*0.72
            p.leftFoot.x=lerp(a.1,b.1); p.rightFoot.x=lerp(a.2,b.2)
        case "arm-reach":
            p.leftHand = .init(x:0.33-0.11*pulse,y:0.58-0.34*pulse); p.rightHand = .init(x:0.67+0.11*pulse,y:0.58-0.34*pulse)
            p.leftElbow = .init(x:0.35-0.01*pulse,y:0.43-0.09*pulse); p.rightElbow = .init(x:0.65+0.01*pulse,y:0.43-0.09*pulse)
        case "v-step":
            let targets:[(Double,Double)] = [(0.34,0.58),(0.34,0.66),(0.42,0.66),(0.42,0.58)]
            let i=beatIndex%4, n=(i+1)%4, t=smooth(f), a=targets[i], b=targets[n]
            p.leftFoot.x=a.0+(b.0-a.0)*t; p.rightFoot.x=a.1+(b.1-a.1)*t; p.hip.x += 0.018*side
        case "box-step":
            let q=beatIndex%4; let targets=[(0.42,0.58),(0.42,0.64),(0.36,0.64),(0.36,0.58)]
            let a=targets[q], b=targets[(q+1)%4], t=smooth(f); p.leftFoot.x=a.0+(b.0-a.0)*t; p.rightFoot.x=a.1+(b.1-a.1)*t; p.hip.y -= 0.02*pulse
        case "mambo":
            let forward=beatIndex%4<2; let reach=0.10*pulse; p.hip.y += (forward ? -0.015:0.015)*pulse
            if forward { p.leftFoot.y -= reach } else { p.rightFoot.y += reach*0.45 }; p.leftHand.x += 0.05*side; p.rightHand.x += 0.05*side
        case "cha-cha":
            let q=beatIndex%4; let shift=[-0.05,0.0,0.05,0.0][q]; p.hip.x += shift+0.025*side; p.leftFoot.x += shift*1.4; p.rightFoot.x += shift*1.4; p.leftElbow.y -= 0.04*pulse; p.rightElbow.y -= 0.04*pulse
        case "squat-pulse":
            let drop=0.16*pulse; p.hip.y += drop; p.neck.y += drop*0.55; p.leftKnee.x -= 0.09*pulse; p.rightKnee.x += 0.09*pulse; p.leftHand.y=0.50; p.rightHand.y=0.50
        case "side-lunge":
            let dir=side>=0 ? 1.0 : -1.0; let amt=0.185*abs(side); p.hip.x += dir*amt*0.45; p.hip.y += 0.08*abs(side)
            // Lift the travelling foot between its planted neutral and extended poses.
            // Same beat clock as the lunge; avoids dragging a grounded foot across the stage.
            let swing = sin(2.0 * Double.pi * beatPosition)
            let footClearance = 0.085 * swing * swing
            if dir>0 { p.rightFoot.x += amt; p.rightFoot.y -= footClearance; p.rightKnee.x += amt*0.45 }
            else { p.leftFoot.x -= amt; p.leftFoot.y -= footClearance; p.leftKnee.x -= amt*0.45 }
        case "cross-step":
            let cross=0.10*side; p.hip.x += cross*0.35; p.leftFoot.x += max(0,cross); p.rightFoot.x += min(0,cross); p.leftHand.y -= 0.10*pulse; p.rightHand.y -= 0.10*pulse
        case "body-roll":
            let wave=sin(beatPosition * .pi); p.hip.x += 0.05*wave; p.neck.x -= 0.065*wave; p.neck.y -= 0.05*abs(wave); p.hip.y += 0.025*pulse; p.leftHand.y=0.50; p.rightHand.y=0.50
        case "jumping-jack":
            let open=pulse; p.leftFoot.x -= 0.12*open; p.rightFoot.x += 0.12*open; p.leftHand=CGPoint(x:0.31-0.08*open,y:0.58-0.43*open); p.rightHand=CGPoint(x:0.69+0.08*open,y:0.58-0.43*open)
        case "skater":
            let dir=beatIndex%2==0 ? -1.0:1.0; let amt=0.10*pulse; p.hip.x += dir*amt; p.neck.x += dir*amt*0.65
            if dir<0 { p.rightFoot.x=0.48; p.rightFoot.y-=0.04*pulse } else { p.leftFoot.x=0.52; p.leftFoot.y-=0.04*pulse }
        case "pivot-turn":
            let phase=beatPosition * .pi/2; let turn=(sin(phase)-0.1*sin(3*phase))/1.1; p.leftShoulder.x += 0.055*turn; p.rightShoulder.x -= 0.055*turn; p.leftFoot.x += 0.045*side; p.rightFoot.x += 0.045*side; p.hip.x += 0.02*side
            p.bodyYaw = turn * (5 * .pi / 12)
        case "kick-ball-change":
            let q=beatIndex%4; let kick=(q==0 || q==2) ? 0.14*pulse : 0.04*pulse
            if q<2 { p.leftFoot.y -= kick; p.leftFoot.x -= 0.04*pulse } else { p.rightFoot.y -= kick; p.rightFoot.x += 0.04*pulse }; p.hip.x += 0.035*side
        case "salsa-basic":
            let forward=beatIndex%4<2; let travel=0.075*pulse; p.hip.x += 0.055*side
            if forward { p.leftFoot.y -= travel } else { p.rightFoot.y += travel }; p.leftHand.x -= 0.04*side; p.rightHand.x -= 0.04*side
        case "jazz-square":
            let q=beatIndex%4; let lx=[0.42,0.53,0.43,0.38][q], rx=[0.58,0.58,0.47,0.62][q]; p.leftFoot.x=lx; p.rightFoot.x=rx; p.hip.x += 0.03*side; p.leftHand.y -= 0.08*pulse; p.rightHand.y -= 0.08*pulse
        case "power-knee":
            let left=beatIndex%2==0; let lift=0.22*pulse
            if left { p.leftKnee.y-=lift; p.leftFoot.y-=lift*1.12; p.rightHand=CGPoint(x:0.60,y:0.36+0.16*pulse) } else { p.rightKnee.y-=lift; p.rightFoot.y-=lift*1.12; p.leftHand=CGPoint(x:0.40,y:0.36+0.16*pulse) }; p.hip.y-=0.025*pulse
        case "lateral-hop":
            let dir=beatIndex%2==0 ? -1.0:1.0; let hop=0.095*pulse; p.hip.x += dir*hop; p.neck.x += dir*hop; p.hip.y -= 0.045*pulse; p.leftFoot.x += dir*hop; p.rightFoot.x += dir*hop
        case "turning-grapevine":
            let q=beatIndex%4; let travel=[-0.09,-0.04,0.05,0.10][q]; p.hip.x += travel; p.neck.x += travel*0.7
            let twist=sin(beatPosition * Double.pi / 2); p.leftShoulder.x += 0.065*twist; p.rightShoulder.x -= 0.065*twist; p.leftFoot.x += travel*0.8; p.rightFoot.x += travel*0.8
        default: break
        }
        return p
    }

    static func jointAngles(moveID: String, musicalTime: TimeInterval, bpm: Double) -> [String: Double] {
        let p=pose(moveID:moveID,musicalTime:musicalTime,bpm:bpm)
        func angle(_ a:CGPoint,_ b:CGPoint,_ c:CGPoint)->Double {
            let v1=(Double(a.x-b.x),Double(a.y-b.y)), v2=(Double(c.x-b.x),Double(c.y-b.y))
            let dot=v1.0*v2.0+v1.1*v2.1, mag=hypot(v1.0,v1.1)*hypot(v2.0,v2.1)
            guard mag > 0 else { return 180 }
            return acos(max(-1,min(1,dot/mag)))*180/Double.pi
        }
        return ["leftElbow":angle(p.leftShoulder,p.leftElbow,p.leftHand),"rightElbow":angle(p.rightShoulder,p.rightElbow,p.rightHand),
                "leftKnee":angle(p.hip,p.leftKnee,p.leftFoot),"rightKnee":angle(p.hip,p.rightKnee,p.rightFoot),
                "leftHip":angle(p.leftShoulder,p.hip,p.leftKnee),"rightHip":angle(p.rightShoulder,p.hip,p.rightKnee)]
    }
}
