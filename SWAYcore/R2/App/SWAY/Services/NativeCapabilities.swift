import Foundation
import CoreMotion
import HealthKit
import AVFoundation
import MediaPlayer
import UniformTypeIdentifiers
import Accelerate
import MusicKit
import Vision
import UIKit
import ShazamKit
import CoreHaptics
import SWAYcoreEngine
import AVFAudio
import ReplayKit
import ImageIO

final class MotionService: ObservableObject {
    private let manager = CMMotionManager()
    @Published var cadenceEnergy: Double = 0
    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 0.1
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let a = motion?.userAcceleration else { return }
            self?.cadenceEnergy = abs(a.x) + abs(a.y) + abs(a.z)
        }
    }
    func stop() { manager.stopDeviceMotionUpdates() }
}

final class HealthService {
    let store = HKHealthStore()
    func request() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let read: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.workoutType()]
        let write: Set<HKSampleType> = [HKObjectType.workoutType()]
        try await store.requestAuthorization(toShare: write, read: read)
    }
}


// MARK: - Canonical SWAY timeline + performance model

enum SwayMatchState: String, Codable {
    case good = "GOOD MATCH"
    case partial = "PARTIAL MATCH"
    case notMatched = "NOT MATCHED"
    case unknown = "TRACKING"
}

struct SwayPerformanceSample {
    var timing: Double
    var shape: Double
    var direction: Double
    var range: Double
    var continuity: Double
    var confidence: Double

    var matchState: SwayMatchState {
        if confidence < 0.45 { return .unknown }
        return weightedScore >= 0.72 ? .good : .partial
    }

    var weightedScore: Double {
        guard confidence >= 0.45 else { return 0 }
        return timing * 0.30
             + shape * 0.20
             + direction * 0.15
             + range * 0.10
             + continuity * 0.25
    }
}

struct SwayCameraReadiness {
    var bodyVisible = false
    var feetVisible = false
    var upperBodyVisible = false
    var confidence: Double = 0

    var message: String {
        if !bodyVisible { return "Step into view — keep dancing even without scoring." }
        if confidence < 0.45 { return "Tracking is uncertain — no penalty." }
        if !feetVisible && upperBodyVisible { return "Feet not clear — using upper-body feedback." }
        if feetVisible { return "Camera ready" }
        return "Adjust framing when convenient."
    }
}

@MainActor
final class SwayTimelineEngine: ObservableObject {
    @Published private(set) var beat = 0
    @Published private(set) var count = 1
    @Published private(set) var bar = 0
    @Published private(set) var phrase = 0
    /// Continuous authoritative choreography time. Unlike `beat`, this advances every
    /// engine tick and is what the renderer samples.
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var beatPhase: Double = 0
    @Published private(set) var running = false

    var bpm: Double = 120
    private var task: Task<Void, Never>?
    private var accumulated: TimeInterval = 0
    private var activeGrid: SwayBeatGrid?
    private var songOffset: TimeInterval = 0
    private var startedAt: ContinuousClock.Instant?
    private var pausedAtElapsed: TimeInterval = 0
    private var authoritativeTimeSource: (() -> TimeInterval)?
    var onBeat: (() -> Void)?

    func start(bpm: Double, beatGrid: SwayBeatGrid? = nil, songPosition: TimeInterval = 0, timeSource: (() -> TimeInterval)? = nil) {
        stop(reset: true)
        self.bpm = max(20, bpm)
        accumulated = max(0, songPosition)
        pausedAtElapsed = accumulated
        songOffset = accumulated
        activeGrid = beatGrid
        authoritativeTimeSource=timeSource
        startContinuousClock(from: accumulated)
    }

    /// Update tempo without resetting choreography/session time.
    func updateTempo(_ newBPM: Double) {
        bpm = max(20, newBPM)
        publishMusicalPosition(elapsed)
    }

    /// Install a better beat map without restarting the session. Identity/analysis
    /// improvements must not reset COACH, counts, scoring or workout progress.
    func updateBeatGrid(_ grid: SwayBeatGrid) {
        activeGrid = grid
        bpm = max(20, grid.bpm)
        publishMusicalPosition(elapsed)
    }

    /// Shazam/analysis observations are synchronization anchors, not render clocks.
    /// Small errors are slewed; seeks/new recordings rebase immediately.
    func reanchor(songPosition: TimeInterval) {
        let target = max(0, songPosition)
        let error = target - elapsed
        guard abs(error) > 0.08 else { return }
        let corrected = abs(error) > 1.25 ? target : elapsed + error * 0.35
        startContinuousClock(from: corrected)
    }

    /// Count inspection and Learn tempo changes rebase the existing musical clock.
    /// A paused seek publishes immediately and remains paused at the exact phase.
    func seek(to seconds: TimeInterval) {
        let target=max(0,seconds)
        accumulated=target; pausedAtElapsed=target
        elapsed=target; publishMusicalPosition(target)
        if running { startContinuousClock(from:target) }
    }

    func resume() {
        guard !running else { return }
        startContinuousClock(from: pausedAtElapsed)
    }

    func pause() {
        guard running else { return }
        if let source=authoritativeTimeSource { let time=source(); if time.isFinite && time>=0 { elapsed=time;publishMusicalPosition(time) } }
        pausedAtElapsed = elapsed
        accumulated = elapsed
        running = false
        task?.cancel(); task = nil
        startedAt = nil
    }

    func stop(reset: Bool = false) {
        authoritativeTimeSource=nil
        task?.cancel(); task = nil
        running = false
        startedAt = nil
        pausedAtElapsed = elapsed
        if reset {
            accumulated = 0; pausedAtElapsed = 0; songOffset = 0; activeGrid = nil
            beat = 0; count = 1; bar = 0; phrase = 0; elapsed = 0; beatPhase = 0
        }
    }

    private func startContinuousClock(from offset: TimeInterval) {
        task?.cancel()
        accumulated = max(0, offset)
        pausedAtElapsed = accumulated
        let clock = ContinuousClock()
        let origin = clock.now
        startedAt = origin
        running = true
        publishMusicalPosition(authoritativeTimeSource?() ?? accumulated)
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            var previousBeat = self.beat
            while !Task.isCancelled {
                let duration = origin.duration(to: clock.now)
                let seconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1.0e18
                let now = self.authoritativeTimeSource?() ?? (self.accumulated + max(0, seconds))
                if !now.isFinite || now<0 { try? await Task.sleep(for:.milliseconds(8));continue }
                self.publishMusicalPosition(now)
                if self.beat != previousBeat {
                    previousBeat = self.beat
                    self.onBeat?()
                }
                // Engine clock is time-derived; a missed tick cannot accumulate timing drift.
                try? await Task.sleep(for: .milliseconds(8))
            }
        }
    }

    /// Native transport position of the current eight-count's first beat.
    var currentMovePhraseStartTransportTime:TimeInterval {
        let firstBeat=max(0,beat/8*8)
        if let grid=activeGrid,let last=grid.beats.last {
            if firstBeat<grid.beats.count {return grid.beats[firstBeat]}
            return last+Double(firstBeat-grid.beats.count+1)*SwayTimelineMath.secondsPerBeat(bpm:grid.bpm)
        }
        return Double(firstBeat)*SwayTimelineMath.secondsPerBeat(bpm:bpm)
    }

    /// Beat phase owns authored movement even when analyzed beat intervals are irregular.
    var movementTime:TimeInterval { (Double(beat)+beatPhase)*SwayTimelineMath.secondsPerBeat(bpm:bpm) }
    func movementTime(forTransportTime time:TimeInterval)->TimeInterval {
        let position=SwayTimelineMath.position(time:time,bpm:bpm,gridBeats:activeGrid?.beats,gridBPM:activeGrid?.bpm)
        return (Double(position.beat)+position.beatPhase)*SwayTimelineMath.secondsPerBeat(bpm:bpm)
    }

    private func publishMusicalPosition(_ time: TimeInterval) {
        elapsed = time
        // Pure, tested mapping (SWAYcoreEngine). 20 BPM floor per the Learn contract.
        let p = SwayTimelineMath.position(time: time, bpm: bpm, gridBeats: activeGrid?.beats, gridBPM: activeGrid?.bpm)
        beat = p.beat; count = p.count; bar = p.bar; phrase = p.phrase; beatPhase = p.beatPhase
    }
}

struct PoseJoint: Identifiable {
    let name: VNHumanBodyPoseObservation.JointName
    let point: CGPoint
    let confidence: Float
    var id: String { name.rawValue.rawValue }
}

/// One authoritative normalized YOU pose. Vision writes this model once; overlay,
/// matcher and diagnostics consume the same snapshot. Coordinates use the SWAY
/// display convention (origin top-left, normalized 0...1).
struct SwayBodyPose {
    var timestamp: TimeInterval
    var sequence: UInt64
    var joints: [VNHumanBodyPoseObservation.JointName: PoseJoint]
    var averageConfidence: Float
    static let empty = SwayBodyPose(timestamp: 0, sequence: 0, joints: [:], averageConfidence: 0)
    var orderedJoints: [PoseJoint] { joints.values.sorted { $0.id < $1.id } }
    var isEmpty: Bool { joints.isEmpty }
}


enum SwayPersonTrackingState: String, Codable {
    case searching = "SEARCHING"
    case headAnchor = "TRACKING · HEAD"
    case headAndTorso = "TRACKING · HEAD + TORSO"
    case torsoAnchor = "TRACKING · TORSO"
    case bodyPartial = "TRACKING · PARTIAL"
    case bodyReady = "BODY READY"
    case reacquiring = "REACQUIRING"
    case lost = "STEP INTO VIEW"

    var isTracking: Bool {
        switch self {
        case .headAnchor, .headAndTorso, .torsoAnchor, .bodyPartial, .bodyReady: return true
        case .searching, .reacquiring, .lost: return false
        }
    }
}

