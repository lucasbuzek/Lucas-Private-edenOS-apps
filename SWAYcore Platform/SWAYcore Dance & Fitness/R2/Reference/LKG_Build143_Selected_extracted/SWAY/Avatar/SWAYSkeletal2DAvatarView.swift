import SwiftUI

private struct SWAYDurer2DAsset: Decodable {
    struct Metrics: Decodable { let shoulder, waist, hip, arm, leg: CGFloat }
    struct Customization: Decodable { let bodyTypes, skinTones, faceShapes, hairStyles, hairColours, outfits, footwear, accessories: Int }
    struct Acceptance: Decodable { let legacyPNGProductionPath, sharedCoachUserRig, jointOverlapRequired, stableStageFraming: Bool }
    let format: String
    let version: Int
    let rigID: String
    let layers: [String]
    let joints: [String]
    let bodyMetrics: [String: Metrics]
    let customization: Customization
    let acceptance: Acceptance

    static let alpha: SWAYDurer2DAsset = {
        let candidates = [
            Bundle.main.url(forResource: "SWAY-DURER-2.5D-v1", withExtension: "json", subdirectory: "Avatars/Durer2_5D"),
            Bundle.main.url(forResource: "SWAY-DURER-2.5D-v1", withExtension: "json")
        ]
        guard let url = candidates.compactMap({ $0 }).first,
              let data = try? Data(contentsOf: url),
              let asset = try? JSONDecoder().decode(SWAYDurer2DAsset.self, from: data),
              asset.format == "SWAY-DURER-2.5D", asset.acceptance.sharedCoachUserRig, !asset.acceptance.legacyPNGProductionPath else {
            preconditionFailure("DÜRER 2.5D Alpha runtime asset is missing or invalid")
        }
        return asset
    }()
}

/// SWAY Alpha production illustrated 2.5D character.
/// DÜRER owns geometry/proportion and deformation rules; IRIS/ARTEMIS own appearance.
/// COACH and YOUR DANCER share this renderer and the same musical-time pose contract.
struct SWAYSkeletal2DAvatarView: View {
    enum Role { case coach, user }
    let role: Role
    let moveID: String
    let musicalTime: TimeInterval
    let bpm: Double
    let paused: Bool
    let mirrored: Bool
    var profile: SwayCharacterProfile? = nil

    var body: some View {
        let _ = SWAYDurer2DAsset.alpha
        let pose = illustratedPoseIndex
        Group {
            if role == .coach {
                Image(String(format: "LuciaPose%02d", pose))
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    Image(String(format: "UserPose%02dDetail", pose)).resizable().scaledToFit()
                    Image(String(format: "UserPose%02dSkin", pose)).resizable().scaledToFit().colorMultiply(skinColor)
                    Image(String(format: "UserPose%02dHair", pose)).resizable().scaledToFit().colorMultiply(hairColor)
                    Image(String(format: "UserPose%02dAccent", pose)).resizable().scaledToFit().colorMultiply(outfitColor)
                }
            }
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        .accessibilityLabel(role == .coach ? "Lucia, SWAY coach, illustrated 2.5D" : "Your SWAY dancer, illustrated 2.5D")
        .accessibilityIdentifier(role == .coach ? "sway.avatar.durer2d.coach" : "sway.avatar.durer2d.user")
    }

