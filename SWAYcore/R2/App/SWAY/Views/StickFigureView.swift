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
    private static let authoredMoveIDs:Set<String> = ["march","step-touch","double-step","side-tap","hip-sway","heel-dig","knee","grapevine","arm-reach","v-step","box-step","mambo","cha-cha","squat-pulse","side-lunge","cross-step","body-roll","jumping-jack","skater","pivot-turn"]
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
            // Production depth: hips descend below the former proof pose while the
            // torso stays lifted and knees visibly track over widened feet.
            let drop=0.155*pulse; p.hip.y += drop; p.neck.y += drop*0.68
            p.leftKnee.x -= 0.090*pulse; p.rightKnee.x += 0.090*pulse
            p.leftFoot.x -= 0.025*pulse; p.rightFoot.x += 0.025*pulse
            p.leftHand.y=0.48; p.rightHand.y=0.48
        case "side-lunge":
            // Separate travel from level change so the loaded side reads as a lunge,
            // rather than the shallow lateral tap used by the proof candidate.
            let dir=side>=0 ? 1.0 : -1.0; let amt=0.18*abs(side); let sink=0.075*abs(side)
            p.hip.x += dir*amt*0.48; p.hip.y += sink; p.neck.x += dir*amt*0.20; p.neck.y += sink*0.55
            if dir>0 { p.rightFoot.x += amt; p.rightKnee.x += amt*0.30; p.leftKnee.x += amt*0.10 }
            else { p.leftFoot.x -= amt; p.leftKnee.x -= amt*0.30; p.rightKnee.x -= amt*0.10 }
        case "cross-step":
            let cross=0.10*side; p.hip.x += cross*0.35; p.leftFoot.x += max(0,cross); p.rightFoot.x += min(0,cross); p.leftHand.y -= 0.10*pulse; p.rightHand.y -= 0.10*pulse
        case "body-roll":
            // Counter-moving upper and lower landmarks create a readable travelling
            // torso wave in both the reference projection and the articulated bake.
            let wave=sin(beatPosition * .pi); let fold=abs(wave)
            p.neck.x -= 0.060*wave; p.neck.y -= 0.045*fold
            p.hip.x += 0.050*wave; p.hip.y += 0.060*pulse
            p.leftShoulder.y -= 0.025*fold; p.rightShoulder.y -= 0.025*fold
            p.leftHand.y=0.48; p.rightHand.y=0.48
        case "jumping-jack":
            let open=pulse; p.leftFoot.x -= 0.12*open; p.rightFoot.x += 0.12*open; p.leftHand=CGPoint(x:0.31-0.08*open,y:0.58-0.43*open); p.rightHand=CGPoint(x:0.69+0.08*open,y:0.58-0.43*open)
        case "skater":
            let dir=beatIndex%2==0 ? -1.0:1.0; let amt=0.10*pulse; p.hip.x += dir*amt; p.neck.x += dir*amt*0.65
            if dir<0 { p.rightFoot.x=0.48; p.rightFoot.y-=0.04*pulse } else { p.leftFoot.x=0.52; p.leftFoot.y-=0.04*pulse }
        case "pivot-turn":
            let turn=sin(beatPosition * .pi/2); p.leftShoulder.x += 0.055*turn; p.rightShoulder.x -= 0.055*turn; p.leftFoot.x += 0.045*side; p.rightFoot.x += 0.045*side; p.hip.x += 0.02*side
            p.bodyYaw = turn * .pi * 5 / 12
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

/// Display-refresh-driven COACH renderer. CADisplayLink owns presentation cadence;
/// SWAY musical time remains authoritative and is extrapolated from the latest engine anchor.
struct StickFigureView: UIViewRepresentable {
    let moveID:String; let elapsed:TimeInterval; let bpm:Double; let paused:Bool; let mirrored:Bool; let characterMode:Bool
    var skinTone:Int=2; var hairStyle:Int=0; var outfitStyle:Int=0; var instructorPreset:Int?=nil
    var bodyStyle:SwayBodyStyle = .neutral; var faceShape:Int=0; var hairColor:Int=0; var footwearStyle:Int=0; var accessoryStyle:Int=0
    func makeUIView(context:Context)->SwayCoachRenderView { let v=SwayCoachRenderView(); v.isOpaque=false; return v }
    func updateUIView(_ view:SwayCoachRenderView, context:Context) { view.update(moveID:moveID, elapsed:elapsed, bpm:bpm, paused:paused, mirrored:mirrored, characterMode:characterMode, skinTone:skinTone, hairStyle:hairStyle, outfitStyle:outfitStyle, instructorPreset:instructorPreset, bodyStyle:bodyStyle, faceShape:faceShape, hairColor:hairColor, footwearStyle:footwearStyle, accessoryStyle:accessoryStyle) }
}

