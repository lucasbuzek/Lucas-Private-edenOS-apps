import SwiftUI
import AVFoundation
import Vision

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        if let c = view.previewLayer.connection, c.isVideoMirroringSupported {
            c.automaticallyAdjustsVideoMirroring = false
            c.isVideoMirrored = true
        }
        return view
    }
    func updateUIView(_ view: CameraPreviewUIView, context: Context) {
        view.previewLayer.session = session
        if let c = view.previewLayer.connection, c.isVideoMirroringSupported {
            c.automaticallyAdjustsVideoMirroring = false
            c.isVideoMirrored = true
        }
    }
}

struct PoseOverlay: View {
    let pose: SwayBodyPose
    private var joints: [PoseJoint] { pose.orderedJoints }
    private let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.neck,.nose),(.neck,.leftShoulder),(.leftShoulder,.leftElbow),(.leftElbow,.leftWrist),
        (.neck,.rightShoulder),(.rightShoulder,.rightElbow),(.rightElbow,.rightWrist),
        (.neck,.root),(.root,.leftHip),(.leftHip,.leftKnee),(.leftKnee,.leftAnkle),
        (.root,.rightHip),(.rightHip,.rightKnee),(.rightKnee,.rightAnkle)
    ]
    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let map = Dictionary(uniqueKeysWithValues: joints.map { ($0.name, $0) })
                for (a,b) in bones {
                    guard let p1 = map[a], let p2 = map[b] else { continue }
                    var path = Path()
                    path.move(to: CGPoint(x:p1.point.x*size.width, y:p1.point.y*size.height))
                    path.addLine(to: CGPoint(x:p2.point.x*size.width, y:p2.point.y*size.height))
                    context.stroke(path, with: .color(.cyan), lineWidth: 4)
                }
                for joint in joints {
                    let p = CGPoint(x:joint.point.x*size.width, y:joint.point.y*size.height)
                    context.fill(Path(ellipseIn:CGRect(x:p.x-5,y:p.y-5,width:10,height:10)), with:.color(.green))
                }
            }
        }.allowsHitTesting(false)
    }
}


/// Unified camera + YOU surface. The same AVFoundation preview transform maps Vision
/// capture-device coordinates into stage coordinates, so aspect-fill cropping and
/// front-camera mirroring cannot drift away from the pose overlay.
final class CameraTrackingStageUIView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()
    let bonesLayer = CAShapeLayer()
    let jointsLayer = CAShapeLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.opacity = 0.14
        layer.addSublayer(previewLayer)
        bonesLayer.fillColor = UIColor.clear.cgColor
        bonesLayer.strokeColor = UIColor.systemCyan.cgColor
        bonesLayer.lineWidth = 5
        bonesLayer.lineCap = .round
        bonesLayer.lineJoin = .round
        jointsLayer.fillColor = UIColor.systemGreen.cgColor
        layer.addSublayer(bonesLayer); layer.addSublayer(jointsLayer)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews(); previewLayer.frame = bounds
        bonesLayer.frame = bounds; jointsLayer.frame = bounds
    }
    func configure(session: AVCaptureSession, pose: SwayBodyPose, showPose: Bool, previewOpacity: Float) {
        previewLayer.opacity = previewOpacity
        if previewLayer.session !== session { previewLayer.session = session }
        if let c=previewLayer.connection, c.isVideoMirroringSupported {
            c.automaticallyAdjustsVideoMirroring=false; c.isVideoMirrored=true
        }
        guard showPose else { bonesLayer.path=nil; jointsLayer.path=nil; return }
        let map=pose.joints
        let bones:[(VNHumanBodyPoseObservation.JointName,VNHumanBodyPoseObservation.JointName)] = [
            (.neck,.nose),(.neck,.leftShoulder),(.leftShoulder,.leftElbow),(.leftElbow,.leftWrist),
            (.neck,.rightShoulder),(.rightShoulder,.rightElbow),(.rightElbow,.rightWrist),
            (.neck,.root),(.root,.leftHip),(.leftHip,.leftKnee),(.leftKnee,.leftAnkle),
            (.root,.rightHip),(.rightHip,.rightKnee),(.rightKnee,.rightAnkle)
        ]
        func stagePoint(_ j: PoseJoint)->CGPoint {
            // Single presentation authority: AVCaptureVideoPreviewLayer already knows the
            // active session format, portrait orientation, front-camera mirroring and
            // resizeAspectFill crop. Vision points are normalized into top-left display
            // coordinates by CameraPoseService, so pass them directly as capture-device
            // points instead of guessing a 9:16 sensor aspect ratio.
            previewLayer.layerPointConverted(fromCaptureDevicePoint: j.point)
        }
        let bp=CGMutablePath()
        for (a,b) in bones { guard let aa=map[a],let bb=map[b] else{continue}; bp.move(to:stagePoint(aa)); bp.addLine(to:stagePoint(bb)) }
        bonesLayer.path=bp
        let jp=CGMutablePath()
        for j in map.values { let q=stagePoint(j), r:CGFloat=5; jp.addEllipse(in:CGRect(x:q.x-r,y:q.y-r,width:r*2,height:r*2)) }
        jointsLayer.path=jp
    }
}

