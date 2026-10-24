import SwiftUI
import AVFoundation
import SWAYcoreEngine

@main
struct EngineZEROApp: App {
    var body: some Scene {
        WindowGroup { EngineZERORoot() }
    }
}

/// Independent, intentionally minimal host for the existing SWAYcore pose engine.
/// Nothing here changes the Dance & Fitness app, its project or its release gates.
struct EngineZERORoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("SWAYcore.EngineZERO.onboarded") private var onboarded = false
    @StateObject private var camera = ZEROCamera()
    @State private var onboardingPage = 0
    @State private var moveID = "march"
    @State private var bpm = 120.0
    @State private var mirrored = false
    @State private var playing = true
    @State private var elapsedBeforePause: TimeInterval = 0
    @State private var startedAt = Date()
    @State private var cameraRequested = false
    @State private var cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var calibration = SwayCalibrationMachine()
    @State private var calibrationActive = false
    @State private var showGuide = false

    private let moves = ["grapevine", "mambo", "cha-cha", "salsa-basic", "jazz-square"]
    private var elapsed: TimeInterval {
        elapsedBeforePause + (playing ? max(0, Date().timeIntervalSince(startedAt)) : 0)
    }
    private var authorization: AVAuthorizationStatus { cameraAuthorization }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.04, blue: 0.18),
                         Color(red: 0.04, green: 0.10, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            if !onboarded {
                onboarding
            } else {
                liveSurface
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { camera.stop() }
            if phase == .active {
                cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
                if cameraRequested { Task { await camera.start() } }
            }
        }
        .onReceive(camera.$joints) { joints in
            guard calibrationActive, cameraRequested, cameraAuthorization == .authorized else { return }
            func point(_ name: String) -> SwayPoint? {
                guard let p = joints[name] else { return nil }
                return SwayPoint(x: Double(p.x), y: Double(p.y))
            }
            let ready = ["root", "neck", "leftAnkle", "rightAnkle"].allSatisfy { joints[$0] != nil }
            let frame = SwayCalibrationFrame(
                timestamp: CACurrentMediaTime(), bodyPresent: !joints.isEmpty,
                scoringReady: ready, root: point("root"),
                leftWrist: point("leftWrist"), rightWrist: point("rightWrist"),
                leftAnkle: point("leftAnkle"), rightAnkle: point("rightAnkle"))
            _ = calibration.ingest(frame)
            if calibration.isReady { calibrationActive = false }
        }
    }

    private var onboarding: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 10)
            Text("SWAYcore SWAYZ").font(.system(size: 33, weight: .bold, design: .rounded))
            Text("SWAYZ · ZERO").font(.caption.weight(.semibold))
                .tracking(4).foregroundStyle(.cyan)

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.white.opacity(0.065))
                ZEROStickManView(moveID: "march", musicalTime: 0.35,
                                 bpm: 120, mirrored: false)
                    .padding(26)
            }
            .frame(height: 245)

            VStack(spacing: 11) {
                Text(["Movement comes first",
                      "Camera tracking is optional",
                      "Private by default"][onboardingPage])
                    .font(.title2.bold())
                Text([
                    "Engine ZERO uses the existing SWAYcore movement definitions and animated stick-man, without requiring production avatars.",
                    "With your permission, the front camera detects your body joints and draws a live skeleton. You can also use the animated coach without a camera.",
                    "Camera analysis runs on your iPhone. ZERO does not record or upload camera video. You can turn tracking off at any time."
                ][onboardingPage])
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 125)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(i == onboardingPage ? Color.cyan : Color.white.opacity(0.22))
                        .frame(width: i == onboardingPage ? 32 : 10, height: 5)
                }
            }
            if onboardingPage < 2 {
                Button("Continue") { onboardingPage += 1 }
                    .buttonStyle(ZEROPrimaryButtonStyle())
            } else {
                Button("Start with Camera") {
                    onboarded = true
                    beginCamera()
                }
                .buttonStyle(ZEROPrimaryButtonStyle())
                Button("Start without Camera") { onboarded = true }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 9)
            }
            Spacer(minLength: 12)
        }
        .padding(24)
    }

    private var liveSurface: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SWAYcore SWAYZ").font(.title2.bold())
                        Text("SWAYZ · PROFESSIONAL MOVE PREVIEW")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.8).foregroundStyle(.cyan)
                    }
                    Spacer()
                    Button { showGuide = true } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                    }
                    .accessibilityLabel("Open help")
                }
                HStack(spacing: 8) {
                    Label("COACH · ZERO", systemImage: "figure.dance")
                        .font(.caption.bold())
                    Spacer()
                    Text(playing ? "ANIMATING" : "PAUSED")
                        .font(.caption2.monospaced())
                        .foregroundStyle(playing ? .green : .orange)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.white.opacity(0.055))
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !playing)) { _ in
                        ZEROStickManView(moveID: moveID, musicalTime: elapsed,
                                         bpm: bpm, mirrored: mirrored)
                            .padding(12)
                    }
                }
                .frame(height: 245)
                .accessibilityLabel("Animated ZERO stick figure performing \(moveID)")

                VStack(spacing: 12) {
                    Picker("Move", selection: $moveID) {
                        ForEach(moves, id: \.self) { item in
                            Text(item.replacingOccurrences(of: "-", with: " ").capitalized)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    HStack {
                        Button {
                            if playing {
                                elapsedBeforePause = elapsed
                            } else {
                                startedAt = Date()
                            }
                            playing.toggle()
                        } label: {
                            Label(playing ? "Pause" : "Play",
                                  systemImage: playing ? "pause.fill" : "play.fill")
                        }
                        Spacer()
                        Button {
                            elapsedBeforePause = 0
                            startedAt = Date()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        Spacer()
                        Toggle("Mirror", isOn: $mirrored)
                            .labelsHidden()
                            .accessibilityLabel("Mirror coach")
                    }
                    HStack {
                        Text("Tempo").font(.subheadline)
                        Slider(value: $bpm, in: 60...180, step: 5)
                            .accessibilityLabel("Tempo")
                        Text("\(Int(bpm)) BPM")
                            .font(.caption.monospacedDigit())
                            .frame(width: 75, alignment: .trailing)
                    }
                }
                .padding(14)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))

                HStack {
                    Label("YOU · CAMERA", systemImage: "camera.viewfinder")
                        .font(.caption.bold())
                    Spacer()
                    Text(camera.status)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .font(.caption2.monospaced())
                        .foregroundStyle(camera.joints.isEmpty ? .orange : .green)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(.black.opacity(0.45))
                    if cameraRequested && authorization == .authorized {
                        ZEROCameraStage(session: camera.session, joints: camera.joints)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "camera")
                                .font(.system(size: 36))
                                .foregroundStyle(.cyan)
                            Text(cameraMessage)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(height: 230)

                if cameraRequested && authorization == .authorized {
                    if calibrationActive {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("MOVEMENT SETUP").font(.caption.weight(.bold))
                                Spacer()
                                Text("\(min(calibration.completed.count + 1, 6)) / 6")
                                    .font(.caption.monospaced())
                            }
                            Text(calibration.stage.title).font(.headline)
                            Text(calibration.status).font(.caption).foregroundStyle(.cyan)
                            HStack {
                                Button("Restart") { calibration.restart() }
                                Spacer()
                                if calibration.stage == .jump {
                                    Button("Low-impact: skip jump") { _ = calibration.skipJump() }
                                }
                                Button("Follow Along") { calibrationActive = false }
                            }.font(.caption.weight(.semibold))
                        }
                        .padding(12)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                    } else if calibration.isReady {
                        Label("READY TO SWAY", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline.bold())
                    } else {
                        Button("Calibrate Tracking") { calibration.restart(); calibrationActive = true }
                            .font(.subheadline.weight(.semibold))
                    }
                }

                HStack {
                    Text("Joints: \(camera.joints.count)")
                    Spacer()
                    Text("Confidence: \(Int(camera.confidence * 100))%")
                    Spacer()
                    Text(String(format: "%.0f fps", camera.framesPerSecond))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.78))

                if cameraRequested && authorization == .authorized {
                    Button("Stop Camera") {
                        cameraRequested = false
                        camera.stop()
                    }
                    .buttonStyle(ZEROPrimaryButtonStyle())
                } else if authorization == .denied || authorization == .restricted {
                    Button("Open Camera Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(ZEROPrimaryButtonStyle())
                } else {
                    Button("Enable Camera Tracking") { beginCamera() }
                        .buttonStyle(ZEROPrimaryButtonStyle())
                }

                Text("Offline · On-device Vision · No camera recording")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity)
            }
            .padding(18)
        }
        .sheet(isPresented: $showGuide) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Engine ZERO").font(.title2.bold())
                    Text("The moving stick-man is the minimum COACH renderer. The camera skeleton represents YOU. Both are independent of the production avatar pipeline.")
                    Text("If tracking is disabled or permission is denied, COACH continues animating. To enable tracking after a denial, use Camera Settings.")
                    Text("The existing SWAYcore native movement source is reused here. This test host does not replace Dance & Fitness.")
                    Spacer()
                }
                .padding(24)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showGuide = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var cameraMessage: String {
        switch authorization {
        case .denied: return "Camera access denied. Enable it in Settings."
        case .restricted: return "Camera access restricted on this iPhone."
        default: return "Optional live body tracking.\nNo video is stored or shared."
        }
    }

    private func beginCamera() {
        cameraRequested = true
        if !calibration.isReady && !calibrationActive {
            calibration.restart()
            calibrationActive = true
        }
        Task {
            await camera.start()
            cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }
}