final class SwayCoachRenderView: UIView {
    private var displayLink:CADisplayLink?
    private var moveID="march", bpm=120.0, anchorElapsed:TimeInterval=0, anchorHost:CFTimeInterval=CACurrentMediaTime(), presentationHost:CFTimeInterval=CACurrentMediaTime(), paused=false, mirrored=false, characterMode=false
    private var skinTone=2, hairStyle=0, outfitStyle=0; private var instructorPreset:Int?=nil
    private var bodyStyle:SwayBodyStyle = .neutral; private var faceShape=0, hairColor=0, footwearStyle=0, accessoryStyle=0
    override init(frame:CGRect){ super.init(frame:frame); startDisplayLink() }
    required init?(coder:NSCoder){ super.init(coder:coder); startDisplayLink() }
    deinit { displayLink?.invalidate() }
    private func startDisplayLink(){
        let link=CADisplayLink(target:self,selector:#selector(frame(_:)))
        if #available(iOS 15.0, *) { link.preferredFrameRateRange=CAFrameRateRange(minimum:30,maximum:120,preferred:60) }
        link.add(to:.main,forMode:.common); displayLink=link
    }
    func update(moveID:String, elapsed:TimeInterval, bpm:Double, paused:Bool, mirrored:Bool, characterMode:Bool, skinTone:Int, hairStyle:Int, outfitStyle:Int, instructorPreset:Int?, bodyStyle:SwayBodyStyle = .neutral, faceShape:Int = 0, hairColor:Int = 0, footwearStyle:Int = 0, accessoryStyle:Int = 0) {
        self.moveID=moveID; self.bpm=max(SwayTimelineMath.minimumBPM,bpm); self.mirrored=mirrored; self.characterMode=characterMode; self.skinTone=skinTone; self.hairStyle=hairStyle; self.outfitStyle=outfitStyle; self.instructorPreset=instructorPreset; self.bodyStyle=bodyStyle; self.faceShape=faceShape; self.hairColor=hairColor; self.footwearStyle=footwearStyle; self.accessoryStyle=accessoryStyle
        anchorElapsed=elapsed; anchorHost=CACurrentMediaTime(); self.paused=paused
        displayLink?.isPaused=false; setNeedsDisplay()
    }
    @objc private func frame(_ link:CADisplayLink){
        // Apple recommends targetTimestamp when calculating the next presentation state.
        presentationHost = link.targetTimestamp
        if !paused { setNeedsDisplay() }
    }
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let hostTime: CFTimeInterval = paused ? anchorHost : max(presentationHost, CACurrentMediaTime())
        let delta: TimeInterval = paused ? 0 : max(0, hostTime - anchorHost)
        let musicalTime: TimeInterval = anchorElapsed + delta
        let pose = SwayCoachPoseEngine.pose(moveID: moveID, musicalTime: musicalTime, bpm: bpm)
        // Physical Alpha: keep the complete dancer inside the stage instead of cropping hands/feet.
        let scale: CGFloat = 0.94

        func canvasPoint(_ normalized: CGPoint) -> CGPoint {
            let x = mirrored ? (1.0 - normalized.x) : normalized.x
            return CGPoint(
                x: (0.5 + (x - 0.5) * scale) * bounds.width,
                y: (0.53 + (normalized.y - 0.53) * scale) * bounds.height
            )
        }

        func image(named name: String) -> UIImage? { UIImage(named: name) }

        // Authored limb art is normalized around proximal/distal pivots.  The joint-to-joint
        // distance scales the pivot span, not the complete PNG.  This preserves the intentional
        // artwork beyond each joint and stops the renderer from stretching cut edges onto joints.
        func drawSegment(_ imageName: String, from start: CGPoint, to end: CGPoint, width: CGFloat, tint: UIColor? = nil, proximal: CGFloat? = nil, distal: CGFloat? = nil) {
            guard let source = image(named: imageName) else { return }
            let a = canvasPoint(start), b = canvasPoint(end)
            let dx = b.x-a.x, dy = b.y-a.y, jointLength = hypot(dx,dy)
            guard jointLength > 0.5 else { return }
            let angle = atan2(dy,dx) - (.pi/2)
            let p0 = proximal ?? 0.0, p1 = distal ?? 1.0
            let span = max(0.1,p1-p0)
            let authoredHeight = jointLength/span
            let authoredWidth: CGFloat
            if proximal != nil, distal != nil, source.size.height > 0 {
                authoredWidth = authoredHeight * source.size.width/source.size.height
            } else {
                authoredWidth = width
            }
            let target=CGRect(x:-authoredWidth/2,y:-p0*authoredHeight,width:authoredWidth,height:authoredHeight)
            context.saveGState(); context.translateBy(x:a.x,y:a.y); context.rotate(by:angle)
            if let tint, let mask=source.cgImage { context.clip(to:target,mask:mask); context.setFillColor(tint.cgColor); context.fill(target) }
            else { source.draw(in:target) }
            context.restoreGState()
        }

        func drawAxialPart(_ imageName:String, from start:CGPoint, to end:CGPoint, proximal:CGFloat, distal:CGFloat, tint:UIColor?=nil) {
            drawSegment(imageName,from:start,to:end,width:1,tint:tint,proximal:proximal,distal:distal)
        }

        func drawPivoted(_ imageName:String, pivot:CGPoint, at anchor:CGPoint, size:CGSize, tint:UIColor?=nil, rotation:CGFloat=0) {
            guard let source=image(named:imageName) else { return }
            let c=canvasPoint(anchor)
            let target=CGRect(x:-pivot.x*size.width,y:-pivot.y*size.height,width:size.width,height:size.height)
            context.saveGState(); context.translateBy(x:c.x,y:c.y); context.rotate(by:rotation)
            if let tint, let mask=source.cgImage { context.clip(to:target,mask:mask); context.setFillColor(tint.cgColor); context.fill(target) }
            else { source.draw(in:target) }
            context.restoreGState()
        }

        func drawPivotedAtCanvas(_ imageName:String, pivot:CGPoint, canvasAnchor:CGPoint, size:CGSize, tint:UIColor?=nil, rotation:CGFloat=0) {
            guard let source=image(named:imageName) else { return }
            let target=CGRect(x:-pivot.x*size.width,y:-pivot.y*size.height,width:size.width,height:size.height)
            context.saveGState(); context.translateBy(x:canvasAnchor.x,y:canvasAnchor.y); context.rotate(by:rotation)
            if let tint, let mask=source.cgImage { context.clip(to:target,mask:mask); context.setFillColor(tint.cgColor); context.fill(target) }
            else { source.draw(in:target) }
            context.restoreGState()
        }

        func drawCentered(_ imageName: String, at center: CGPoint, size: CGSize, tint: UIColor? = nil, rotation: CGFloat = 0) {
            drawPivoted(imageName,pivot:CGPoint(x:0.5,y:0.5),at:center,size:size,tint:tint,rotation:rotation)
        }

        let unit: CGFloat = max(8.0, bounds.width * 0.034)
        let presetNames = ["lucia", "nandi", "thabo", "zuri", "kyle"]
        let presetIndex = max(0, min(instructorPreset ?? 0, presetNames.count - 1))
        let preset = presetNames[presetIndex]
        let skinColors: [UIColor] = [
            UIColor(red:0.96, green:0.76, blue:0.62, alpha:1),
            UIColor(red:0.86, green:0.60, blue:0.43, alpha:1),
            UIColor(red:0.70, green:0.43, blue:0.28, alpha:1),
            UIColor(red:0.48, green:0.27, blue:0.17, alpha:1),
            UIColor(red:0.30, green:0.16, blue:0.11, alpha:1)
        ]
        let outfitColors: [UIColor] = [.systemPink, .systemPurple, .systemBlue, .systemOrange, UIColor(red:0.12, green:0.78, blue:0.68, alpha:1)]
        let skin = skinColors[max(0, min(skinTone, skinColors.count - 1))]
        let outfit = outfitColors[max(0, min(outfitStyle, outfitColors.count - 1))]

        // Instructor presets use their authored transparent body-part assets. User/custom
        // appearances use the neutral masks with selected skin/outfit tints. Both paths
        // are articulated by exactly the same SwayCoachPoseEngine joints.
        let usesInstructorAssets = instructorPreset != nil
        func part(_ suffix: String, fallback: String) -> String {
            let authored = "Rig_\(preset)_\(suffix)"
            guard usesInstructorAssets else { return fallback }
            if image(named:authored) != nil { return authored }
            // Lucia is the Alpha production instructor: required parts must never silently
            // degrade to generic avatar masks. A missing required Lucia asset therefore
            // renders absent and is immediately visible during acceptance testing.
            if preset == "lucia" { return authored }
            // Future instructor families remain allowed to use the neutral rig until their
            // complete authored asset contracts are delivered.
            return fallback
        }
        let authoredTint: UIColor? = usesInstructorAssets ? nil : skin
        let outfitTint: UIColor? = usesInstructorAssets ? nil : outfit

        drawSegment(part("leftUpperArm", fallback:"RigUpperLimb"), from:pose.leftShoulder, to:pose.leftElbow, width:unit*1.55, tint:authoredTint, proximal: usesInstructorAssets ? 0.06 : nil, distal: usesInstructorAssets ? 0.94 : nil)
        drawSegment(part("leftLowerArm", fallback:"RigLowerLimb"), from:pose.leftElbow, to:pose.leftHand, width:unit*1.28, tint:authoredTint, proximal: usesInstructorAssets ? 0.06 : nil, distal: usesInstructorAssets ? 0.94 : nil)
        drawSegment(part("rightUpperArm", fallback:"RigUpperLimb"), from:pose.rightShoulder, to:pose.rightElbow, width:unit*1.55, tint:authoredTint, proximal: usesInstructorAssets ? 0.06 : nil, distal: usesInstructorAssets ? 0.94 : nil)
        drawSegment(part("rightLowerArm", fallback:"RigLowerLimb"), from:pose.rightElbow, to:pose.rightHand, width:unit*1.28, tint:authoredTint, proximal: usesInstructorAssets ? 0.06 : nil, distal: usesInstructorAssets ? 0.94 : nil)
        // Lucia's pelvis contract defines the spine and both hip sockets. Convert those
        // authored pivots back into pose-space so the legs originate from the artwork's
        // actual sockets rather than an arbitrary symmetric offset. Other rigs retain the
        // neutral socket spread until their complete manifests are authored.
        let pelvisSize=CGSize(width:unit*4.5,height:unit*2.35)
        let leftHipSocket:CGPoint
        let rightHipSocket:CGPoint
        if usesInstructorAssets && preset == "lucia" {
            let dxL=(0.32-0.50)*pelvisSize.width/max(1,bounds.width)
            let dxR=(0.68-0.50)*pelvisSize.width/max(1,bounds.width)
            let dy=(0.75-0.10)*pelvisSize.height/max(1,bounds.height)
            leftHipSocket=CGPoint(x:pose.hip.x+dxL,y:pose.hip.y+dy)
            rightHipSocket=CGPoint(x:pose.hip.x+dxR,y:pose.hip.y+dy)
        } else {
            let hipSpread:CGFloat=0.043
            leftHipSocket=CGPoint(x:pose.hip.x-hipSpread,y:pose.hip.y)
            rightHipSocket=CGPoint(x:pose.hip.x+hipSpread,y:pose.hip.y)
        }
        drawSegment(part("leftThigh", fallback:"RigUpperLimb"), from:leftHipSocket, to:pose.leftKnee, width:unit*1.95, tint:outfitTint, proximal: usesInstructorAssets ? 0.05 : nil, distal: usesInstructorAssets ? 0.95 : nil)
        drawSegment(part("leftCalf", fallback:"RigLowerLimb"), from:pose.leftKnee, to:pose.leftFoot, width:unit*1.52, tint:outfitTint, proximal: usesInstructorAssets ? 0.05 : nil, distal: usesInstructorAssets ? 0.95 : nil)
        drawSegment(part("rightThigh", fallback:"RigUpperLimb"), from:rightHipSocket, to:pose.rightKnee, width:unit*1.95, tint:outfitTint, proximal: usesInstructorAssets ? 0.05 : nil, distal: usesInstructorAssets ? 0.95 : nil)
        drawSegment(part("rightCalf", fallback:"RigLowerLimb"), from:pose.rightKnee, to:pose.rightFoot, width:unit*1.52, tint:outfitTint, proximal: usesInstructorAssets ? 0.05 : nil, distal: usesInstructorAssets ? 0.95 : nil)

        let neck = canvasPoint(pose.neck)
        let hip = canvasPoint(pose.hip)
        let torsoCenter = CGPoint(x:(pose.neck.x + pose.hip.x)/2.0, y:(pose.neck.y + pose.hip.y)/2.0)
        if usesInstructorAssets && preset == "lucia" {
            drawPivoted(part("pelvis",fallback:"RigTorso"),pivot:CGPoint(x:0.5,y:0.10),at:pose.hip,size:pelvisSize)
        } else {
            drawCentered(part("pelvis", fallback:"RigTorso"), at:CGPoint(x:pose.hip.x,y:pose.hip.y-0.012), size:pelvisSize, tint:outfitTint)
        }
        if usesInstructorAssets {
            // Lucia manifest: neck 0.08, pelvis 0.92. Align those authored pivots to pose joints.
            drawAxialPart(part("torso", fallback:"RigTorso"), from:pose.neck, to:pose.hip, proximal:0.08, distal:0.92)
        } else {
            drawCentered(part("torso", fallback:"RigTorso"), at:torsoCenter, size:CGSize(width:unit*5.7, height:max(unit*5.2, abs(hip.y-neck.y)*1.35)), tint:outfitTint)
        }
        let headSize=CGSize(width:unit*(faceShape == 2 ? 3.9 : faceShape == 1 ? 4.05 : 4.25),height:unit*(faceShape == 2 ? 4.8 : faceShape == 1 ? 4.7 : 4.65))
        if usesInstructorAssets && preset == "lucia" {
            // Lucia is one rigid head assembly.  The head's authored neck pivot is attached to
            // the skeleton neck; both hair layers then attach to the resulting head centre.
            // This removes the previous split anchors (pose.head vs pose.neck) that physically
            // produced a floating hair/head stack on iPhone.
            let neckCanvas=canvasPoint(pose.neck)
            let headCenterCanvas=CGPoint(x:neckCanvas.x,y:neckCanvas.y + (0.5-0.92)*headSize.height)
            let hairSize=CGSize(width:unit*4.5,height:unit*4.8)
            drawPivotedAtCanvas(part("hairBack",fallback:"RigHair"),pivot:CGPoint(x:0.5,y:0.55),canvasAnchor:headCenterCanvas,size:hairSize)
            drawPivotedAtCanvas(part("head",fallback:"RigHead"),pivot:CGPoint(x:0.5,y:0.92),canvasAnchor:neckCanvas,size:headSize)
            drawPivotedAtCanvas(part("hairFront",fallback:"RigHair"),pivot:CGPoint(x:0.5,y:0.55),canvasAnchor:headCenterCanvas,size:hairSize)
        } else {
            if usesInstructorAssets { drawCentered(part("hairBack",fallback:"RigHair"),at:pose.head,size:CGSize(width:unit*4.5,height:unit*4.8)) }
            drawCentered(part("head",fallback:"RigHead"),at:pose.head,size:headSize,tint:authoredTint)
            if usesInstructorAssets { drawCentered(part("hairFront",fallback:"RigHair"),at:pose.head,size:CGSize(width:unit*4.5,height:unit*4.8)) }
        }

        if !usesInstructorAssets {
            // Production user-avatar hair is deterministic vector artwork rather than a
            // resized generic RigHair mask. Each exposed style has genuinely different
            // geometry while sharing the canonical head socket.
            let hairColors: [UIColor] = [
                UIColor(red:0.12,green:0.06,blue:0.04,alpha:1),
                UIColor(red:0.24,green:0.10,blue:0.05,alpha:1),
                .black, UIColor(red:0.30,green:0.16,blue:0.08,alpha:1),
                UIColor(red:0.10,green:0.07,blue:0.05,alpha:1)
            ]
            let style = max(0, hairStyle) % 5
            let color = hairColors[max(0, hairColor) % hairColors.count]
            let h = canvasPoint(pose.head)
            context.saveGState()
            context.setFillColor(color.cgColor)
            switch style {
            case 0: // Ponytail
                context.fillEllipse(in:CGRect(x:h.x-unit*2.05,y:h.y-unit*2.45,width:unit*4.1,height:unit*2.35))
                context.fillEllipse(in:CGRect(x:h.x+unit*1.35,y:h.y-unit*1.25,width:unit*1.75,height:unit*3.2))
            case 1: // Braids
                context.fillEllipse(in:CGRect(x:h.x-unit*2.15,y:h.y-unit*2.45,width:unit*4.3,height:unit*2.15))
                for side: CGFloat in [-1, 1] {
                    for bead in 0..<4 {
                        let y=h.y-unit*0.75+CGFloat(bead)*unit*0.72
                        context.fillEllipse(in:CGRect(x:h.x+side*unit*1.72-unit*0.36,y:y,width:unit*0.72,height:unit*0.86))
                    }
                }
            case 2: // Short
                let path=UIBezierPath(roundedRect:CGRect(x:h.x-unit*2.08,y:h.y-unit*2.38,width:unit*4.16,height:unit*1.95),cornerRadius:unit*0.9)
                path.fill()
            case 3: // Curls
                for row in 0..<2 {
                    for col in 0..<5 {
                        let x=h.x-unit*1.9+CGFloat(col)*unit*0.95
                        let y=h.y-unit*2.25+CGFloat(row)*unit*0.72
                        context.fillEllipse(in:CGRect(x:x-unit*0.52,y:y-unit*0.52,width:unit*1.04,height:unit*1.04))
                    }
                }
            default: // Cap
                let crown=UIBezierPath(roundedRect:CGRect(x:h.x-unit*2.05,y:h.y-unit*2.35,width:unit*4.1,height:unit*1.55),cornerRadius:unit*0.72)
                crown.fill()
                context.fill(CGRect(x:h.x+unit*0.85,y:h.y-unit*1.12,width:unit*2.0,height:unit*0.42))
            }
            context.restoreGState()
        }
        if usesInstructorAssets && preset == "lucia" {
            drawPivoted(part("leftHand",fallback:"RigHand"),pivot:CGPoint(x:0.5,y:0.10),at:pose.leftHand,size:CGSize(width:unit*1.15,height:unit*1.3))
            drawPivoted(part("rightHand",fallback:"RigHand"),pivot:CGPoint(x:0.5,y:0.10),at:pose.rightHand,size:CGSize(width:unit*1.15,height:unit*1.3))
        } else {
            drawCentered(part("leftHand", fallback:"RigHand"), at:pose.leftHand, size:CGSize(width:unit*1.15,height:unit*1.3), tint:authoredTint)
            drawCentered(part("rightHand", fallback:"RigHand"), at:pose.rightHand, size:CGSize(width:unit*1.15,height:unit*1.3), tint:authoredTint)
        }
        let shoeColors:[UIColor] = [.white,.black,.systemPink,.systemCyan]
        let shoeTint:UIColor? = usesInstructorAssets ? nil : shoeColors[max(0,footwearStyle) % shoeColors.count]
        let shoeScale:CGFloat = [1.0,1.12,0.94,1.04][max(0,footwearStyle) % 4]
        let shoeSize=CGSize(width:unit*2.55*shoeScale,height:unit*1.25*(footwearStyle == 1 ? 1.25:1))
        if usesInstructorAssets && preset == "lucia" {
            drawPivoted(part("leftShoe",fallback:"RigShoe"),pivot:CGPoint(x:0.35,y:0.25),at:pose.leftFoot,size:shoeSize)
            drawPivoted(part("rightShoe",fallback:"RigShoe"),pivot:CGPoint(x:0.65,y:0.25),at:pose.rightFoot,size:shoeSize)
        } else {
            drawCentered(part("leftShoe",fallback:"RigShoe"),at:pose.leftFoot,size:shoeSize,tint:shoeTint)
            drawCentered(part("rightShoe",fallback:"RigShoe"),at:pose.rightFoot,size:shoeSize,tint:shoeTint)
        }
        if !usesInstructorAssets && accessoryStyle > 0 {
            context.saveGState(); context.setStrokeColor(UIColor.systemYellow.cgColor); context.setLineWidth(max(2,unit*0.18))
            if accessoryStyle == 1 { // headband
                let h=canvasPoint(pose.head); context.strokeEllipse(in:CGRect(x:h.x-unit*1.75,y:h.y-unit*1.35,width:unit*3.5,height:unit*0.7))
            } else if accessoryStyle == 2 { // wristbands
                for hand in [pose.leftHand,pose.rightHand] { let q=canvasPoint(hand); context.strokeEllipse(in:CGRect(x:q.x-unit*0.55,y:q.y-unit*0.55,width:unit*1.1,height:unit*1.1)) }
            } else { // glasses
                let h=canvasPoint(pose.head); for dx in [-unit*0.82,unit*0.82] { context.strokeEllipse(in:CGRect(x:h.x+dx-unit*0.62,y:h.y-unit*0.45,width:unit*1.24,height:unit*0.82)) }; context.move(to:CGPoint(x:h.x-unit*0.2,y:h.y-unit*0.05)); context.addLine(to:CGPoint(x:h.x+unit*0.2,y:h.y-unit*0.05)); context.strokePath()
            }
            context.restoreGState()
        }
    }
}

