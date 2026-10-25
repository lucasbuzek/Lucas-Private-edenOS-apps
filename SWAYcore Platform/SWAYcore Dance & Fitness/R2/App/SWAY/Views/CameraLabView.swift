import SwiftUI
import AVFoundation
import Vision
import SWAYcoreEngine

@MainActor
final class SwayPreviewRotationController {
    private var coordinator:AVCaptureDevice.RotationCoordinator?
    private var observation:NSKeyValueObservation?
    private var deviceID:String?
    private weak var layer:AVCaptureVideoPreviewLayer?

    func update(layer:AVCaptureVideoPreviewLayer) {
        self.layer=layer
        guard let device=layer.session?.inputs.compactMap({($0 as? AVCaptureDeviceInput)?.device}).first else{return}
        if deviceID != device.uniqueID {
            deviceID=device.uniqueID
            let coordinator=AVCaptureDevice.RotationCoordinator(device:device,previewLayer:layer)
            self.coordinator=coordinator
            let expectedID=device.uniqueID
            observation=coordinator.observe(\.videoRotationAngleForHorizonLevelPreview,options:[.initial,.new]) { [weak self] _,change in
                guard let angle=change.newValue else{return}
                Task { @MainActor [weak self] in
                    guard let self,self.deviceID == expectedID else{return}
                    self.apply(angle)
                }
            }
        }
        if let coordinator { apply(coordinator.videoRotationAngleForHorizonLevelPreview) }
    }
    private func apply(_ angle:CGFloat) {
        guard let connection=layer?.connection,connection.isVideoRotationAngleSupported(angle) else{return}
        connection.videoRotationAngle=angle
    }
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    private let rotation=SwayPreviewRotationController()
    func updateRotation(){rotation.update(layer:previewLayer)}
    override func layoutSubviews(){super.layoutSubviews();updateRotation()}
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.updateRotation()
        if let c = view.previewLayer.connection, c.isVideoMirroringSupported {
            c.automaticallyAdjustsVideoMirroring = false
            c.isVideoMirrored = true
        }
        return view
    }
    func updateUIView(_ view: CameraPreviewUIView, context: Context) {
        view.previewLayer.session = session
        view.updateRotation()
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
    private let rotation=SwayPreviewRotationController()
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
        rotation.update(layer:previewLayer)
    }
    func configure(session: AVCaptureSession, pose: SwayBodyPose, showPose: Bool, previewOpacity: Float) {
        previewLayer.opacity = previewOpacity
        if previewLayer.session !== session { previewLayer.session = session }
        rotation.update(layer:previewLayer)
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


/// Canonical calibration stages live in SWAYcoreEngine (tested state machine). The view only renders and feeds frames.
typealias SwayCalibrationStep = SwayCalibrationStage
extension SwayCalibrationStage {
    var symbol:String { switch self { case .frame:return "person.crop.rectangle"; case .waveLeft,.waveRight:return "hand.wave.fill"; case .liftLeft,.liftRight:return "shoeprints.fill"; case .jump:return "figure.jumprope"; case .ready:return "checkmark.circle.fill" } }
}

struct CameraTrackingSetupView: View {
    @EnvironmentObject var store:SwayStore
    @ObservedObject var pose:CameraPoseService
    var onCompleted:(()->Void)? = nil
    var onCancel:(()->Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var machine = SwayCalibrationMachine()
    @State private var completionSent=false
    @State private var flash:String?

    private var step:SwayCalibrationStep { machine.stage }
    private var status:String { machine.status }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // ONE movement space: camera is a subtle sensor layer, COACH and YOU occupy the same stage.
                CameraTrackingStage(session:pose.session,pose:pose.bodyPose,showPose:false,previewOpacity:0.16)
                    .ignoresSafeArea().allowsHitTesting(false)
                LinearGradient(colors:[.black.opacity(0.20),.clear,.black.opacity(0.72)],startPoint:.top,endPoint:.bottom).ignoresSafeArea()
                SwayGraphicalCoachView(moveID:calibrationMove,count:max(1,step.rawValue),waiting:false)
                    .frame(maxWidth:min(proxy.size.width*0.72,520),maxHeight:proxy.size.height*0.72)
                    .padding(.top,28)
                // Live YOUR DANCER follows Vision joints on the frozen character stage.
                SWAYCharacterStage(character:.yourDancer,
                    source:.tracked(pose.bodyPose,visible:pose.personTrackingState.isTracking),
                    profile:store.character,mirrored:store.mirrored)
                    .frame(maxWidth:min(proxy.size.width*0.72,520),maxHeight:proxy.size.height*0.72)
                    .padding(.top,28)

                VStack(spacing:12) {
                    HStack {
                        Text("SWAY").font(.caption.bold()).tracking(1.2).foregroundStyle(.white.opacity(0.65))
                        Spacer()
                        Button { cancel() } label:{ Image(systemName:"xmark").font(.headline).frame(width:44,height:44).background(.black.opacity(0.40),in:Circle()) }
                            .accessibilityLabel("Turn off movement tracking")
                    }
                    Spacer()
                    VStack(spacing:8) {
                        Image(systemName:step.symbol).font(.title2.bold()).foregroundStyle(step == .ready ? SwayTheme.lime:SwayTheme.cyan)
                        Text(step.title.uppercased()).font(.system(size:28,weight:.heavy,design:.rounded)).minimumScaleFactor(0.72).multilineTextAlignment(.center)
                        Group { if let flash { Text(flash).font(.subheadline.bold()).foregroundStyle(SwayTheme.lime) }
                                else if status.uppercased() != step.title.uppercased() { Text(status).font(.subheadline.bold()).foregroundStyle(.white.opacity(0.78)).multilineTextAlignment(.center) } }
                        HStack(spacing:5) { ForEach(0..<6,id:\.self){ i in Capsule().fill(i < step.rawValue ? SwayTheme.lime : (i == step.rawValue ? SwayTheme.cyan:Color.white.opacity(0.18))).frame(height:4) } }
                            .frame(maxWidth:320)
                        if step == .jump { Button("LOW IMPACT — SKIP JUMP") { store.lowImpact=true; handle(machine.skipJump()) }.buttonStyle(.bordered) }
                        if machine.timedOut {
                            Text("Having trouble? You can keep trying or dance without tracking.").font(.footnote).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8))
                            HStack { Button("KEEP TRYING") { machine.continueAfterTimeout() }.buttonStyle(.borderedProminent)
                                     Button("FOLLOW-ALONG INSTEAD") { cancel() }.buttonStyle(.bordered) }
                        }
                    }
                    .padding(.horizontal,20).padding(.vertical,14)
                    .background(.black.opacity(0.50),in:RoundedRectangle(cornerRadius:22,style:.continuous))
                }.padding(18).foregroundStyle(.white)
            }
            // Orientation/geometry change invalidates positional baselines (jump) and in-progress evidence.
            .onChange(of:proxy.size.width > proxy.size.height){_,_ in machine.geometryChanged()}
        }
        .task { await pose.requestAndStart() }
        .onChange(of:pose.frameSequence){_,_ in evaluateFrame() }
        .onChange(of:pose.geometryRevision){_,_ in machine.geometryChanged() }
        .onChange(of:machine.stage){_,newStage in
            guard newStage == .ready,!completionSent else{return}
            completionSent=true
            DispatchQueue.main.asyncAfter(deadline:.now()+0.65){ if let onCompleted { onCompleted() } else { dismiss() } }
        }
        .onDisappear { if !machine.isReady { pose.stop() } }
    }

    private func cancel(){ _ = machine.cancel(); if let onCancel { onCancel() } else { dismiss() } }
    private var calibrationMove:String { switch step { case .waveLeft,.waveRight:return "arm-reach"; case .liftLeft,.liftRight:return "knee"; case .jump:return "v-step"; default:return "march" } }

    /// Builds one engine frame from the single authoritative SwayBodyPose snapshot (display coordinates) and feeds the state machine.
    private func evaluateFrame(){
        let j=pose.bodyPose.joints
        func p(_ n:VNHumanBodyPoseObservation.JointName)->SwayPoint? { j[n].map{ SwayPoint(x:Double($0.point.x),y:Double($0.point.y)) } }
        let frame=SwayCalibrationFrame(timestamp:ProcessInfo.processInfo.systemUptime,bodyPresent:!pose.bodyPose.isEmpty,scoringReady:pose.scoringReady,
                                       root:p(.root),leftWrist:p(.leftWrist),rightWrist:p(.rightWrist),leftAnkle:p(.leftAnkle),rightAnkle:p(.rightAnkle))
        handle(machine.ingest(frame))
    }
    private func handle(_ events:[SwayCalibrationEvent]){
        for e in events {
            if case .stageCompleted(let done) = e {
                store.haptic(.medium); flash="\(done.title) ✓"
                DispatchQueue.main.asyncAfter(deadline:.now()+0.6){ flash=nil }
            }
        }
    }
}

struct CameraTrackingSetupLauncher: View {
    @StateObject private var pose=CameraPoseService()
    var onCompleted:(()->Void)? = nil
    var body: some View { CameraTrackingSetupView(pose:pose,onCompleted:onCompleted).onDisappear { pose.stop() } }
}