struct SwayEngagementSample: Codable, Equatable {
    var timestamp: TimeInterval
    var personVisible: Bool
    var bodyConfidence: Double
    var headMotion: Double
    var bodyMotion: Double
    var continuity: Double
    var observableEnergy: Double
    var detectorConfidence: Double
}

/// Positive-engagement model. It deliberately measures observable movement and continuity,
/// not emotion, identity, attractiveness, facial expression, or mental/health state.
struct SwayEngagementEngine {
    private(set) var previousHeadCenter: CGPoint?
    private(set) var previousBodyCenter: CGPoint?
    private(set) var movingFrames = 0
    private(set) var observedFrames = 0

    mutating func sample(faceBox: CGRect?, joints: [PoseJoint], confidence: Double, timestamp: TimeInterval) -> SwayEngagementSample {
        let head = faceBox.map { CGPoint(x:$0.midX,y:$0.midY) }
        let body: CGPoint? = joints.isEmpty ? nil : CGPoint(
            x:joints.map{$0.point.x}.reduce(0,+)/CGFloat(joints.count),
            y:joints.map{$0.point.y}.reduce(0,+)/CGFloat(joints.count))
        func distance(_ a:CGPoint?,_ b:CGPoint?)->Double {
            guard let a,let b else{return 0}
            return min(1.0, hypot(Double(a.x-b.x),Double(a.y-b.y))*8.0)
        }
        let hm=distance(head,previousHeadCenter), bm=distance(body,previousBodyCenter)
        if head != nil { previousHeadCenter=head }
        if body != nil { previousBodyCenter=body }
        observedFrames += 1
        if max(hm,bm) > 0.035 { movingFrames += 1 }
        let continuity = observedFrames == 0 ? 0 : Double(movingFrames)/Double(observedFrames)
        let detector = min(1,max(0, confidence))
        let energy = min(1, hm*0.28 + bm*0.52 + continuity*0.20)
        return .init(timestamp:timestamp,personVisible:faceBox != nil || !joints.isEmpty,
                     bodyConfidence:confidence,headMotion:hm,bodyMotion:bm,
                     continuity:continuity,observableEnergy:energy,detectorConfidence:detector)
    }
}

struct SwayCoachDecision: Equatable {
    var message: String
    var suggestEasier: Bool = false
    var recoverySeconds: Int? = nil
}

struct SwayPositiveCoachEngine {
    /// Encourages observable effort. Detector uncertainty is never treated as user failure.
    func decision(sample:SwayEngagementSample, match:SwayPoseScore? = nil, activeSeconds:TimeInterval = 0) -> SwayCoachDecision {
        if activeSeconds >= 12*60 && Int(activeSeconds) % (8*60) < 3 {
            return .init(message:"Water break — you earned it.", recoverySeconds:30)
        }
        if sample.personVisible && sample.detectorConfidence < 0.30 {
            return .init(message:"I can see you moving — keep going.")
        }
        if sample.continuity > 0.72 && sample.observableEnergy > 0.38 {
            return .init(message:"Great energy — stay with it!")
        }
        if let match, match.state == .partial && sample.continuity > 0.45 {
            return .init(message:"Keep moving — you've got the rhythm.")
        }
        if sample.continuity > 0.55 {
            return .init(message:"Nice work — keep it flowing.")
        }
        return .init(message:"Come back in on the next beat.", suggestEasier:true)
    }
}

enum SwayCameraFrameOrientation {
    /// Analysis buffers remain unmirrored; Vision returns mirrored display space.
    /// Preserve the established portrait convention while following native sensor rotation.
    static func exif(rotationAngle:Double)->CGImagePropertyOrientation {
        guard rotationAngle.isFinite else { return .leftMirrored }
        let wrapped=rotationAngle.truncatingRemainder(dividingBy:360)
        let quadrant=Int((wrapped/90).rounded())
        switch (quadrant%4+4)%4 {
        case 0:return .upMirrored
        case 1:return .leftMirrored
        case 2:return .downMirrored
        default:return .rightMirrored
        }
    }
}

final class CameraPoseService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    @Published private(set) var bodyDetected = false
    @Published private(set) var bodyPose: SwayBodyPose = .empty
    @Published private(set) var joints: [PoseJoint] = [] // compatibility view of bodyPose
    @Published private(set) var averageConfidence: Float = 0
    @Published private(set) var framesPerSecond: Double = 0
    @Published private(set) var cameraStatus = "Off"
    @Published private(set) var faceDetected = false
    @Published private(set) var faceBounds: CGRect? = nil
    @Published private(set) var personTrackingState: SwayPersonTrackingState = .searching
    @Published private(set) var engagement = SwayEngagementSample(timestamp:0,personVisible:false,bodyConfidence:0,headMotion:0,bodyMotion:0,continuity:0,observableEnergy:0,detectorConfidence:0)
    @Published private(set) var frameSequence: UInt64 = 0
    @Published private(set) var scoringReady = false
    @Published private(set) var geometryRevision: UInt64 = 0

    private var lastAnchorAt: TimeInterval = 0
    private var everAnchored = false
    private let reacquireGrace: TimeInterval = 1.5

    var readiness: SwayCameraReadiness {
        let names = Set(joints.map(\.name))
        let feet = names.contains(.leftAnkle) && names.contains(.rightAnkle)
        let upper = names.contains(.leftShoulder) && names.contains(.rightShoulder) && names.contains(.neck)
        return SwayCameraReadiness(bodyVisible: bodyDetected, feetVisible: feet, upperBodyVisible: upper, confidence: Double(averageConfidence))
    }

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sway.camera.session", qos: .userInitiated)
    private let visionQueue = DispatchQueue(label: "sway.camera.vision", qos: .userInitiated)
    private let request = VNDetectHumanBodyPoseRequest()
    private let faceRequest = VNDetectFaceRectanglesRequest()
    private var engagementEngine = SwayEngagementEngine()
    private var frameCount = 0
    private var fpsStart = CACurrentMediaTime()
    private var configured = false
    private var processingFrame = false
    private var currentCaptureTimestamp: TimeInterval = 0
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    // Written and consumed only on visionQueue.
    private var analysisOrientation: CGImagePropertyOrientation = .leftMirrored

    func requestAndStart() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let granted: Bool
        switch status {
        case .authorized: granted = true
        case .notDetermined: granted = await AVCaptureDevice.requestAccess(for: .video)
        default: granted = false
        }
        guard granted else {
            publishStatus("Camera permission denied")
            return
        }
        publishStatus("Preparing camera…")
        sessionQueue.async { [weak self] in self?.configureAndStart() }
    }

    private func configureAndStart() {
        if !configured {
            session.beginConfiguration()
            session.sessionPreset = .high
            defer { session.commitConfiguration() }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                publishStatus("Front camera unavailable"); return
            }
            let coordinator=AVCaptureDevice.RotationCoordinator(device:camera,previewLayer:nil)
            rotationCoordinator=coordinator
            rotationObservation=coordinator.observe(\.videoRotationAngleForHorizonLevelCapture,options:[.initial,.new]) { [weak self] _,change in
                guard let self,let angle=change.newValue else{return}
                let orientation=SwayCameraFrameOrientation.exif(rotationAngle:Double(angle))
                self.visionQueue.async {
                    guard self.analysisOrientation != orientation else{return}
                    self.analysisOrientation=orientation
                    self.engagementEngine=SwayEngagementEngine()
                    self.lastAnchorAt=0;self.everAnchored=false
                    DispatchQueue.main.async { self.geometryRevision &+= 1 }
                }
            }
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                guard session.canAddInput(input) else { publishStatus("Camera input unavailable"); return }
                session.addInput(input)
            } catch {
                publishStatus("Camera input failed: \(error.localizedDescription)"); return
            }

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            output.setSampleBufferDelegate(self, queue: visionQueue)
            guard session.canAddOutput(output) else { publishStatus("Video output unavailable"); return }
            session.addOutput(output)

            // Keep analysis buffers unmirrored. The preview is mirrored independently in CameraPreview.
            if let connection = output.connection(with: .video), connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
            configured = true
        }

        guard !session.isRunning else { publishStatus("Live — on-device Vision"); return }
        session.startRunning()
        publishStatus(session.isRunning ? "Live — on-device Vision" : "Camera failed to start")
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            self.publishStatus("Off")
            // Drain pending Vision frames before clearing the public pose. Tracking
            // history belongs to visionQueue, never the capture-session queue.
            self.visionQueue.async {
                self.everAnchored=false;self.lastAnchorAt=0
                self.engagementEngine=SwayEngagementEngine()
                self.frameCount=0;self.fpsStart=CACurrentMediaTime()
                self.publish([], detected:false,face:nil,timestamp:CACurrentMediaTime())
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !processingFrame else { return }
        processingFrame = true
        let captureTimestamp = CACurrentMediaTime()
        currentCaptureTimestamp = captureTimestamp
        defer { processingFrame = false }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: analysisOrientation)
        do {
            // Body and face geometry are extracted on-device from the same ephemeral frame.
            // No identity recognition, emotion classification, or frame persistence.
            try handler.perform([request, faceRequest])
            var visible: [PoseJoint] = []
            if let observation = request.results?.first {
                let recognized = try observation.recognizedPoints(.all)
                visible = recognized.compactMap { name, p -> PoseJoint? in
                    guard p.confidence >= 0.25 else { return nil }
                    return PoseJoint(name:name,
                                     point:CGPoint(x:p.location.x,y:1-p.location.y),
                                     confidence:p.confidence)
                }
            }
            let face = faceRequest.results?.first?.boundingBox
            let displayFace = face.map { CGRect(x:$0.origin.x, y:1-$0.origin.y-$0.height, width:$0.width, height:$0.height) }
            publish(visible, detected:!visible.isEmpty, face:displayFace, timestamp:captureTimestamp)
        } catch {
            publishStatus("Vision error: \(error.localizedDescription)")
            publish([], detected: false, face: nil, timestamp:captureTimestamp)
        }
    }

    private func publishStatus(_ status: String) {
        DispatchQueue.main.async { self.cameraStatus = status }
    }

    private func publish(_ found:[PoseJoint], detected:Bool, face:CGRect?, timestamp:TimeInterval) {
        frameCount += 1
        let now = CACurrentMediaTime()
        let elapsed = now - fpsStart
        var fps: Double?
        if elapsed >= 0.75 {
            fps = Double(frameCount) / elapsed
            frameCount = 0
            fpsStart = now
        }
        let avg = found.isEmpty ? 0 : found.map(\.confidence).reduce(0, +) / Float(found.count)
        let sample = engagementEngine.sample(faceBox:face,joints:found,confidence:Double(avg),timestamp:now)
        let names=Set(found.map(\.name))
        let shoulders = names.contains(.leftShoulder) && names.contains(.rightShoulder)
        let hips = names.contains(.leftHip) && names.contains(.rightHip)
        let torso = shoulders || hips || names.contains(.neck) || names.contains(.root)
        let fullTorso = shoulders && hips
        let head = face != nil
        let hasAnchor = head || torso
        if hasAnchor { lastAnchorAt = now; everAnchored = true }
        let withinGrace = everAnchored && now - lastAnchorAt <= reacquireGrace
        let state:SwayPersonTrackingState
        if fullTorso && head { state = .bodyReady }
        else if head && torso { state = .headAndTorso }
        else if torso { state = .torsoAnchor }
        else if head { state = .headAnchor }
        else if !found.isEmpty { state = .bodyPartial }
        else if withinGrace { state = .reacquiring }
        else { state = everAnchored ? .lost : .searching }
        // Matching needs a fresh, structurally useful body observation; an isolated joint/head is not scoreable.
        let limbEvidence = names.contains(.leftElbow) || names.contains(.rightElbow) || names.contains(.leftKnee) || names.contains(.rightKnee)
        let canScore = torso && limbEvidence && found.count >= 6 && avg >= 0.45
        DispatchQueue.main.async {
            self.bodyDetected=detected
            self.faceDetected=head
            self.faceBounds=face
            self.personTrackingState=state
            self.engagement=sample
            self.frameSequence &+= 1
            let canonical = Dictionary(uniqueKeysWithValues: found.map { ($0.name, $0) })
            self.bodyPose = SwayBodyPose(timestamp: timestamp, sequence: self.frameSequence, joints: canonical, averageConfidence: avg)
            self.joints=self.bodyPose.orderedJoints
            self.averageConfidence=self.bodyPose.averageConfidence
            self.scoringReady=canScore
            if let fps { self.framesPerSecond=fps }
        }
    }
}