    /// DÜRER Alpha pose atlas. The visible pixels come from approved illustrated artwork,
    /// never Canvas body primitives. Counts 1...8 deterministically select inspectable poses.
    private var illustratedPoseIndex: Int {
        let beat = musicalTime * max(40, bpm) / 60.0
        let count = max(0, Int(floor(beat + 0.0001))) % 8
        let id = moveID.lowercased().replacingOccurrences(of: "_", with: "-")
        let atlas: [Int]
        if id.contains("march") { atlas = [1, 2, 3, 2, 1, 3, 2, 1] }
        else if id.contains("step-touch") || id.contains("side") { atlas = [1, 4, 5, 4, 1, 5, 4, 1] }
        else if id.contains("knee") { atlas = [1, 6, 7, 6, 1, 7, 6, 1] }
        else if id.contains("grape") { atlas = [1, 5, 4, 8, 1, 4, 5, 8] }
        else if id.contains("squat") { atlas = [1, 8, 8, 1, 1, 8, 8, 1] }
        else if id.contains("jump") { atlas = [1, 9, 10, 9, 1, 10, 9, 1] }
        else if id.contains("reach") { atlas = [1, 9, 10, 9, 1, 10, 9, 1] }
        else if id.contains("sway") || id.contains("roll") { atlas = [1, 11, 12, 11, 1, 12, 11, 1] }
        else { atlas = [1, 4, 5, 6, 7, 8, 9, 10] }
        return atlas[count]
    }

    private func drawCharacter(in c: inout GraphicsContext, size: CGSize, pose p: Pose) {
        let skin = skinColor, hair = hairColor, outfit = outfitColor
        let outline = Color.black.opacity(0.16)
        let scale = min(size.width / 240, size.height / 380)
        let body = bodyMetrics(scale: scale)
        let center = CGPoint(x: size.width * 0.50, y: size.height * 0.44 + p.bob * size.height)
        func P(_ x: CGFloat,_ y: CGFloat)->CGPoint { CGPoint(x:center.x+x*scale,y:center.y+y*scale) }

        let shoulderL=P(-body.shoulder+p.torsoShift,-42), shoulderR=P(body.shoulder+p.torsoShift,-42)
        let hipL=P(-body.hip+p.hipShift,61), hipR=P(body.hip+p.hipShift,61)
        let elbowL=P(-70+p.leftArmX,9+p.leftArmY), elbowR=P(70+p.rightArmX,9+p.rightArmY)
        let handL=P(-79+p.leftHandX,67+p.leftHandY), handR=P(79+p.rightHandX,67+p.rightHandY)
        let kneeL=P(-body.hip-2+p.leftLegX,128+p.leftKneeLift), kneeR=P(body.hip+2+p.rightLegX,128+p.rightKneeLift)
        let ankleL=P(-body.hip-4+p.leftFootX,201+p.leftFootY), ankleR=P(body.hip+4+p.rightFootX,201+p.rightFootY)

        // Back hair and pony/braids establish depth before rear limbs.
        drawBackHair(&c, center:P(0,-105), scale:scale, color:hair)
        softLimb(&c, shoulderL, elbowL, width:body.arm*scale, color:skin, outline:outline)
        softLimb(&c, elbowL, handL, width:(body.arm-4)*scale, color:skin, outline:outline)
        softLimb(&c, hipL, kneeL, width:body.leg*scale, color:lowerGarmentColor, outline:outline)
        softLimb(&c, kneeL, ankleL, width:(body.leg-6)*scale, color:skin, outline:outline)

        // Torso and pelvis deliberately overlap to form one continuous silhouette.
        var torso=Path(); torso.move(to:P(-body.shoulder,-51));
        torso.addCurve(to:P(-body.waist,48),control1:P(-body.shoulder-8,-5),control2:P(-body.waist-4,28))
        torso.addQuadCurve(to:P(0,69),control:P(-body.hip,66)); torso.addQuadCurve(to:P(body.waist,48),control:P(body.hip,66))
        torso.addCurve(to:P(body.shoulder,-51),control1:P(body.waist+4,28),control2:P(body.shoulder+8,-5))
        torso.addQuadCurve(to:P(0,-65),control:P(23,-63)); torso.addQuadCurve(to:P(-body.shoulder,-51),control:P(-23,-63)); torso.closeSubpath()
        c.fill(torso,with:.color(outfit)); c.stroke(torso,with:.color(outline),lineWidth:1.2*scale)
        let pelvisRect=CGRect(x:P(-body.hip-5,43).x,y:P(-body.hip-5,43).y,width:(body.hip*2+10)*scale,height:48*scale)
        c.fill(Path(roundedRect:pelvisRect,cornerRadius:19*scale),with:.color(lowerGarmentColor))

        softLimb(&c, hipR, kneeR, width:body.leg*scale, color:lowerGarmentColor, outline:outline)
        softLimb(&c, kneeR, ankleR, width:(body.leg-6)*scale, color:skin, outline:outline)
        softLimb(&c, shoulderR, elbowR, width:body.arm*scale, color:skin, outline:outline)
        softLimb(&c, elbowR, handR, width:(body.arm-4)*scale, color:skin, outline:outline)

        drawHand(&c, at:handL, scale:scale, skin:skin); drawHand(&c, at:handR, scale:scale, skin:skin)
        drawShoe(&c, at:ankleL, scale:scale, flip:false); drawShoe(&c, at:ankleR, scale:scale, flip:true)

        // Neck is underneath head and torso. Head shape changes with FACE selection.
        c.fill(Path(roundedRect:CGRect(x:P(-14,-79).x,y:P(-14,-79).y,width:28*scale,height:40*scale),cornerRadius:12*scale),with:.color(skin))
        let hc=P(0,-106); let faceRect=faceRect(center:hc,scale:scale)
        c.fill(Path(ellipseIn:faceRect),with:.color(skin)); c.stroke(Path(ellipseIn:faceRect),with:.color(outline),lineWidth:1.2*scale)
        drawFrontHair(&c, center:hc, scale:scale, color:hair)
        drawFace(&c, center:hc, scale:scale)
        drawAccessory(&c, center:hc, leftHand:handL, rightHand:handR, scale:scale)
    }