struct CameraTrackingStage: UIViewRepresentable {
    let session: AVCaptureSession
    let pose: SwayBodyPose
    let showPose: Bool
    var previewOpacity: Float = 0.14
    func makeUIView(context: Context)->CameraTrackingStageUIView { CameraTrackingStageUIView() }
    func updateUIView(_ view: CameraTrackingStageUIView, context: Context) { view.configure(session:session,pose:pose,showPose:showPose,previewOpacity:previewOpacity) }
}

struct CameraLabView: View {
    @StateObject private var pose = CameraPoseService()
    @State private var running = false
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                CameraPreview(session: pose.session).background(.black)
                PoseOverlay(pose: pose.bodyPose)
                VStack(alignment:.leading, spacing:4) {
                    Text(pose.personTrackingState.rawValue).bold()
                    Text(pose.faceDetected ? "Head/face present" : "Head/face searching")
                        .font(.caption)
                    Text("Energy \(Int(pose.engagement.observableEnergy*100))% · continuity \(Int(pose.engagement.continuity*100))%")
                        .font(.caption.monospacedDigit())
                    Text("\(pose.joints.count) joints  •  \(Int(pose.averageConfidence*100))%  •  \(Int(pose.framesPerSecond)) FPS")
                        .font(.caption.monospacedDigit())
                }.padding(10).background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius:10)).padding()
            }
            .clipShape(RoundedRectangle(cornerRadius:18))
            .aspectRatio(3/4, contentMode:.fit)

            VStack(spacing:4) {
                Text(pose.readiness.message).font(.headline)
                Text(pose.cameraStatus).font(.footnote).foregroundStyle(.secondary)
                if pose.bodyDetected {
                    HStack(spacing:12) {
                        Label(pose.readiness.upperBodyVisible ? "Upper body" : "Upper body partial",
                              systemImage:pose.readiness.upperBodyVisible ? "checkmark.circle.fill":"circle.dashed")
                        Label(pose.readiness.feetVisible ? "Feet" : "Feet optional",
                              systemImage:pose.readiness.feetVisible ? "checkmark.circle.fill":"circle.dashed")
                    }.font(.caption).foregroundStyle(.secondary)
                }
            }
            Button(running ? "Stop Camera" : "Start Camera") {
                if running { pose.stop(); running = false }
                else { running = true; Task { await pose.requestAndStart() } }
            }.buttonStyle(.borderedProminent)
            Text("Camera Lab: live front camera + on-device Vision body/head geometry. SWAY measures observable movement, not identity or emotion. Frames are not saved or uploaded.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Camera Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { pose.stop() }
    }
}


enum SwayCalibrationStep:Int,CaseIterable {
    case frame, waveLeft, waveRight, liftLeft, liftRight, jump, ready
    var title:String { switch self {
    case .frame:return "STEP INTO VIEW"; case .waveLeft:return "WAVE LEFT"; case .waveRight:return "WAVE RIGHT"
    case .liftLeft:return "LIFT LEFT FOOT"; case .liftRight:return "LIFT RIGHT FOOT"; case .jump:return "AND… JUMP!"; case .ready:return "READY TO SWAY"
    }}
    var symbol:String { switch self { case .frame:return "person.crop.rectangle"; case .waveLeft,.waveRight:return "hand.wave.fill"; case .liftLeft,.liftRight:return "shoeprints.fill"; case .jump:return "figure.jumprope"; case .ready:return "checkmark.circle.fill" } }
}