// MARK: - ShazamKit recognition, recording identity, cached analysis and synchronization
struct SwayRecognitionAnchor: Equatable {
    var identity:SwayRecordingIdentity
    var matchedPosition:TimeInterval
    var observedAt:Date
    var confidence:Double
    var title:String
    var artist:String
}

final class SwayTrackAnalysisCache {
    static let shared=SwayTrackAnalysisCache()
    private let encoder=JSONEncoder(), decoder=JSONDecoder()
    private var url:URL { FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("SWAYTrackAnalysis.json") }
    private func key(_ r:SwayRecordingIdentity)->String {
        if let isrc=r.isrc,!isrc.isEmpty { return "isrc:\(isrc.lowercased())" }
        if let id=r.providerIDs["shazam"] { return "shazam:\(id)" }
        if let id=r.providerIDs["appleMusic"] { return "apple:\(id)" }
        return "\(r.artist.lowercased())|\(r.title.lowercased())|\(Int(r.duration ?? 0))"
    }
    func load(_ r:SwayRecordingIdentity)->SwayTrackAnalysis? {
        guard let d=try? Data(contentsOf:url),let all=try? decoder.decode([String:SwayTrackAnalysis].self,from:d) else{return nil}
        return all[key(r)]
    }
    func save(_ a:SwayTrackAnalysis) {
        var all:[String:SwayTrackAnalysis]=[:]
        if let d=try? Data(contentsOf:url),let old=try? decoder.decode([String:SwayTrackAnalysis].self,from:d){all=old}
        all[key(a.recording)]=a
        try? FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        if let d=try? encoder.encode(all){try? d.write(to:url,options:.atomic)}
    }
}

final class SwayLiveRhythmDetector: @unchecked Sendable {
    private let lock = NSLock()
    private var previousEnergy: Float = 0
    private var onsets: [TimeInterval] = []

    func ingest(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData, buffer.frameLength > 0 else { return }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frames { let v = data[0][i]; sum += v * v }
        let rms = sqrt(sum / Float(frames))
        let now = CACurrentMediaTime()
        lock.lock(); defer { lock.unlock() }
        let rise = rms - previousEnergy
        previousEnergy = previousEnergy * 0.72 + rms * 0.28
        guard rms > 0.015, rise > max(0.008, previousEnergy * 0.30) else { return }
        if let last = onsets.last, now - last < 0.22 { return }
        onsets.append(now)
        if onsets.count > 32 { onsets.removeFirst(onsets.count - 32) }
    }

    func snapshot() -> (bpm: Double?, lastOnsetAge: TimeInterval?) {
        lock.lock(); defer { lock.unlock() }
        guard onsets.count >= 4 else { return (nil, onsets.last.map { CACurrentMediaTime() - $0 }) }
        var intervals = zip(onsets.dropFirst(), onsets).map { $0.0 - $0.1 }
        intervals = intervals.filter { $0 >= 0.25 && $0 <= 1.5 }.sorted()
        guard !intervals.isEmpty else { return (nil, nil) }
        var median = intervals[intervals.count / 2]
        var bpm = 60.0 / median
        while bpm < 80 { bpm *= 2; median /= 2 }
        while bpm > 180 { bpm /= 2; median *= 2 }
        return (bpm, onsets.last.map { CACurrentMediaTime() - $0 })
    }
}

@MainActor
final class SwayShazamProvider:NSObject,ObservableObject,SHSessionDelegate {
    @Published private(set) var status="Shazam ready"
    @Published private(set) var listening=false
    @Published private(set) var anchor:SwayRecognitionAnchor?
    @Published private(set) var cachedAnalysis:SwayTrackAnalysis?
    @Published private(set) var liveBPM:Double?
    private let session=SHSession()
    private let engine=AVAudioEngine()
    private let rhythm=SwayLiveRhythmDetector()
    private var startedAt:Date?
    private var lastAnchorAt=Date.distantPast
    private var rhythmTask:Task<Void,Never>?

    override init(){super.init();session.delegate=self}

    func start() async {
        guard !listening else{return}
        let granted=await AVAudioApplication.requestRecordPermission()
        guard granted else{status="Microphone permission is needed to listen for music.";return}
        do {
            let audio=AVAudioSession.sharedInstance()
            try audio.setCategory(.playAndRecord,mode:.default,options:[.mixWithOthers,.defaultToSpeaker,.allowBluetoothA2DP])
            try audio.setActive(true)
            let input=engine.inputNode, format=input.outputFormat(forBus:0)
            input.removeTap(onBus:0)
            input.installTap(onBus:0,bufferSize:4096,format:format){[weak self] buffer,time in
                guard let self else { return }
                self.rhythm.ingest(buffer)
                self.session.matchStreamingBuffer(buffer,at:time)
            }
            try engine.start(); listening=true; startedAt=Date(); status="Listening for music…"
            rhythmTask?.cancel()
            rhythmTask=Task { @MainActor [weak self] in
                while let self, self.listening, !Task.isCancelled {
                    try? await Task.sleep(nanoseconds:1_500_000_000)
                    guard !Task.isCancelled else { break }
                    if let bpm=self.rhythm.snapshot().bpm { self.liveBPM=bpm }
                }
            }
        } catch {
            let e = error as NSError
            status="Shazam listening unavailable · \(e.domain) \(e.code): \(e.localizedDescription)"
        }
    }
    func stop(){
        rhythmTask?.cancel(); rhythmTask=nil
        if engine.isRunning {engine.stop()}; engine.inputNode.removeTap(onBus:0); listening=false
        status=anchor == nil ? "Shazam stopped" : "Recognition anchored"
    }
    nonisolated func session(_ session:SHSession,didFind match:SHMatch) {
        guard let item=match.mediaItems.first else{return}
        Task{@MainActor [weak self] in self?.accept(item) }
    }
    nonisolated func session(_ session:SHSession,didNotFindMatchFor signature:SHSignature,error:Error?) {
        Task{@MainActor [weak self] in
            guard let self, self.anchor == nil else { return }
            if let error {
                let e = error as NSError
                self.status = "Shazam match failed · \(e.domain) \(e.code): \(e.localizedDescription)"
            } else {
                self.status = "Listening · no match yet"
            }
        }
    }
    private func accept(_ item:SHMatchedMediaItem){
        // Throttle observations: the local SWAY clock remains authoritative between anchors.
        guard Date().timeIntervalSince(lastAnchorAt) > 2.0 else{return}; lastAnchorAt=Date()
        var ids:[String:String]=[:]
        if let id=item.shazamID {ids["shazam"]=id}
        if let u=item.appleMusicURL {ids["appleMusicURL"]=u.absoluteString}
        let identity=SwayRecordingIdentity(providerIDs:ids,title:item.title ?? "Recognized music",artist:item.artist ?? "Unknown",duration:nil)
        let pos=max(0,item.predictedCurrentMatchOffset)
        let a=SwayRecognitionAnchor(identity:identity,matchedPosition:pos,observedAt:Date(),confidence:1,title:identity.title,artist:identity.artist)
        anchor=a
        cachedAnalysis=SwayTrackAnalysisCache.shared.load(identity)
        let rhythmSnapshot=rhythm.snapshot()
        liveBPM=rhythmSnapshot.bpm
        if cachedAnalysis == nil, let bpm=rhythmSnapshot.bpm {
            // Shazam supplies identity/position; SWAY supplies the beat structure from captured sound.
            // Align the most recent detected onset to the matched recording position, then synthesize
            // a reusable beat grid around that anchor. Later observations can re-anchor drift smoothly.
            let interval=60.0/bpm
            let age=rhythmSnapshot.lastOnsetAge ?? 0
            let phase=max(0,pos-age)
            let first=max(0,phase - interval*ceil(phase/interval))
            var beats:[TimeInterval]=[]
            var t=first
            while t < max(900,(identity.duration ?? 0)+30) { if t >= 0 { beats.append(t) }; t += interval }
            let down=Array(beats.enumerated().compactMap { $0.offset % 4 == 0 ? $0.element : nil })
            let phrases=Array(beats.enumerated().compactMap { $0.offset % 32 == 0 ? $0.element : nil })
            let generated=SwayTrackAnalysis(recording:identity,source:.swayDerived,confidence:0.58,bpm:bpm,timeSignatureNumerator:4,timeSignatureDenominator:4,beatTimes:beats,downbeats:down,phraseStarts:phrases)
            SwayTrackAnalysisCache.shared.save(generated)
            cachedAnalysis=generated
        }
        status=cachedAnalysis == nil ? "Recognized · listening for rhythm" : "Recognized · SWAY rhythm map ready"
    }
}