    private typealias Metrics = SWAYDurer2DAsset.Metrics
    private func bodyMetrics(scale:CGFloat)->Metrics {
        let key = (profile?.bodyStyle ?? .neutral).rawValue.lowercased()
        guard let metrics = SWAYDurer2DAsset.alpha.bodyMetrics[key] else {
            preconditionFailure("DÜRER asset has no metrics for \(key)")
        }
        return metrics
    }

    private func softLimb(_ c:inout GraphicsContext,_ a:CGPoint,_ b:CGPoint,width:CGFloat,color:Color,outline:Color){
        // DÜRER tapered limb: a soft quadrilateral silhouette instead of a uniform stick.
        // This preserves joint overlap while giving the illustrated avatar anatomical taper.
        let dx = b.x - a.x, dy = b.y - a.y
        let length = max(0.001, sqrt(dx * dx + dy * dy))
        let nx = -dy / length, ny = dx / length
        let proximal = width * 0.52, distal = width * 0.39
        var limb = Path()
        limb.move(to: CGPoint(x:a.x + nx * proximal, y:a.y + ny * proximal))
        limb.addQuadCurve(to: CGPoint(x:b.x + nx * distal, y:b.y + ny * distal), control: CGPoint(x:(a.x+b.x)/2 + nx*width*0.48, y:(a.y+b.y)/2 + ny*width*0.48))
        limb.addQuadCurve(to: CGPoint(x:b.x - nx * distal, y:b.y - ny * distal), control: CGPoint(x:b.x + dx/length*width*0.16, y:b.y + dy/length*width*0.16))
        limb.addQuadCurve(to: CGPoint(x:a.x - nx * proximal, y:a.y - ny * proximal), control: CGPoint(x:(a.x+b.x)/2 - nx*width*0.48, y:(a.y+b.y)/2 - ny*width*0.48))
        limb.addQuadCurve(to: CGPoint(x:a.x + nx * proximal, y:a.y + ny * proximal), control: CGPoint(x:a.x - dx/length*width*0.12, y:a.y - dy/length*width*0.12))
        limb.closeSubpath()
        c.fill(limb,with:.color(color)); c.stroke(limb,with:.color(outline),lineWidth:1.15)
        c.fill(Path(ellipseIn:CGRect(x:b.x-distal,y:b.y-distal,width:distal*2,height:distal*2)),with:.color(color))
    }
    private func drawHand(_ c:inout GraphicsContext,at p:CGPoint,scale:CGFloat,skin:Color){ c.fill(Path(ellipseIn:CGRect(x:p.x-13*scale,y:p.y-13*scale,width:26*scale,height:27*scale)),with:.color(skin)) }

