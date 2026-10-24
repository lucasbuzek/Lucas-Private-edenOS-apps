import SwiftUI
import AVFoundation
import Vision

// Adapted from R2/App/SWAY/Views/CameraLabView.swift.
// Preserve one preview coordinate authority (AVCaptureVideoPreviewLayer).
@MainActor
final class SwayPreviewRotationController {
    private var coordinator: AVCaptureDevice.RotationCoordinator?
    private var observation: NSKeyValueObservation?
    private var deviceID: String?
    private weak var layer: AVCaptureVideoPreviewLayer?

    func update(layer: AVCaptureVideoPreviewLayer) {
        self.layer = layer
        guard let device = layer.session?.inputs.compactMap({
            ($0 as? AVCaptureDeviceInput)?.device
        }).first else { return }
        if deviceID != device.uniqueID {
            deviceID = device.uniqueID
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: layer)
            self.coordinator = coordinator
            let expectedID = device.uniqueID
            observation = coordinator.observe(
                \.videoRotationAngleForHorizonLevelPreview,
                options: [.initial, .new]
            ) { [weak self] _, change in
                guard let angle = change.newValue else { return }
                Task { @MainActor [weak self] in
                    guard let self, self.deviceID == expectedID else { return }
                    self.apply(angle)
                }
            }
        }
        if let coordinator { apply(coordinator.videoRotationAngleForHorizonLevelPreview) }
    }

    private func apply(_ angle: CGFloat) {
        guard let connection = layer?.connection,
              connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }
}

final class ZEROStageUIView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()
    private let bonesLayer = CAShapeLayer()
    private let pointsLayer = CAShapeLayer()
    private let rotation = SwayPreviewRotationController()

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        bonesLayer.strokeColor = UIColor.systemCyan.cgColor
        bonesLayer.fillColor = UIColor.clear.cgColor
        bonesLayer.lineWidth = 4
        bonesLayer.lineCap = .round
        pointsLayer.fillColor = UIColor.systemGreen.cgColor
        layer.addSublayer(bonesLayer)
        layer.addSublayer(pointsLayer)
    }

    required init?(coder: NSCoder) { fatalError("Unavailable") }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        bonesLayer.frame = bounds
        pointsLayer.frame = bounds
        rotation.update(layer: previewLayer)
    }

    func configure(session: AVCaptureSession, joints: [String: CGPoint]) {
        if previewLayer.session !== session { previewLayer.session = session }
        rotation.update(layer: previewLayer)
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
        // Use the same official JointName vocabulary and capture-layer mapping as R2.
        let bones: [(VNHumanBodyPoseObservation.JointName,
                     VNHumanBodyPoseObservation.JointName)] = [
            (.neck,.nose), (.neck,.leftShoulder), (.leftShoulder,.leftElbow),
            (.leftElbow,.leftWrist), (.neck,.rightShoulder),
            (.rightShoulder,.rightElbow), (.rightElbow,.rightWrist),
            (.neck,.root), (.root,.leftHip), (.leftHip,.leftKnee),
            (.leftKnee,.leftAnkle), (.root,.rightHip), (.rightHip,.rightKnee),
            (.rightKnee,.rightAnkle)
        ]
        func location(_ value: CGPoint) -> CGPoint {
            previewLayer.layerPointConverted(fromCaptureDevicePoint: value)
        }
        let lines = CGMutablePath()
        for (a, b) in bones {
            guard let pa = joints[a.rawValue.rawValue],
                  let pb = joints[b.rawValue.rawValue] else { continue }
            lines.move(to: location(pa))
            lines.addLine(to: location(pb))
        }
        bonesLayer.path = lines

        let markers = CGMutablePath()
        for pose in joints.values {
            let point = location(pose)
            markers.addEllipse(in: CGRect(x: point.x-4, y: point.y-4,
                                          width: 8, height: 8))
        }
        pointsLayer.path = markers
    }
}

struct ZEROCameraStage: UIViewRepresentable {
    let session: AVCaptureSession
    let joints: [String: CGPoint]
    func makeUIView(context: Context) -> ZEROStageUIView { ZEROStageUIView() }
    func updateUIView(_ view: ZEROStageUIView, context: Context) {
        view.configure(session: session, joints: joints)
    }
}