enum SwayCoachProfileID: String, CaseIterable, Identifiable {
    case lucia, nandi, thabo, zuri, kyle
    var id:String { rawValue }
    var displayName:String { rawValue.capitalized }
    func phrase(_ intent:String)->String {
        switch self {
        case .lucia: return intent
        case .nandi: return "You've got this — \(intent.lowercased())"
        case .thabo: return "Strong and steady. \(intent)"
        case .zuri: return "Feel the groove — \(intent.lowercased())"
        case .kyle: return "Nice! \(intent)"
        }
    }
}

@MainActor
final class SwayCueEngine:ObservableObject {
    @Published var enabled=true
    @Published var spokenCounts=false
    private var haptic:CHHapticEngine?
    private let speech=AVSpeechSynthesizer()
    init(){haptic=try? CHHapticEngine();try? haptic?.start()}
    func beat(count:Int,phraseStart:Bool=false){
        guard enabled else{return}
        let intensity:Float=phraseStart ? 1.0 : (count == 1 ? 0.8 : 0.42)
        let event=CHHapticEvent(eventType:.hapticTransient,parameters:[.init(parameterID:.hapticIntensity,value:intensity),.init(parameterID:.hapticSharpness,value:0.45)],relativeTime:0)
        if let pattern=try? CHHapticPattern(events:[event],parameters:[]){try? haptic?.makePlayer(with:pattern).start(atTime:0)}
        if spokenCounts && (count == 1 || count == 5) { let u=AVSpeechUtterance(string:"\(count)");u.rate=0.52;speech.speak(u) }
    }
    func coach(_ text:String){guard enabled,!speech.isSpeaking else{return};let u=AVSpeechUtterance(string:text);u.rate=0.5;speech.speak(u)}
}

// MARK: - SWAY music clock (offline/native AVFoundation baseline)
@MainActor
final class SwayMusicEngine: ObservableObject {
    enum BeatStyle: String, CaseIterable, Identifiable {
        case basic = "Simple", pop = "Pop", house = "House", hipHop = "Hip-Hop", disco = "Disco"
        case latin = "Latin", afro = "Afro", percussion = "Percussion", rock = "Rock", minimal = "Minimal"
        var id: String { rawValue }
        var defaultBPM: Double {
            switch self {
            case .basic: return 116
            case .pop: return 118
            case .house: return 124
            case .hipHop: return 96
            case .disco: return 118
            case .latin: return 104
            case .afro: return 112
            case .percussion: return 108
            case .rock: return 122
            case .minimal: return 110
            }
        }
    }