private struct ZEROStickManView: View {
    let moveID: String
    let musicalTime: TimeInterval
    let bpm: Double
    let mirrored: Bool

    var body: some View {
        Canvas { context, size in
            let p = SwayCoachPoseEngine.pose(moveID: moveID,
                                              musicalTime: musicalTime, bpm: bpm)
            func canvasPoint(_ point: CGPoint) -> CGPoint {
                CGPoint(x: (mirrored ? 1 - point.x : point.x) * size.width,
                        y: point.y * size.height)
            }
            let lines: [(CGPoint, CGPoint)] = [
                (p.head, p.neck),
                (p.neck, p.leftShoulder), (p.leftShoulder, p.leftElbow),
                (p.leftElbow, p.leftHand),
                (p.neck, p.rightShoulder), (p.rightShoulder, p.rightElbow),
                (p.rightElbow, p.rightHand),
                (p.neck, p.hip),
                (p.hip, p.leftKnee), (p.leftKnee, p.leftFoot),
                (p.hip, p.rightKnee), (p.rightKnee, p.rightFoot)
            ]
            for (a, b) in lines {
                var path = Path()
                path.move(to: canvasPoint(a))
                path.addLine(to: canvasPoint(b))
                context.stroke(path, with: .color(.cyan),
                               style: StrokeStyle(lineWidth: 6, lineCap: .round))
            }
            let head = canvasPoint(p.head)
            context.stroke(Path(ellipseIn: CGRect(x: head.x - 15, y: head.y - 15,
                                                    width: 30, height: 30)),
                           with: .color(.white), lineWidth: 5)
            for joint in [p.leftShoulder, p.rightShoulder, p.leftElbow,
                          p.rightElbow, p.leftHand, p.rightHand, p.hip,
                          p.leftKnee, p.rightKnee, p.leftFoot, p.rightFoot] {
                let point = canvasPoint(joint)
                context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4,
                                                     width: 8, height: 8)),
                             with: .color(.white))
            }
        }
        .accessibilityLabel("Stick figure showing \(moveID)")
    }
}

private struct ZEROPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.cyan.opacity(configuration.isPressed ? 0.68 : 1),
                        in: RoundedRectangle(cornerRadius: 14))
    }
}