    private func drawShoe(_ c:inout GraphicsContext,at p:CGPoint,scale:CGFloat,flip:Bool){
        let style=profile?.footwearStyle ?? 0; let w:[CGFloat]=[43,46,45,40]; let h:[CGFloat]=[20,25,18,17]
        let i=max(0,min(3,style)); let x=p.x-(flip ? 8:CGFloat(w[i]-8))*scale
        let r=CGRect(x:x,y:p.y-(h[i]*0.18)*scale,width:w[i]*scale,height:h[i]*scale)
        let color = i == 1 ? outfitColor.opacity(0.92) : Color.white.opacity(0.97)
        c.fill(Path(roundedRect:r,cornerRadius:(i == 1 ? 7:9)*scale),with:.color(color)); c.stroke(Path(roundedRect:r,cornerRadius:8*scale),with:.color(.black.opacity(0.18)),lineWidth:1.1*scale)
    }

    private func faceRect(center:CGPoint,scale:CGFloat)->CGRect {
        switch profile?.faceShape ?? 0 {
        case 1: return CGRect(x:center.x-39*scale,y:center.y-52*scale,width:78*scale,height:104*scale)
        case 2: return CGRect(x:center.x-42*scale,y:center.y-48*scale,width:84*scale,height:96*scale)
        default:return CGRect(x:center.x-43*scale,y:center.y-50*scale,width:86*scale,height:100*scale)
        }
    }
    private func drawFace(_ c:inout GraphicsContext,center h:CGPoint,scale:CGFloat){
        let eyeY=h.y-3*scale
        for dx:CGFloat in [-18,18] { c.fill(Path(ellipseIn:CGRect(x:h.x+(dx-3)*scale,y:eyeY-3*scale,width:6*scale,height:7*scale)),with:.color(.black.opacity(0.78))) }
        var nose=Path(); nose.move(to:CGPoint(x:h.x,y:h.y+2*scale)); nose.addLine(to:CGPoint(x:h.x-3*scale,y:h.y+12*scale)); c.stroke(nose,with:.color(.black.opacity(0.14)),lineWidth:1.2*scale)
        var smile=Path(); smile.move(to:CGPoint(x:h.x-13*scale,y:h.y+22*scale)); smile.addQuadCurve(to:CGPoint(x:h.x+13*scale,y:h.y+22*scale),control:CGPoint(x:h.x,y:h.y+31*scale)); c.stroke(smile,with:.color(Color(red:0.55,green:0.16,blue:0.20)),style:StrokeStyle(lineWidth:2.2*scale,lineCap:.round))
    }