    private static func prepareAudioSessionInBackground() {
        DispatchQueue.global(qos: .userInitiated).async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
            } catch { }
        }
    }

    @Published var trackTitle = "SWAY Beat"
    @Published var bpm: Double = 120
    @Published var isPlaying = false
    @Published var providerName = "SWAY Offline"
    @Published var playbackPosition: TimeInterval = 0
    @Published var libraryAuthorized = MPMediaLibrary.authorizationStatus() == .authorized
    @Published var usingLibraryTrack = false
    @Published var beatStyle: BeatStyle = .basic
    @Published var beatIntensity: Double = 0.55
    @Published var beatComplexity: Double = 0.35
    @Published var lastMusicMessage = ""
    @Published var analyzedBeatGrid: SwayBeatGrid? = nil
    @Published var analysisStatus = "Not analyzed"
    @Published var shuffleEnabled = false

    private let libraryPlayer = MPMusicPlayerController.applicationMusicPlayer
    private var player: AVAudioPlayer?
    private var audioClockBase:TimeInterval=0
    private var audioScheduledStart:TimeInterval?
    private var libraryClockBase:TimeInterval=0
    private var lastLibraryPosition:TimeInterval=0
    private var lastLibraryTrackID:UInt64?
    private var libraryAnalysisGeneration=UUID()

    /// Musical time comes from native transport. Device time counts audio output samples.
    var authoritativePlaybackPosition:TimeInterval {
        let position:TimeInterval
        if usingLibraryTrack {
            let current=max(0,libraryPlayer.currentPlaybackTime)
            let identity=libraryPlayer.nowPlayingItem?.persistentID
            if let previous=lastLibraryTrackID, let identity, identity != previous {
                libraryClockBase += lastLibraryPosition
            }
            lastLibraryTrackID=identity;lastLibraryPosition=current
            position=libraryClockBase+current
        } else if isPlaying,let player,let origin=audioScheduledStart {
            position=audioClockBase+max(0,player.deviceCurrentTime-origin)
        } else { position=audioClockBase }
        return position.isFinite ? position : playbackPosition
    }

    private func resetAudioClock() {
        audioClockBase=0;audioScheduledStart=nil
        libraryClockBase=0;lastLibraryPosition=0;lastLibraryTrackID=nil
        playbackPosition=0
    }

    func play() {
        guard !isPlaying else{return}
        Self.prepareAudioSessionInBackground()
        if usingLibraryTrack {
            libraryPlayer.play();isPlaying=true
        } else {
            if player == nil { player = makeBeatPlayer() }
            guard let player else {lastMusicMessage="Generated Beat unavailable";return}
            // A rebuilt voice must start at the held phase, including paused tempo changes.
            player.currentTime=audioClockBase.truncatingRemainder(dividingBy:max(0.001,player.duration))
            let start=player.deviceCurrentTime+0.02
            audioScheduledStart=start
            isPlaying=player.play(atTime:start)
            if !isPlaying {audioScheduledStart=nil;lastMusicMessage="Generated Beat could not start"}
        }
    }

    func pause() {
        audioClockBase=authoritativePlaybackPosition
        playbackPosition=audioClockBase;audioScheduledStart=nil
        if usingLibraryTrack { libraryPlayer.pause() } else { player?.pause() }
        isPlaying = false
    }

    func stop() {
        if usingLibraryTrack { libraryPlayer.stop() }
        player?.stop(); player = nil
        resetAudioClock()
        isPlaying = false
    }

    func requestLibraryAccess() async -> Bool {
        if MPMediaLibrary.authorizationStatus() == .authorized {
            libraryAuthorized = true
            return true
        }
        let status = await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { continuation.resume(returning: $0) }
        }
        libraryAuthorized = status == .authorized
        return libraryAuthorized
    }

    /// Selects a random locally playable library song after explicit Media Library permission.
    /// Returns false without silently falling back, so UI can explain permission/empty-library state.
    @MainActor
    func useRandomLibrarySong() async -> Bool {
        guard await requestLibraryAccess() else {
            lastMusicMessage = "Music Library access is needed for Random Song."
            return false
        }
        let query = MPMediaQuery.songs()
        let playable = (query.items ?? []).filter {
            $0.mediaType == .music && $0.assetURL != nil && !$0.isCloudItem
        }
        guard let item = playable.randomElement() else {
            lastMusicMessage = "No locally available songs were found."
            return false
        }
        useLibraryItems(MPMediaItemCollection(items: [item]))
        lastMusicMessage = "Random song: \(trackTitle)"
        return true
    }

    func useLibraryItems(_ collection: MPMediaItemCollection) {
        guard let item = collection.items.first else {
            lastMusicMessage = "No music was selected."
            return
        }
        player?.stop(); player = nil
        libraryPlayer.stop()
        resetAudioClock()
        libraryAnalysisGeneration=UUID()
        let generation=libraryAnalysisGeneration
        libraryPlayer.setQueue(with: collection)
        let count = collection.items.count
        trackTitle = count > 1 ? "\(item.title ?? "My Music") + \(count - 1) more" : (item.title ?? "My Music")
        providerName = count > 1 ? "Music Library · \(count) songs" : "Music Library"
        usingLibraryTrack = true
        isPlaying = false
        lastMusicMessage = count > 1 ? "\(count) songs ready" : "\(item.title ?? "Song") ready"
        // Library metadata is optional. The SWAY timeline keeps a safe fallback when BPM is absent.
        if item.beatsPerMinute > 0 { bpm = Double(item.beatsPerMinute) }
        analyzedBeatGrid=nil
        let metadataBPM=item.beatsPerMinute
        if let url=item.assetURL {
            analysisStatus="Analyzing rhythm…"
            Task.detached(priority:.userInitiated) {
                let grid:SwayBeatGrid?
                do {
                    let (samples,rate)=try SwayAudioAnalyzer.readMonoSamples(url:url,maxSeconds:240)
                    grid=SwayAudioAnalyzer.analyze(samples:samples,sampleRate:rate)
                } catch { grid=nil }
                await MainActor.run {
                    self.applyLibraryAnalysis(grid,metadataBPM:metadataBPM,generation:generation)
                }
            }
        } else {
            analysisStatus=metadataBPM > 0 ? "Using library tempo metadata" : "Protected/cloud audio — direct PCM analysis unavailable"
        }
    }

    /// Late detached analysis belongs only to the source selection that requested it.
    func applyLibraryAnalysis(_ grid:SwayBeatGrid?,metadataBPM:Int,generation:UUID) {
        guard usingLibraryTrack,generation == libraryAnalysisGeneration else{return}
        analyzedBeatGrid=grid
        if let grid {
            bpm=grid.bpm
            analysisStatus="SWAY analysis · \(Int(grid.bpm.rounded())) BPM · \(Int(grid.confidence*100))%"
        } else {
            analysisStatus=metadataBPM > 0 ? "Using library tempo metadata" : "Audio analysis unavailable for this recording"
        }
    }

    func nextTrack() {
        if usingLibraryTrack {
            libraryPlayer.skipToNextItem()
            lastMusicMessage="Next song"
        } else {
            let styles=BeatStyle.allCases
            let next=(styles.firstIndex(of:beatStyle).map{$0+1} ?? 0) % styles.count
            useOfflineBeat(style:styles[next]); play()
        }
    }

    func toggleShuffle() {
        guard usingLibraryTrack else { return }
        shuffleEnabled.toggle()
        libraryPlayer.shuffleMode=shuffleEnabled ? .songs : .off
        lastMusicMessage=shuffleEnabled ? "Shuffle on" : "Shuffle off"
    }

    func setPlaybackMode(_ mode:SwayMusicPlaybackMode) {
        switch mode {
        case .inOrder:
            libraryPlayer.shuffleMode = .off
            shuffleEnabled=false
            lastMusicMessage = "Playlist will play in order."
        case .shuffle:
            libraryPlayer.shuffleMode = .songs
            shuffleEnabled=true
            lastMusicMessage = "Playlist shuffle is on."
        case .automatic:
            // Build 72 makes Automatic functional as a non-repeating shuffled workout queue.
            // Phase/BPM-aware sequencing remains analysis-driven and must not be falsely claimed here.
            libraryPlayer.shuffleMode = .songs
            lastMusicMessage = "Automatic workout queue is on."
        }
    }

    func setOfflineTempo(_ newBPM:Double) {
        guard !usingLibraryTrack else { return }
        let wasPlaying=isPlaying
        let beats=authoritativePlaybackPosition*max(20,bpm)/60
        bpm=max(20,min(180,newBPM))
        player?.stop(); player=nil;isPlaying=false;audioScheduledStart=nil
        audioClockBase=beats*60/bpm;playbackPosition=audioClockBase
        if wasPlaying {
            player=makeBeatPlayer()
            if let player {player.currentTime=audioClockBase.truncatingRemainder(dividingBy:max(0.001,player.duration))}
            play()
        }
        lastMusicMessage="\(beatStyle.rawValue) · \(Int(bpm)) BPM"
    }

    /// Rebuild the generated offline loop after the drummer feel changes.
    /// This makes the XY performance control audible immediately while previewing,
    /// without changing the selected style or tempo.
    func refreshOfflineBeatIfPlaying() {
        guard !usingLibraryTrack else { return }
        let wasPlaying = isPlaying
        audioClockBase=authoritativePlaybackPosition;playbackPosition=audioClockBase
        player?.stop();player=nil;isPlaying=false;audioScheduledStart=nil
        if wasPlaying {
            player=makeBeatPlayer()
            if let player {player.currentTime=audioClockBase.truncatingRemainder(dividingBy:max(0.001,player.duration))}
            play()
        }
    }

    func useOfflineBeat(style: BeatStyle = .basic) {
        libraryAnalysisGeneration=UUID()
        resetAudioClock()
        libraryPlayer.stop()
        player?.stop(); player = nil
        usingLibraryTrack = false
        analyzedBeatGrid=nil
        analysisStatus="Generated SWAY rhythm"
        beatStyle = style
        bpm = style.defaultBPM
        trackTitle = style == .basic ? "SWAY Beat" : "SWAY \(style.rawValue)"
        providerName = "SWAY Beats"
        lastMusicMessage = "\(style.rawValue) · \(Int(bpm)) BPM"
        isPlaying = false
    }

    func seek(to seconds: TimeInterval) {
        guard seconds.isFinite else{return}
        if usingLibraryTrack {
            libraryPlayer.currentPlaybackTime = max(0, seconds)
            libraryClockBase=0;lastLibraryPosition=max(0,libraryPlayer.currentPlaybackTime)
            playbackPosition=lastLibraryPosition
        } else {
            let wasPlaying=isPlaying
            player?.pause();isPlaying=false;audioScheduledStart=nil
            audioClockBase=max(0,seconds);playbackPosition=audioClockBase
            if let player {
                player.currentTime=audioClockBase.truncatingRemainder(dividingBy:max(0.001,player.duration))
            }
            if wasPlaying {play()}
        }
    }

    /// Generates an original deterministic rhythm loop. Each style has a genuinely different
    /// kick/snare/hat/percussion pattern and tempo; no copyrighted samples are bundled.
    private func makeBeatPlayer() -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let beatsPerBar = 4
        let subdivisions = 4
        let bars = 2
        let steps = beatsPerBar * subdivisions * bars
        let framesPerStep = max(1, Int(sampleRate * (60.0 / bpm) / Double(subdivisions)))
        let frames = framesPerStep * steps

        func hits(for style: BeatStyle, step: Int) -> (kick:Double,snare:Double,hat:Double,perc:Double) {
            let s = step % 16
            switch style {
            case .basic:
                return (s % 4 == 0 ? 1:0, s == 4 || s == 12 ? 0.8:0, s % 2 == 0 ? 0.22:0, 0)
            case .pop:
                return ([0,8,10].contains(s) ? 0.92:0, [4,12].contains(s) ? 0.88:0, s % 2 == 0 ? 0.30:0.08, [6,14].contains(s) ? 0.18:0)
            case .house:
                return (s % 4 == 0 ? 1:0, s == 4 || s == 12 ? 0.65:0, s % 2 == 2 ? 0.5:0.12, 0)
            case .hipHop:
                return ([0,7,10].contains(s) ? 1:0, [4,12].contains(s) ? 0.95:0, s % 2 == 0 ? 0.28:0.08, [3,11,15].contains(s) ? 0.25:0)
            case .disco:
                return (s % 4 == 0 ? 0.9:0, [4,12].contains(s) ? 0.75:0, s % 2 == 0 ? 0.5:0.16, [2,6,10,14].contains(s) ? 0.22:0)
            case .latin:
                return ([0,6,10].contains(s) ? 0.85:0, [4,12].contains(s) ? 0.55:0, s % 2 == 0 ? 0.18:0, [3,7,11,14].contains(s) ? 0.65:0)
            case .afro:
                return ([0,5,10].contains(s) ? 0.9:0, [4,12].contains(s) ? 0.48:0, [2,6,10,14].contains(s) ? 0.25:0, [3,7,9,15].contains(s) ? 0.72:0)
            case .percussion:
                return (s == 0 ? 0.55:0, [4,12].contains(s) ? 0.30:0, [2,6,10,14].contains(s) ? 0.18:0, [1,3,6,9,11,14].contains(s) ? 0.82:0)
            case .rock:
                return ([0,8,10].contains(s) ? 1:0, [4,12].contains(s) ? 1:0, s % 2 == 0 ? 0.34:0.12, [15].contains(s) ? 0.32:0)
            case .minimal:
                return (s % 4 == 0 ? 0.75:0, s == 12 ? 0.42:0, s % 4 == 2 ? 0.18:0, 0)
            }
        }

        var pcm=[Int16](); pcm.reserveCapacity(frames)
        for frame in 0..<frames {
            let step = frame / framesPerStep
            let local = frame % framesPerStep
            var h = hits(for: beatStyle, step: step)
            let density=max(0,min(1,beatComplexity)), energy=max(0.15,min(1,beatIntensity))
            if density < 0.28 && step % 4 != 0 { h.hat *= 0.15; h.perc *= 0.10 }
            if density > 0.62 && step % 2 == 1 { h.hat=max(h.hat,0.18+density*0.20); h.perc=max(h.perc,density*0.18) }
            h.kick *= 0.65+energy*0.45; h.snare *= 0.60+energy*0.50; h.hat *= 0.45+energy*0.65; h.perc *= 0.45+energy*0.70
            let x = Double(local)
            let kickEnv = exp(-x / 1500.0)
            let snareEnv = exp(-x / 850.0)
            let hatEnv = exp(-x / 260.0)
            let percEnv = exp(-x / 600.0)
            // Percussive synthesis: pitched kick plus deterministic broadband transients.
            // Avoid the previous sustained high-frequency oscillator that sounded like a test tone.
            let noiseSeed = sin((Double(frame) + Double(step * 7919)) * 12.9898) * 43758.5453
            let noise = (noiseSeed - floor(noiseSeed)) * 2.0 - 1.0
            let kickPhase = x * (0.050 - min(0.030, x / 90000.0))
            let kick = sin(kickPhase) * kickEnv * h.kick
            let snare = noise * snareEnv * h.snare
            let hat = (noise - sin(x * 0.031) * 0.20) * hatEnv * h.hat
            let perc = (noise * 0.65 + sin(x * 0.12) * 0.35) * percEnv * h.perc
            let mixed = max(-1.0,min(1.0,kick*0.72 + snare*0.30 + hat*0.12 + perc*0.28))
            pcm.append(Int16(mixed * 18000))
        }

        var wav=Data()
        func u16(_ v:UInt16){ var x=v.littleEndian; wav.append(Data(bytes:&x,count:2)) }
        func u32(_ v:UInt32){ var x=v.littleEndian; wav.append(Data(bytes:&x,count:4)) }
        let dataSize=UInt32(pcm.count*2)
        wav.append("RIFF".data(using:.ascii)!); u32(36+dataSize)
        wav.append("WAVEfmt ".data(using:.ascii)!); u32(16); u16(1); u16(1)
        u32(UInt32(sampleRate)); u32(UInt32(sampleRate*2)); u16(2); u16(16)
        wav.append("data".data(using:.ascii)!); u32(dataSize)
        for sample in pcm { var x=sample.littleEndian; wav.append(Data(bytes:&x,count:2)) }
        let p=try? AVAudioPlayer(data:wav)
        p?.numberOfLoops = -1; p?.prepareToPlay()
        return p
    }
}


