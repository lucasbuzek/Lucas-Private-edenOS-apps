import AVFoundation
import Vision
import SWAYcoreKit

/// Camera -> Vision joints -> TrackingObservation. Frames are analysed on-device and discarded; nothing is stored.
public final class CameraPoseService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    public let session = AVCaptureSession()
    public var onObservation: (@Sendable (TrackingObservation?) -> Void)?
    private let queue = DispatchQueue(label: "sway.camera.pose")
    private let request = VNDetectHumanBodyPoseRequest()
    private var configured = false
    public private(set) var isRunning = false

    public static func authorization() -> AVAuthorizationStatus { AVCaptureDevice.authorizationStatus(for: .video) }
    public static func requestAccess() async -> Bool { await AVCaptureDevice.requestAccess(for: .video) }

    public func start(position: AVCaptureDevice.Position = .front) throws {
        if !configured {
            session.beginConfiguration(); session.sessionPreset = .vga640x480
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) ?? AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: dev), session.canAddInput(input) else { session.commitConfiguration(); throw NSError(domain: "SWAY", code: 1, userInfo: [NSLocalizedDescriptionKey: "No camera available"]) }
            session.addInput(input)
            let out = AVCaptureVideoDataOutput(); out.alwaysDiscardsLateVideoFrames = true
            out.setSampleBufferDelegate(self, queue: queue)
            guard session.canAddOutput(out) else { session.commitConfiguration(); throw NSError(domain: "SWAY", code: 2) }
            session.addOutput(out); session.commitConfiguration(); configured = true
        }
        queue.async { [session] in if !session.isRunning { session.startRunning() } }
        isRunning = true
    }
    public func stop() { queue.async { [session] in if session.isRunning { session.stopRunning() } }; isRunning = false }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored, options: [:])   // front camera, portrait (verify on device)
        let t = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        guard (try? handler.perform([request])) != nil, let obs = request.results?.first else { onObservation?(nil); return }
        onObservation?(Self.observation(from: obs, timestamp: t))
    }

    /// Vision labels are anatomical (subject's left/right). Image is mirrored by orientation, so x is flipped back
    /// to the Core convention (+x = subject's left = image-right of an unmirrored view).
    static func observation(from o: VNHumanBodyPoseObservation, timestamp: TimeInterval) -> TrackingObservation {
        let map: [(VNHumanBodyPoseObservation.JointName, SWAYJoint)] = [
            (.neck, .neck), (.nose, .head), (.root, .hips),
            (.leftShoulder, .shoulderL), (.leftElbow, .elbowL), (.leftWrist, .wristL), (.leftHip, .hipL), (.leftKnee, .kneeL), (.leftAnkle, .ankleL),
            (.rightShoulder, .shoulderR), (.rightElbow, .elbowR), (.rightWrist, .wristR), (.rightHip, .hipR), (.rightKnee, .kneeR), (.rightAnkle, .ankleR)]
        var raw: [SWAYJoint: JointSample] = [:]
        for (vn, j) in map {
            if let p = try? o.recognizedPoint(vn), p.confidence > 0 { raw[j] = JointSample(Vec3(1 - p.location.x, p.location.y, 0), confidence: Double(p.confidence)) }
        }
        return TrackingObservation(timestamp: timestamp, raw: raw)
    }
}