struct CameraTrackingSetupView: View {
    @EnvironmentObject var store:SwayStore
    @ObservedObject var pose:CameraPoseService
    var onCompleted:(()->Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var step:SwayCalibrationStep = .frame
    @State private var baselineRootY:CGFloat?
    @State private var previousWrist:CGPoint?
    @State private var motionScore:CGFloat=0
    @State private var stableFrames=0
    @State private var status="Finding you…"

    var body: some View {
        ZStack {
            SwayTheme.stageGradient.ignoresSafeArea()
            VStack(spacing:16) {
                HStack { Text("TRACKING SETUP").font(.caption.bold()).tracking(1.5); Spacer(); Text("\(min(step.rawValue+1,6)) / 6").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
                HStack(spacing:10) {
                    ZStack(alignment:.bottom) {
                        LinearGradient(colors:[SwayTheme.violet.opacity(0.35),.black],startPoint:.top,endPoint:.bottom)
                        SwayGraphicalCoachView(moveID:calibrationMove,count:max(1,step.rawValue),waiting:false)
                            .padding(4)
                        Text("COACH").font(.caption.bold()).padding(.horizontal,10).padding(.vertical,5).background(.black.opacity(0.55),in:Capsule()).padding(8)
                    }
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                    .clipShape(RoundedRectangle(cornerRadius:24,style:.continuous))
                    ZStack(alignment:.bottom) {
                        Color.black.opacity(0.72)
                        CameraTrackingStage(session:pose.session,pose:pose.bodyPose,showPose:pose.personTrackingState.isTracking,previewOpacity:1.0)
                        VStack(spacing:4) {
                            Spacer()
                            Label(pose.personTrackingState.isTracking ? "YOU READY":"FINDING YOU",systemImage:pose.personTrackingState.isTracking ? "checkmark.circle.fill":"viewfinder")
                                .font(.caption.bold()).foregroundStyle(pose.personTrackingState.isTracking ? SwayTheme.lime:.white)
                                .padding(.horizontal,9).padding(.vertical,5).background(.black.opacity(0.58),in:Capsule())
                            Text("CAMERA + YOU").font(.caption2.bold()).foregroundStyle(.secondary)
                        }.padding(8)
                    }
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                    .clipShape(RoundedRectangle(cornerRadius:24,style:.continuous))
                    .overlay(RoundedRectangle(cornerRadius:24).stroke(pose.personTrackingState.isTracking ? SwayTheme.lime.opacity(0.55):SwayTheme.cyan.opacity(0.25),lineWidth:1))
                }
                .frame(maxHeight:430)
                .aspectRatio(0.92,contentMode:.fit)
                VStack(spacing:8) {
                    Image(systemName:step.symbol).font(.system(size:34,weight:.semibold)).foregroundStyle(step == .ready ? SwayTheme.lime:SwayTheme.cyan)
                    Text(step.title).font(.system(size:34,design:.rounded)).bold().minimumScaleFactor(0.72).multilineTextAlignment(.center)
                    Text(status).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.frame(minHeight:100)
                if step == .jump {
                    Button("NO JUMP / LOW IMPACT") { store.lowImpact=true; completeCurrent("Low-impact calibration ✓") }.buttonStyle(.bordered)
                }
                if step == .ready {
                    Button("USE TRACKING") { onCompleted?(); dismiss() }.buttonStyle(SwayPrimaryButtonStyle())
                } else {
                    HStack(spacing:6) { ForEach(0..<6,id:\.self){i in Capsule().fill(i < step.rawValue ? SwayTheme.lime : (i == step.rawValue ? SwayTheme.cyan:Color.white.opacity(0.15))).frame(height:5) } }
                }
            }.padding(20).foregroundStyle(.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await pose.requestAndStart() }
        .onChange(of:pose.frameSequence){_,_ in evaluateFrame()}
        .onDisappear { if step != .ready { pose.stop() } }
    }

    private var calibrationMove:String { switch step { case .waveLeft,.waveRight:return "arm-reach"; case .liftLeft,.liftRight:return "knee"; case .jump:return "v-step"; default:return "march" } }
    private var calibrationPhase:TimeInterval { switch step { case .waveLeft:return 0.15; case .waveRight:return 0.65; case .liftLeft:return 0.18; case .liftRight:return 0.68; case .jump:return 0.40; default:return 0.0 } }
    private func joint(_ name:VNHumanBodyPoseObservation.JointName)->PoseJoint? { pose.bodyPose.joints[name] }
    private func requireFullBody()->Bool {
        guard pose.scoringReady else { status = pose.bodyDetected ? "STEP BACK — I NEED TO SEE YOUR WHOLE BODY" : "STEP INTO VIEW"; stableFrames=0; return false }
        return true
    }
    private func evaluateFrame(){
        guard !pose.bodyPose.isEmpty else { status="Move into the camera view"; return }
        let root=joint(.root)?.point
        if baselineRootY == nil, let root { baselineRootY=root.y }
        switch step {
        case .frame:
            if pose.scoringReady { stableFrames += 1; status="PERFECT — HOLD THERE" } else { stableFrames=0; status=pose.bodyDetected ? "STEP BACK — I NEED TO SEE YOUR FEET" : "STEP INTO VIEW" }
            if stableFrames >= 8 { completeCurrent("Body ready ✓") }
        case .waveLeft: guard requireFullBody() else{return}; detectWave(.leftWrist, label:"Left hand")
        case .waveRight: guard requireFullBody() else{return}; detectWave(.rightWrist, label:"Right hand")
        case .liftLeft: guard requireFullBody() else{return}; detectFoot(.leftAnkle,.rightAnkle,label:"Left foot")
        case .liftRight: guard requireFullBody() else{return}; detectFoot(.rightAnkle,.leftAnkle,label:"Right foot")
        case .jump:
            guard requireFullBody() else{return}
            guard let y=root?.y, let base=baselineRootY else{return}
            // Display coordinates: smaller y is higher. Require meaningful whole-body rise.
            if base-y > 0.045 { stableFrames += 1; status="Jump detected!" } else { stableFrames=max(0,stableFrames-1); status="Both feet together — jump when ready" }
            if stableFrames >= 2 { completeCurrent("Jump ✓") }
        case .ready: break
        }
    }
    private func detectWave(_ name:VNHumanBodyPoseObservation.JointName,label:String){
        guard let wrist=joint(name)?.point else { status="Show me your \(label.lowercased())"; return }
        if let old=previousWrist { motionScore += abs(wrist.x-old.x) + abs(wrist.y-old.y) }
        previousWrist=wrist; status="Wave side to side"
        if motionScore > 0.32 { completeCurrent("\(label) ✓") }
    }
    private func detectFoot(_ moving:VNHumanBodyPoseObservation.JointName,_ other:VNHumanBodyPoseObservation.JointName,label:String){
        guard let a=joint(moving)?.point, let b=joint(other)?.point else { status="I need to see both feet"; return }
        if b.y-a.y > 0.055 { stableFrames += 1; status="Hold it…" } else { stableFrames=max(0,stableFrames-1); status="Lift your \(label.lowercased())" }
        if stableFrames >= 4 { completeCurrent("\(label) ✓") }
    }
    private func completeCurrent(_ message:String){
        status=message; store.haptic(.medium); motionScore=0; stableFrames=0; previousWrist=nil
        if let next=SwayCalibrationStep(rawValue:step.rawValue+1) { DispatchQueue.main.asyncAfter(deadline:.now()+0.45){ step=next; status=next == .ready ? "Camera calibrated. Let's dance.":"Show me the move" } }
    }
}

struct CameraTrackingSetupLauncher: View {
    @StateObject private var pose=CameraPoseService()
    var onCompleted:(()->Void)? = nil
    var body: some View { CameraTrackingSetupView(pose:pose,onCompleted:onCompleted).onDisappear { pose.stop() } }
}