// MARK: - Music provider contract
struct SwayProviderDescriptor: Identifiable {
    var id: SwayMusicProvider
    var name: String
    var capabilities: Set<SwayMusicCapability>
}

@MainActor
protocol SwayMusicProviderAdapter {
    var descriptor: SwayProviderDescriptor { get }
    func availability(for recording: SwayRecordingIdentity) async -> SwayTrackAvailability
}

// MARK: - SWAY Beats pattern engine
struct SwayDrumHit: Hashable {
    enum Voice: String { case kick, snare, closedHat, openHat, clap, rim, tomLow, tomHigh, shaker, tambourine, cowbell, crash }
    var beat: Double
    var voice: Voice
    var velocity: Double
}

enum SwayBeatPatternEngine {
    static func pattern(style: SwayBeatStyle, complexity: Double, intensity: Double) -> [SwayDrumHit] {
        let kick = [SwayDrumHit(beat:0, voice:.kick, velocity:0.85),
                    SwayDrumHit(beat:2, voice:.kick, velocity:0.75)]
        let backbeat = [SwayDrumHit(beat:1, voice:.snare, velocity:0.78),
                        SwayDrumHit(beat:3, voice:.snare, velocity:0.82)]
        var hits = kick + backbeat
        let step = complexity > 0.6 ? 0.5 : 1.0
        var b = 0.0
        while b < 4 {
            hits.append(.init(beat:b, voice: style == .latin || style == .afro ? .shaker : .closedHat,
                              velocity:0.42 + intensity * 0.25))
            b += step
        }
        if style == .house {
            hits = [0,1,2,3].map { .init(beat:Double($0), voice:.kick, velocity:0.85) } + hits.filter { $0.voice != .kick }
        }
        if style == .disco { hits.append(.init(beat:1.5, voice:.openHat, velocity:0.55)); hits.append(.init(beat:3.5, voice:.openHat, velocity:0.55)) }
        if style == .latin { hits.append(.init(beat:2.5, voice:.clap, velocity:0.5)) }
        if style == .afro { hits.append(.init(beat:2.5, voice:.tomLow, velocity:0.55)) }
        return hits.sorted { $0.beat < $1.beat }
    }
}


// MARK: - Shared control surface contract
// iPhone is the first client. A near-v1 Watch client can send the same commands
// and observe the same snapshot without changing workout semantics.
@MainActor
final class SwaySessionController: ObservableObject {
    @Published private(set) var snapshot = SwaySessionSnapshot()
    var commandHandler: ((SwaySessionCommand) -> Void)?

    func publish(_ newValue: SwaySessionSnapshot) { snapshot = newValue }
    func send(_ command: SwaySessionCommand) { commandHandler?(command) }
}



// MARK: - Shared Sessions coordinator
@MainActor
final class SwaySharedSessionCoordinator: ObservableObject {
    @Published private(set) var activeSession: SwaySharedSessionDescriptor?
    @Published private(set) var lastEvent: SwaySharedSessionEvent?
    @Published var preferredTransport: SwaySharedSessionTransport = .local
    @Published var statusMessage: String = "Ready"

    private var sequence: UInt64 = 0
    private let entitlement: SwaySharedSessionEntitlementResolving

    init(entitlement: SwaySharedSessionEntitlementResolving = SwayPrivateSharedSessionEntitlementResolver()) {
        self.entitlement = entitlement
    }

    var masterUnlockedForTesting: Bool { entitlement.hasMasterHostEntitlement }

    func createSession(hostName: String, requestedCapacity: Int = 2) {
        let normalizedCapacity = max(1, requestedCapacity)
        guard entitlement.mayHost(participantCount: normalizedCapacity) else {
            statusMessage = "This session size is not available for the current entitlement."
            return
        }
        let hostID = UUID()
        let tier: SwaySharedSessionTier = normalizedCapacity <= 1 ? .individual : (normalizedCapacity == 2 ? .together : (normalizedCapacity <= 6 ? .household : .master))
        activeSession = SwaySharedSessionDescriptor(
            hostID: hostID,
            tier: tier,
            transport: preferredTransport,
            participants: [
                SwaySharedParticipant(id: hostID, displayName: hostName, role: .host, presence: .ready)
            ]
        )
        statusMessage = "\(tier.rawValue) session created"
    }

    @discardableResult
    func addParticipant(displayName: String) -> Bool {
        guard var session = activeSession else { return false }
        let proposed = session.participants.count + 1
        guard entitlement.mayHost(participantCount: proposed) else {
            statusMessage = "Participant limit reached for this session."
            return false
        }
        if session.tier == .individual && proposed == 2 { session.tier = .together }
        else if session.tier == .together && proposed > 2 && proposed <= 6 { session.tier = .household }
        else if session.tier == .household && proposed > 6 { session.tier = .master }
        session.participants.append(
            SwaySharedParticipant(id: UUID(), displayName: displayName,
                                  role: .participant, presence: .ready)
        )
        activeSession = session
        statusMessage = "\(session.participants.count) participants ready"
        return true
    }

    func removeParticipant(id: UUID) {
        guard var session = activeSession, id != session.hostID else { return }
        session.participants.removeAll { $0.id == id }
        activeSession = session
    }

    func endSession() {
        activeSession = nil
        lastEvent = nil
        sequence = 0
        statusMessage = "Ready"
    }

    func publish(_ snapshot: SwaySessionSnapshot) {
        guard let session = activeSession else { return }
        sequence &+= 1
        lastEvent = SwaySharedSessionEvent(
            sessionID: session.id,
            sequence: sequence,
            timestamp: Date().timeIntervalSince1970,
            snapshot: snapshot
        )
    }
}