    private func drawBackHair(_ c:inout GraphicsContext,center h:CGPoint,scale:CGFloat,color:Color){
        let style=profile?.hairStyle ?? 0
        c.fill(Path(ellipseIn:CGRect(x:h.x-43*scale,y:h.y-52*scale,width:86*scale,height:(style == 2 ? 75:106)*scale)),with:.color(color.opacity(0.96)))
        if style == 0 { c.fill(Path(ellipseIn:CGRect(x:h.x+28*scale,y:h.y-18*scale,width:30*scale,height:78*scale)),with:.color(color)) }
        if style == 1 { for dx:CGFloat in [-33,33] { c.fill(Path(roundedRect:CGRect(x:h.x+(dx-5)*scale,y:h.y-8*scale,width:10*scale,height:93*scale),cornerRadius:5*scale),with:.color(color)) } }
        if style == 3 { for dx:CGFloat in [-32,-16,0,16,32] { c.fill(Path(ellipseIn:CGRect(x:h.x+(dx-15)*scale,y:h.y-45*scale,width:30*scale,height:38*scale)),with:.color(color)) } }
    }
    private func drawFrontHair(_ c:inout GraphicsContext,center h:CGPoint,scale:CGFloat,color:Color){
        let style=profile?.hairStyle ?? 0
        if style == 4 { // cap
            c.fill(Path(ellipseIn:CGRect(x:h.x-44*scale,y:h.y-52*scale,width:88*scale,height:44*scale)),with:.color(outfitColor)); c.fill(Path(roundedRect:CGRect(x:h.x+20*scale,y:h.y-23*scale,width:31*scale,height:8*scale),cornerRadius:4*scale),with:.color(outfitColor))
        } else {
            var crown=Path(); crown.move(to:CGPoint(x:h.x-40*scale,y:h.y-21*scale)); crown.addCurve(to:CGPoint(x:h.x+39*scale,y:h.y-21*scale),control1:CGPoint(x:h.x-26*scale,y:h.y-67*scale),control2:CGPoint(x:h.x+27*scale,y:h.y-66*scale)); crown.addQuadCurve(to:CGPoint(x:h.x+29*scale,y:h.y+1*scale),control:CGPoint(x:h.x+45*scale,y:h.y-8*scale)); crown.addQuadCurve(to:CGPoint(x:h.x-40*scale,y:h.y-21*scale),control:CGPoint(x:h.x-4*scale,y:h.y-8*scale)); crown.closeSubpath(); c.fill(crown,with:.color(color))
        }
    }
    private func drawAccessory(_ c:inout GraphicsContext,center h:CGPoint,leftHand:CGPoint,rightHand:CGPoint,scale:CGFloat){
        switch profile?.accessoryStyle ?? 0 {
        case 1: c.stroke(Path(roundedRect:CGRect(x:h.x-39*scale,y:h.y-20*scale,width:78*scale,height:10*scale),cornerRadius:5*scale),with:.color(outfitColor),lineWidth:5*scale)
        case 2: for p in [leftHand,rightHand] { c.stroke(Path(ellipseIn:CGRect(x:p.x-12*scale,y:p.y-12*scale,width:24*scale,height:24*scale)),with:.color(outfitColor),lineWidth:4*scale) }
        case 3:
            for dx:CGFloat in [-17,17] { c.stroke(Path(ellipseIn:CGRect(x:h.x+(dx-11)*scale,y:h.y-9*scale,width:22*scale,height:16*scale)),with:.color(.black.opacity(0.75)),lineWidth:2*scale) }
            var bridge=Path(); bridge.move(to:CGPoint(x:h.x-6*scale,y:h.y-1*scale)); bridge.addLine(to:CGPoint(x:h.x+6*scale,y:h.y-1*scale)); c.stroke(bridge,with:.color(.black.opacity(0.75)),lineWidth:2*scale)
        default: break
        }
    }

    private var skinColor:Color { let i=profile?.skinTone ?? (role == .coach ? 1:2); return [Color(red:0.98,green:0.79,blue:0.67),Color(red:0.86,green:0.62,blue:0.46),Color(red:0.68,green:0.43,blue:0.30),Color(red:0.47,green:0.28,blue:0.20),Color(red:0.31,green:0.18,blue:0.14)][max(0,min(4,i))] }
    private var hairColor:Color { let i=profile?.hairColor ?? 1; return [Color(red:0.16,green:0.08,blue:0.05),Color(red:0.27,green:0.13,blue:0.07),.black,Color(red:0.38,green:0.12,blue:0.08),Color(red:0.64,green:0.28,blue:0.12),Color(red:0.73,green:0.57,blue:0.30)][max(0,min(5,i))] }
    private var outfitColor:Color { let i=profile?.outfitStyle ?? 0; return [Color(red:0.82,green:0.12,blue:0.48),Color(red:0.14,green:0.65,blue:0.78),Color(red:0.48,green:0.31,blue:0.86),Color(red:0.95,green:0.48,blue:0.17),Color(red:0.12,green:0.72,blue:0.47)][max(0,min(4,i))] }
    private var lowerGarmentColor:Color { outfitColor.opacity((profile?.outfitStyle ?? 0) == 2 ? 0.72:0.88) }

