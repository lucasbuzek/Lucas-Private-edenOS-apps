import Foundation
import ReplayKit
import Photos

/// Record Me / Record SWAY via ReplayKit (screen + mic when the user explicitly starts). UNVERIFIED until demonstrated on a physical device.
@MainActor public final class RecordingService: ObservableObject {
    @Published public private(set) var isRecording = false
    @Published public var lastFile: URL?
    @Published public var error: String?
    public init() {}
    public func start(withMicrophone: Bool) async {
        let r = RPScreenRecorder.shared(); guard r.isAvailable else { error = "Recording is unavailable on this device."; return }
        r.isMicrophoneEnabled = withMicrophone
        do { try await r.startRecording(); isRecording = true; error = nil } catch { self.error = error.localizedDescription }
    }
    public func stop() async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SWAY-\(Int(Date().timeIntervalSince1970)).mp4")
        do { try await RPScreenRecorder.shared().stopRecording(withOutput: url); isRecording = false; lastFile = url } catch { isRecording = false; self.error = error.localizedDescription }
    }
    public func saveToPhotos() async {
        guard let f = lastFile else { return }
        let st = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard st == .authorized || st == .limited else { error = "Photos access denied. You can still share the file."; return }
        do { try await PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: f) } } catch { self.error = error.localizedDescription }
    }
}