// MARK: - Recording resolver
actor SwayRecordingResolver {
    struct MBResponse:Decodable {
        struct Recording:Decodable { let id:String; let title:String? }
        let recordings:[Recording]?
    }

    func musicBrainz(isrc:String) async throws -> SwayResolvedRecording? {
        let clean=isrc.replacingOccurrences(of:"-",with:"").uppercased()
        guard let url=URL(string:"https://musicbrainz.org/ws/2/isrc/\(clean)?fmt=json") else { return nil }
        var req=URLRequest(url:url)
        req.setValue("SWAY/0.4 (private development)",forHTTPHeaderField:"User-Agent")
        let (data,response)=try await URLSession.shared.data(for:req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let decoded=try JSONDecoder().decode(MBResponse.self,from:data)
        guard let hit=decoded.recordings?.first else { return nil }
        let identity=SwayRecordingIdentity(isrc:clean,musicBrainzRecordingID:hit.id,
            title:hit.title ?? "Unknown",artist:"Unknown")
        return .init(identity:identity,confidence:0.98,source:.musicBrainz)
    }

    // AcoustID requires a registered client key and a Chromaprint fingerprint.
    // This method is fully wired; caller supplies those values rather than SWAY embedding secrets.
    func acoustID(fingerprint:String,duration:Int,clientKey:String) async throws -> SwayResolvedRecording? {
        var c=URLComponents(string:"https://api.acoustid.org/v2/lookup")!
        c.queryItems=[
            .init(name:"client",value:clientKey),.init(name:"duration",value:"\(duration)"),
            .init(name:"fingerprint",value:fingerprint),.init(name:"meta",value:"recordings+recordingids+isrcs"),
            .init(name:"format",value:"json")
        ]
        let (data,response)=try await URLSession.shared.data(from:c.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let object=try JSONSerialization.jsonObject(with:data) as? [String:Any]
        guard let results=object?["results"] as? [[String:Any]], let first=results.first else{return nil}
        let score=first["score"] as? Double ?? 0
        let aid=first["id"] as? String
        let recordings=first["recordings"] as? [[String:Any]]
        let rec=recordings?.first
        let mbid=rec?["id"] as? String
        let title=rec?["title"] as? String ?? "Unknown"
        let identity=SwayRecordingIdentity(musicBrainzRecordingID:mbid,acoustID:aid,title:title,artist:"Unknown")
        return .init(identity:identity,confidence:score,source:.acoustID)
    }
}

// MARK: - MusicKit provider
@MainActor
final class SwayMusicKitProvider:ObservableObject,SwayMusicProviderAdapter {
    @Published var authorization:MusicAuthorization.Status = MusicAuthorization.currentStatus
    @Published var results:[Song]=[]
    @Published var nowPlaying:String=""
    private let player=ApplicationMusicPlayer.shared

    var descriptor:SwayProviderDescriptor {
        .init(id:.appleMusic,name:"Apple Music",
              capabilities:[.playback,.metadata,.offline,.playlistRead,.playlistWrite])
    }

    func refreshAuthorization() { authorization=MusicAuthorization.currentStatus }
    func requestAuthorization() async { authorization=await MusicAuthorization.request() }

    func search(_ term:String) async throws {
        var request=MusicCatalogSearchRequest(term:term,types:[Song.self])
        request.limit=20
        let response=try await request.response()
        results=Array(response.songs)
    }

    func play(_ song:Song) async throws {
        player.queue=[song]
        try await player.play()
        nowPlaying=song.title
    }

    func pause(){ player.pause() }

    func recordingIdentity(for song:Song)->SwayRecordingIdentity {
        SwayRecordingIdentity(isrc:song.isrc,providerIDs:["appleMusic":song.id.rawValue],
                              title:song.title,artist:song.artistName,duration:song.duration)
    }

    func availability(for recording:SwayRecordingIdentity) async -> SwayTrackAvailability {
        authorization == .authorized ? .streaming : .authorizationRequired
    }
}

// MARK: - Complete local-file player
@MainActor
final class SwayLocalAudioPlayer:ObservableObject {
    @Published var title=""
    @Published var isPlaying=false
    @Published var duration:TimeInterval=0
    private var heldTime:TimeInterval=0
    /// Native player timeline excludes paused intervals; unavailable samples hold position.
    var currentTime:TimeInterval {
        guard isPlaying,let render=node.lastRenderTime,
              let time=node.playerTime(forNodeTime:render),time.sampleRate>0 else{return heldTime}
        let position=Double(time.sampleTime)/time.sampleRate
        guard position.isFinite else{return heldTime}
        heldTime=min(duration,max(0,position))
        return heldTime
    }
    private let engine=AVAudioEngine()
    private let node=AVAudioPlayerNode()
    private var file:AVAudioFile?
    private var securityURL:URL?
    private(set) var loadedURL:URL?

    init(){ engine.attach(node) }

    func load(_ url:URL) throws {
        stop()
        let access=url.startAccessingSecurityScopedResource()
        securityURL=access ? url:nil
        let f=try AVAudioFile(forReading:url)
        file=f; loadedURL=url; title=url.deletingPathExtension().lastPathComponent
        duration=Double(f.length)/f.processingFormat.sampleRate
        engine.disconnectNodeOutput(node)
        engine.connect(node,to:engine.mainMixerNode,format:f.processingFormat)
        node.scheduleFile(f,at:nil)
    }
    func play() throws {
        guard file != nil else{return}
        if !engine.isRunning { try engine.start() }
        node.play(); isPlaying=true
    }
    func pause(){ heldTime=currentTime; node.pause(); isPlaying=false }
    func stop(){
        node.stop(); engine.stop(); isPlaying=false;heldTime=0
        if let u=securityURL { u.stopAccessingSecurityScopedResource() }; securityURL=nil
        loadedURL=nil
    }
    deinit { if let u=securityURL { u.stopAccessingSecurityScopedResource() } }
}

// MARK: - Audio analysis
enum SwayAudioAnalyzer {
    // Energy-onset autocorrelation. Designed for local/provider PCM where SWAY has lawful sample access.
    static func analyze(samples:[Float],sampleRate:Double)->SwayBeatGrid? {
        guard samples.count > 4096, sampleRate > 0 else{return nil}
        let hop=512, frame=1024
        var energy:[Float]=[]
        var i=0
        while i+frame <= samples.count {
            var e:Float=0
            vDSP_svesq(Array(samples[i..<i+frame]),1,&e,vDSP_Length(frame))
            energy.append(e); i += hop
        }
        guard energy.count > 32 else{return nil}
        var onset=[Float](repeating:0,count:energy.count)
        for j in 1..<energy.count { onset[j]=max(0,energy[j]-energy[j-1]) }
        let envRate=sampleRate/Double(hop)
        let minLag=max(1,Int(envRate*60/200)), maxLag=min(onset.count-2,Int(envRate*60/60))
        guard maxLag>minLag else{return nil}
        var bestLag=minLag, best:Float=0
        for lag in minLag...maxLag {
            var sum:Float=0
            for j in lag..<onset.count { sum += onset[j]*onset[j-lag] }
            if sum>best { best=sum; bestLag=lag }
        }
        let bpm=60*envRate/Double(bestLag)
        let beat=60/bpm
        let duration=Double(samples.count)/sampleRate

        // Find the beat phase from the onset envelope instead of assuming song time zero is a beat.
        // This is the critical difference between a metronome at the right BPM and a grid aligned to the recording.
        var bestPhase=0
        var bestPhaseScore:Float=0
        if bestLag > 0 {
            for phase in 0..<bestLag {
                var score:Float=0
                var j=phase
                while j<onset.count { score += onset[j]; j += bestLag }
                if score>bestPhaseScore { bestPhaseScore=score; bestPhase=phase }
            }
        }
        let phaseTime=Double(bestPhase)/envRate
        var beats:[TimeInterval]=[]
        var t=phaseTime
        while t<duration { beats.append(t); t += beat }

        // Choose a four-beat downbeat phase by accumulated onset strength.
        var downbeatPhase=0
        var downbeatScore:Float=0
        for phase in 0..<4 {
            var score:Float=0
            var k=phase
            while k<beats.count {
                let envIndex=min(onset.count-1,max(0,Int(beats[k]*envRate)))
                score += onset[envIndex]; k += 4
            }
            if score>downbeatScore { downbeatScore=score; downbeatPhase=phase }
        }
        let down=beats.enumerated().compactMap{ ($0.offset-downbeatPhase)%4==0 ? $0.element:nil }
        let phrases=beats.enumerated().compactMap{ ($0.offset-downbeatPhase)%32==0 ? $0.element:nil }
        let confidence=min(1,Double(best)/(Double(onset.reduce(0,+))+0.0001)*10)
        return .init(bpm:bpm,beats:beats,downbeats:down,phraseStarts:phrases,confidence:confidence)
    }

    static func readMonoSamples(url:URL,maxSeconds:Double=180) throws -> ([Float],Double) {
        let file=try AVAudioFile(forReading:url)
        let format=file.processingFormat
        let frames=AVAudioFrameCount(min(Double(file.length),format.sampleRate*maxSeconds))
        guard let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:frames) else { throw CocoaError(.fileReadCorruptFile) }
        try file.read(into:buffer,frameCount:frames)
        guard let channels=buffer.floatChannelData else { throw CocoaError(.fileReadCorruptFile) }
        let count=Int(buffer.frameLength)
        var mono=[Float](repeating:0,count:count)
        for c in 0..<Int(format.channelCount) { vDSP_vadd(mono,1,channels[c],1,&mono,1,vDSP_Length(count)) }
        var divisor=Float(format.channelCount); vDSP_vsdiv(mono,1,&divisor,&mono,1,vDSP_Length(count))
        return (mono,format.sampleRate)
    }
}

// MARK: - Sampled SWAY Beats / Drummer
@MainActor
final class SwayDrummerEngine:ObservableObject {
    private let engine=AVAudioEngine()
    private let sampler=AVAudioUnitSampler()
    @Published var running=false
    @Published var config=SwayBeatConfiguration()

    init(){
        engine.attach(sampler); engine.connect(sampler,to:engine.mainMixerNode,format:nil)
    }
    func loadSoundBank(_ url:URL) throws {
        try sampler.loadSoundBankInstrument(at:url,program:0,bankMSB:UInt8(kAUSampler_DefaultMelodicBankMSB),bankLSB:UInt8(kAUSampler_DefaultBankLSB))
    }
    func start() throws { if !engine.isRunning { try engine.start() }; running=true }
    func stop(){ sampler.stopNote(36,onChannel:0); sampler.stopNote(38,onChannel:0); running=false }
    func trigger(_ voice:SwayDrumHit.Voice,velocity:Double) {
        let notes:[SwayDrumHit.Voice:UInt8]=[.kick:36,.snare:38,.closedHat:42,.openHat:46,.clap:39,
            .rim:37,.tomLow:45,.tomHigh:50,.shaker:70,.tambourine:54,.cowbell:56,.crash:49]
        sampler.startNote(notes[voice] ?? 36,withVelocity:UInt8(max(1,min(127,velocity*127))),onChannel:0)
    }
}

// MARK: - Pose reference scoring & deterministic adaptation
enum SwayPoseMatcher {
    static func score(reference:SwayReferencePose,observed:[String:Double],timingError:Double,
                      detectorConfidence:Double,previousTotal:Double?)->SwayPoseScore {
        // Decision logic lives in SWAYcoreEngine.SwayMatchTruth: MATCH / NOT MATCHED / UNKNOWN, no credit without
        // sufficient joint coverage, finite confidence >= 0.30. Legacy weights/thresholds preserved.
        let r=SwayMatchTruth.score(referenceAngles:reference.jointAngles,observedAngles:observed,timingError:timingError,
                                   detectorConfidence:detectorConfidence,previousTotal:previousTotal)
        let state:SwayMatchState
        switch r.outcome {
        case .good: state = .good
        case .partial: state = .partial
        case .notMatched: state = .notMatched
        case .unknown: state = .unknown
        }
        return .init(state:state,timing:r.timing,shape:r.shape,direction:r.shape,range:r.shape,
                     continuity:r.continuity,confidence:r.confidence,total:r.total)
    }

    static func adaptation(for recent:[SwayPoseScore])->Int {
        let valid=recent.filter{$0.state != .unknown}
        guard valid.count >= 4 else{return 0}
        let avg=valid.suffix(8).map(\.total).reduce(0,+)/Double(min(8,valid.count))
        if avg > 0.82 { return 1 }
        if avg < 0.45 { return -1 }
        return 0
    }
}


// MARK: - HealthKit workout lifecycle
@MainActor
final class SwayHealthWorkoutManager:ObservableObject {
    @Published private(set) var state:SwayWorkoutLifecycleState = .prepared
    @Published private(set) var heartRate:Double?
    @Published private(set) var errorMessage:String?
    private let store=HKHealthStore()
    private var startDate:Date?
    private var pausedAt:Date?
    private var pausedTotal:TimeInterval=0
    private var workoutEvents:[HKWorkoutEvent]=[]

    var authorizationSummary:String {
        guard HKHealthStore.isHealthDataAvailable() else { return "Unavailable" }
        switch store.authorizationStatus(for:HKObjectType.workoutType()) {
        case .notDetermined: return "Not requested"
        case .sharingDenied: return "Workout saving off"
        case .sharingAuthorized: return "Connected"
        @unknown default: return "Unknown"
        }
    }

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else{return false}
        let share:Set<HKSampleType>=[HKObjectType.workoutType()]
        let read:Set<HKObjectType>=[HKObjectType.quantityType(forIdentifier:.heartRate)!,
                                    HKObjectType.quantityType(forIdentifier:.activeEnergyBurned)!]
        do { try await store.requestAuthorization(toShare:share,read:read); return true }
        catch { errorMessage=error.localizedDescription; return false }
    }
    func prepare(){state = .prepared}
    func countdown(){state = .countdown}
    func start(){
        startDate=Date(); pausedTotal=0; pausedAt=nil; workoutEvents=[]; state = .active
    }
    func pause(){
        guard state == .active else{return}
        let now=Date()
        pausedAt=now
        workoutEvents.append(HKWorkoutEvent(type:.pause,dateInterval:DateInterval(start:now,duration:0),metadata:nil))
        state = .paused
    }
    func resume(){
        let now=Date()
        if let p=pausedAt {pausedTotal += now.timeIntervalSince(p)}
        if pausedAt != nil {
            workoutEvents.append(HKWorkoutEvent(type:.resume,dateInterval:DateInterval(start:now,duration:0),metadata:nil))
        }
        pausedAt=nil;state = .active
    }
    func cooldown(){state = .cooldown}
    func finish(summary:SwayWorkoutSummary) async {
        guard let start=startDate else{state = .finished;return}
        let end=Date()
        // If Finish is pressed while paused, close the inactive interval at the workout end.
        if let p=pausedAt {
            pausedTotal += end.timeIntervalSince(p)
            workoutEvents.append(HKWorkoutEvent(type:.resume,dateInterval:DateInterval(start:end,duration:0),metadata:nil))
            pausedAt=nil
        }
        let config=HKWorkoutConfiguration()
        config.activityType = .mixedCardio
        config.locationType = .indoor
        let builder=HKWorkoutBuilder(healthStore:store,configuration:config,device:.local())
        do {
            try await builder.beginCollection(at:start)
            if !workoutEvents.isEmpty { try await builder.addWorkoutEvents(workoutEvents) }
            try await builder.addMetadata(["SWAYScore":summary.averageScore])
            try await builder.endCollection(at:end)
            _ = try await builder.finishWorkout()
        } catch {
            builder.discardWorkout()
            errorMessage=error.localizedDescription
        }
        state = .finished
    }
}

