import SwiftUI
import SWAYcoreKit

/// ZERO-only app-local rendering adapter. Shadows SWAYAppKit.CharacterStageView
/// in this product target without changing the recovered app or the R2 branch.
/// Learn, workout, mirrored poses and YOU all use the original shared Pose.
struct CharacterStageView: View {
    let characterID: String
    let pose: Pose?
    let youCharacterID: String?
    let youPose: Pose?
    let youOpacity: Double
    let hair: String?
    let outfit: String?

    init(characterID: String, pose: Pose?,
         youCharacterID: String? = nil, youPose: Pose? = nil,
         youOpacity: Double = 0.45, hair: String? = nil, outfit: String? = nil) {
        self.characterID = characterID
        self.pose = pose
        self.youCharacterID = youCharacterID
        self.youPose = youPose
        self.youOpacity = youOpacity
        self.hair = hair
        self.outfit = outfit
    }

    private let bones: [(SWAYJoint, SWAYJoint)] = [
        (.head, .neck), (.neck, .chest), (.chest, .spine), (.spine, .hips),
        (.chest, .shoulderL), (.shoulderL, .elbowL), (.elbowL, .wristL), (.wristL, .handL),
        (.chest, .shoulderR), (.shoulderR, .elbowR), (.elbowR, .wristR), (.wristR, .handR),
        (.hips, .hipL), (.hipL, .kneeL), (.kneeL, .ankleL), (.ankleL, .toesL),
        (.hips, .hipR), (.hipR, .kneeR), (.kneeR, .ankleR), (.ankleR, .toesR)
    ]

    var body: some View {
        Canvas { context, size in
            let duo = youCharacterID != nil && youPose != nil
            func draw(_ value: Pose?, color: Color, opacity: Double, centerX: CGFloat, allotted: CGFloat) {
                guard let value, !value.samples.isEmpty else { return }
                let points = SWAYJoint.allCases.compactMap { value.position($0) }
                guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                      let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return }
                let actualWidth = max(0.9, maxX - minX)
                let actualHeight = max(2.1, maxY - minY)
                let zoom = min(allotted * 0.87 / actualWidth,
                               size.height * 0.87 / actualHeight)
                let centerY = (minY + maxY) * 0.5
                let poseCenterX = (minX + maxX) * 0.5
                func position(_ joint: SWAYJoint) -> CGPoint? {
                    guard let v = value.position(joint) else { return nil }
                    return CGPoint(x: centerX + (v.x-poseCenterX)*zoom,
                                   y: size.height*0.5-(v.y-centerY)*zoom)
                }
                var stroke = Path()
                for (a,b) in bones {
                    if let p = position(a), let q = position(b) {
                        stroke.move(to: p)
                        stroke.addLine(to: q)
                    }
                }
                context.stroke(stroke, with: .color(color.opacity(opacity)),
                               style: StrokeStyle(lineWidth: max(3, allotted*0.018),
                                                  lineCap: .round, lineJoin: .round))
                if let h = position(.head) {
                    let radius = max(7, allotted*0.052)
                    let head = Path(ellipseIn: CGRect(x:h.x-radius,y:h.y-radius,
                                                        width:radius*2,height:radius*2))
                    context.fill(head, with: .color(.black.opacity(0.65)))
                    context.stroke(head, with: .color(color.opacity(opacity)), lineWidth: max(2, allotted*0.012))
                }
            }
            let slot = duo ? size.width * 0.5 : size.width
            draw(pose, color: .cyan, opacity: 1,
                 centerX: duo ? size.width * 0.25 : size.width * 0.5,
                 allotted: slot)
            if duo {
                draw(youPose, color: .white, opacity: min(1,max(0,youOpacity)),
                     centerX: size.width * 0.75, allotted: slot)
            }
        }
        .accessibilityLabel("Animated ZERO coach and optional live tracked YOU")
        .accessibilityIdentifier("sway.dancezero.stage")
    }
}