    private struct Pose {
        var bob:CGFloat=0, hipShift:CGFloat=0, torsoShift:CGFloat=0
        var leftLegX:CGFloat=0,rightLegX:CGFloat=0,leftKneeLift:CGFloat=0,rightKneeLift:CGFloat=0,leftFootX:CGFloat=0,rightFootX:CGFloat=0,leftFootY:CGFloat=0,rightFootY:CGFloat=0
        var leftArmX:CGFloat=0,rightArmX:CGFloat=0,leftArmY:CGFloat=0,rightArmY:CGFloat=0,leftHandX:CGFloat=0,rightHandX:CGFloat=0,leftHandY:CGFloat=0,rightHandY:CGFloat=0
        static func sample(moveID:String,time:TimeInterval,bpm:Double)->Pose {
            let beat = time * max(40, bpm) / 60
            // One 8-count phrase is one complete motion cycle. Integer beat positions are
            // intentionally distinct so Learn can seek exactly to counts 1...8.
            let phase = (beat.truncatingRemainder(dividingBy: 8.0) / 8.0) * 2.0 * Double.pi + Double.pi / 2.0
            let s = CGFloat(sin(phase)), c = CGFloat(cos(phase)), a = abs(s)
            var p=Pose(); p.bob=a*0.005
            let id=moveID.lowercased().replacingOccurrences(of:"_",with:"-")
            if id.contains("march") { p.leftKneeLift=s>0 ? -50*a:0; p.rightKneeLift=s<0 ? -50*a:0; p.leftArmX = -17*s; p.rightArmX=17*s; p.leftHandY = -23*s; p.rightHandY=23*s }
            else if id.contains("step-touch") || id.contains("side-tap") || id.contains("double-step") { p.hipShift=20*s; p.torsoShift=9*s; p.leftFootX = -27*max(0,s); p.rightFootX=27*max(0,-s); p.leftArmX = -12*c; p.rightArmX=12*c }
            else if id.contains("knee") { p.leftKneeLift = -64*max(0,s); p.rightKneeLift = -64*max(0,-s); p.leftHandY = -24*a; p.rightHandY = -24*a; p.leftArmX=10*s; p.rightArmX = -10*s }
            else if id.contains("grape") { p.hipShift=25*s; p.leftFootX=34*s; p.rightFootX = -21*s; p.torsoShift=9*s; p.leftArmX = -12*s; p.rightArmX=12*s }
            else if id.contains("squat") { p.leftKneeLift=18*a; p.rightKneeLift=18*a; p.leftFootX = -12; p.rightFootX=12; p.bob=0.045*a; p.leftHandY = -18*a; p.rightHandY = -18*a }
            else if id.contains("jump") { p.leftFootX = -28*a; p.rightFootX=28*a; p.leftArmX = -24*a; p.rightArmX=24*a; p.leftHandY = -75*a; p.rightHandY = -75*a }
            else if id.contains("reach") { p.leftHandY = -70*max(0,s); p.rightHandY = -70*max(0,-s); p.leftArmX = -15*a; p.rightArmX=15*a }
            else if id.contains("sway") || id.contains("roll") { p.hipShift=18*s; p.torsoShift = -12*s; p.leftArmX = -8*c; p.rightArmX=8*c }
            else if id.contains("v-step") { p.leftFootX = -24*max(0,s); p.rightFootX=24*max(0,-s); p.leftHandY = -20*a; p.rightHandY = -20*a }
            else { p.hipShift=8*s; p.leftArmX = -8*s; p.rightArmX=8*s }
            return p
        }
    }
}