// MARK: - Live scoring stream
@MainActor
final class SwayScoringEngine:ObservableObject {
    @Published private(set) var latest:SwayPoseScore?
    @Published private(set) var recent:[SwayPoseScore]=[]
    @Published private(set) var adaptationSignal=0
    @Published private(set) var combo=0
    private var previous:Double?

    func ingest(reference:SwayReferencePose,observed:[String:Double],timingError:Double,confidence:Double) {
        let score=SwayPoseMatcher.score(reference:reference,observed:observed,timingError:timingError,
                                        detectorConfidence:confidence,previousTotal:previous)
        latest=score
        recent.append(score); if recent.count>32 {recent.removeFirst(recent.count-32)}
        if score.state == .good {combo += 1} else if score.state == .partial || score.state == .notMatched {combo=max(0,combo-1)}
        // UNKNOWN never punishes the dancer.
        if score.state != .unknown {previous=score.total}
        adaptationSignal=SwayPoseMatcher.adaptation(for:recent)
    }
}

// MARK: - Audio route / interruption recovery and latency
@MainActor
final class SwayPlaybackCoordinator:ObservableObject {
    @Published var interrupted=false
    @Published var latency=SwayLatencyProfile()
    var onPause:(()->Void)?
    var onResume:(()->Void)?
    private var observers:[NSObjectProtocol]=[]

    init(){
        let nc=NotificationCenter.default
        observers.append(nc.addObserver(forName:AVAudioSession.interruptionNotification,object:nil,queue:.main){[weak self] note in
            let raw=note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self else{return}
                if raw == AVAudioSession.InterruptionType.began.rawValue {
                    self.interrupted=true
                    self.onPause?()
                } else {
                    self.interrupted=false
                    self.onResume?()
                }
            }
        })
        observers.append(nc.addObserver(forName:AVAudioSession.routeChangeNotification,object:nil,queue:.main){[weak self] _ in
            Task { @MainActor [weak self] in
                self?.onPause?()
            }
        })
    }
    deinit {observers.forEach(NotificationCenter.default.removeObserver)}
    func compensatedTime(_ heardTime:TimeInterval)->TimeInterval {
        heardTime - latency.audioOutputSeconds + latency.displaySeconds
    }
}

// MARK: - Provider playlist synchronization contract
@MainActor
protocol SwayPlaylistSyncing {
    func exportPlaylist(_ playlist:SwayPlaylist) async throws -> String
}
@MainActor
final class SwayAppleMusicPlaylistSync:SwayPlaylistSyncing {
    func exportPlaylist(_ playlist:SwayPlaylist) async throws -> String {
        guard await MusicAuthorization.request() == .authorized else {
            throw NSError(domain:"SWAYMusic",code:401,userInfo:[NSLocalizedDescriptionKey:"Apple Music authorization required"])
        }
        // Resolve only Apple Music IDs; unavailable entries remain in SWAY and are not silently deleted.
        let ids: [MusicItemID] = playlist.entries.compactMap { entry in
            guard let rawID = entry.recording.providerIDs["appleMusic"] else { return nil }
            return MusicItemID(rawValue: rawID)
        }
        guard !ids.isEmpty else {
            throw NSError(domain:"SWAYMusic",code:404,userInfo:[NSLocalizedDescriptionKey:"No Apple Music tracks in this SWAY playlist"])
        }
        // MusicKit playlist creation APIs differ by OS availability; keep normalized IDs ready
        // and return a deterministic export descriptor rather than mutating user order.
        return "applemusic://playlist/\(playlist.id.uuidString)?tracks=\(ids.count)"
    }
}


struct SwayJointPoint { var x:Double; var y:Double; var confidence:Double }
enum SwayPoseNormalizer {
    static func angle(_ a:SwayJointPoint,_ b:SwayJointPoint,_ c:SwayJointPoint)->Double? {
        guard min(a.confidence,b.confidence,c.confidence) >= 0.25 else{return nil}
        let v1=(a.x-b.x,a.y-b.y), v2=(c.x-b.x,c.y-b.y)
        let dot=v1.0*v2.0+v1.1*v2.1
        let mag=(hypot(v1.0,v1.1)*hypot(v2.0,v2.1))
        guard mag>0 else{return nil}
        return acos(max(-1,min(1,dot/mag)))*180/Double.pi
    }
    static func jointAngles(_ j:[String:SwayJointPoint])->[String:Double] {
        var out:[String:Double]=[:]
        func put(_ key:String,_ a:String,_ b:String,_ c:String){
            if let A=j[a],let B=j[b],let C=j[c],let v=angle(A,B,C){out[key]=v}
        }
        put("leftElbow","leftShoulder","leftElbow","leftWrist")
        put("rightElbow","rightShoulder","rightElbow","rightWrist")
        put("leftKnee","leftHip","leftKnee","leftAnkle")
        put("rightKnee","rightHip","rightKnee","rightAnkle")
        put("leftHip","leftShoulder","leftHip","leftKnee")
        put("rightHip","rightShoulder","rightHip","rightKnee")
        return out
    }
}
enum SwayReferencePoseCatalog {
    /// Matcher and renderer share only authored references. Unknown choreography never silently becomes a neutral COACH.
    static func referenceIfAvailable(moveID:String,musicalTime:TimeInterval,bpm:Double)->SwayReferencePose? {
        guard SwayCoachPoseEngine.supports(moveID:moveID) else { return nil }
        let beatPosition=max(0,musicalTime)/(60.0/max(SwayTimelineMath.minimumBPM,bpm))
        let count=(Int(floor(beatPosition))%8)+1
        return .init(moveID:moveID,count:count,jointAngles:SwayCoachPoseEngine.jointAngles(moveID:moveID,musicalTime:musicalTime,bpm:bpm))
    }
    static func reference(moveID:String,musicalTime:TimeInterval,bpm:Double)->SwayReferencePose {
        referenceIfAvailable(moveID:moveID,musicalTime:musicalTime,bpm:bpm) ?? .init(moveID:moveID,count:1,jointAngles:[:])
    }
}

// MARK: - Record SWAY / Record Me
// Native local-first capture. ReplayKit records the rendered SWAY performance surface;
// microphone capture is opt-in at start. Physical audio/provider behaviour remains a gate.
@MainActor
final class SwayPerformanceRecorder: ObservableObject {
    static let shared = SwayPerformanceRecorder()
    @Published private(set) var isRecording = false
    @Published var lastError: String?
    @Published var preview: RPPreviewViewController?

    private let recorder = RPScreenRecorder.shared()

    func start(microphone: Bool = true) async {
        guard recorder.isAvailable, !isRecording else {
            if !recorder.isAvailable { lastError = "Recording is unavailable on this device." }
            return
        }
        recorder.isMicrophoneEnabled = microphone
        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            recorder.startRecording { error in
                if let error { continuation.resume(returning: .failure(error)) }
                else { continuation.resume(returning: .success(())) }
            }
        }
        switch result {
        case .success:
            isRecording = true
            lastError = nil
        case .failure(let error):
            lastError = error.localizedDescription
            isRecording = false
        }
    }

    func stop() async {
        guard isRecording else { return }
        let result: Result<RPPreviewViewController?, Error> = await withCheckedContinuation { continuation in
            recorder.stopRecording { controller, error in
                if let error { continuation.resume(returning: .failure(error)) }
                else { continuation.resume(returning: .success(controller)) }
            }
        }
        isRecording = false
        switch result {
        case .success(let controller):
            preview = controller
            lastError = nil
        case .failure(let error):
            lastError = error.localizedDescription
        }
    }

    func discardPreview() {
        preview = nil
    }
}
