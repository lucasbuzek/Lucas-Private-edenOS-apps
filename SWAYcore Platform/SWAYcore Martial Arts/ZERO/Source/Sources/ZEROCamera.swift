import Foundation
import SwiftUI
import AVFoundation
import Vision
import ImageIO
import QuartzCore

/// Isolated iOS test-host adapter for SWAYcore's on-device Vision pose input.
/// The native R2 camera service remains untouched and authoritative for Dance & Fitness.
final class ZEROCamera: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    @Published private(set) var joints: [String: CGPoint] = [:]
    @Published private(set) var confidence: Float = 0
    @Published private(set) var status: String = "CAMERA OFF"
    @Published private(set) var framesPerSecond: Double = 0
    let session = AVCaptureSession()
    private let captureQueue = DispatchQueue(label: "sway.zero.capture", qos: .userInitiated)
    private let visionQueue = DispatchQueue(label: "sway.zero.vision", qos: .userInitiated)
    private let poseRequest = VNDetectHumanBodyPoseRequest()
    private var isConfigured = false
    private var frames = 0
    private var fpsAnchor = CACurrentMediaTime()

    @MainActor
    func start() async {
        let authorization = AVCaptureDevice.authorizationStatus(for: .video)
        let allowed: Bool
        switch authorization {
        case .authorized: allowed = true
        case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .video)
        default: allowed = false
        }
        guard allowed else {
            status = "CAMERA PERMISSION REQUIRED"
            return
        }
        status = "CONNECTING CAMERA"
        captureQueue.async { [weak self] in self?.configureAndRun() }
    }

    private func configureAndRun() {
        if !isConfigured {
            session.beginConfiguration()
            session.sessionPreset = .high
            defer { session.commitConfiguration() }
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                publishStatus("FRONT CAMERA UNAVAILABLE"); return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(input) else { publishStatus("CAMERA INPUT FAILED"); return }
                session.addInput(input)
            } catch {
                publishStatus("CAMERA INPUT ERROR"); return
            }
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: visionQueue)
            guard session.canAddOutput(output) else { publishStatus("CAMERA OUTPUT FAILED"); return }
            session.addOutput(output)
            if let conn = output.connection(with: .video), conn.isVideoMirroringSupported {
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = false
            }
            isConfigured = true
        }
        if !session.isRunning { session.startRunning() }
        publishStatus(session.isRunning ? "CAMERA LIVE · ON-DEVICE" : "CAMERA FAILED")
    }

    func stop() {
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async {
                self.status = "CAMERA OFF"
                self.joints = [:]
                self.confidence = 0
                self.framesPerSecond = 0
            }
        }
    }

    private func publishStatus(_ text: String) {
        DispatchQueue.main.async { [weak self] in self?.status = text }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Reuses native R2's portrait-front-camera Vision orientation convention.
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored)
        do {
            try handler.perform([poseRequest])
            let candidates = try poseRequest.results?.first?.recognizedPoints(.all) ?? [:]
            var points: [String: CGPoint] = [:]
            var sum: Float = 0
            for (name, point) in candidates where point.confidence >= 0.25 {
                points[name.rawValue.rawValue] = CGPoint(x: point.location.x, y: 1 - point.location.y)
                sum += point.confidence
            }
            let avg = points.isEmpty ? Float(0) : sum / Float(points.count)
            frames += 1
            let now = CACurrentMediaTime()
            let window = now - fpsAnchor
            let fps: Double? = window > 0.85 ? Double(frames) / window : nil
            if fps != nil { frames = 0; fpsAnchor = now }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.joints = points
                self.confidence = avg
                if let fps = fps { self.framesPerSecond = fps }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.joints = [:]
                self?.confidence = 0
                self?.status = "VISION ERROR"
            }
        }
    }
}