struct SwayHumanFigureView: View {
    var moveID:String; var elapsed:TimeInterval; var bpm:Double; var paused:Bool; var mirrored:Bool
    var style:SwayBodyStyle = .neutral; var portraitData:Data? = nil; var characterMode:Bool = false
    var skinTone:Int=2; var hairStyle:Int=0; var outfitStyle:Int=0; var appearancePreset:Int=0; var instructorPreset:Int?=nil
    var bodyStyle:SwayBodyStyle = .neutral; var faceShape:Int=0; var hairColor:Int=0; var footwearStyle:Int=0; var accessoryStyle:Int=0

    private var alphaProfile:SwayCharacterProfile {
        var p=SwayCharacterProfile()
        if instructorPreset != nil {
            // Lucia is a stable authored COACH identity; user customization never leaks into her.
            p.bodyStyle = .female; p.skinTone = 3; p.faceShape = 0; p.hairStyle = 3; p.hairColor = 0
            p.outfitStyle = 2; p.footwearStyle = 2; p.accessoryStyle = 0
        } else {
            p.bodyStyle=bodyStyle; p.portraitData=portraitData; p.skinTone=skinTone; p.hairStyle=hairStyle
            p.outfitStyle=outfitStyle; p.appearancePreset=appearancePreset; p.faceShape=faceShape
            p.hairColor=hairColor; p.footwearStyle=footwearStyle; p.accessoryStyle=accessoryStyle
        }
        return p
    }

    var body: some View {
        // BUILD 138: the Alpha runtime has one visible character authority.
        // Every SwayHumanFigureView consumer now renders through the 2.5D surface;
        // the legacy PNG cutout remains source/debug code only and cannot silently win
        // because instructorPreset is nil or non-zero.
        SWAYSkeletal2DAvatarView(
            role: instructorPreset != nil ? .coach : .user,
            moveID: moveID,
            musicalTime: elapsed,
            bpm: bpm,
            paused: paused,
            mirrored: mirrored,
            profile: alphaProfile
        )
        .accessibilityLabel("Animated SWAY dancer demonstrating \(moveID)")
    }
}
