import SwiftUI

struct NativeLabView: View {
    @StateObject private var motion=MotionService()
    @StateObject private var pose=CameraPoseService()
    @State private var health="Not connected"
    @State private var camera=false
    var body: some View {
        List {
            Section("0.5 iOS integration") {
                Label("HealthKit workout lifecycle",systemImage:"heart.fill")
                Label("MusicKit + local audio providers",systemImage:"music.note")
                Label("Pose normalization + scoring engine",systemImage:"figure.dance")
                Label("Interruption / route recovery",systemImage:"airpodspro")
                Label("Packs + sharing",systemImage:"square.stack.3d.up")
                Text("Feature-complete iOS pass: physical-device testing remains authoritative.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Device sensing") {
                LabeledContent("Motion energy", value:String(format:"%.2f", motion.cadenceEnergy))
                Toggle("Camera pose detection", isOn:$camera).onChange(of:camera) { _,on in Task { if on { await pose.requestAndStart() } else { pose.stop() } } }
                LabeledContent("Body", value:pose.bodyDetected ? "Detected" : "Not detected")
            }
            Section("Health") { LabeledContent("HealthKit", value:health); Button("Connect Health") { Task { do { try await HealthService().request(); health="Authorized / permission-scoped" } catch { health="Unavailable or denied" } } } }
            Section("Native capability policy") { Text("Camera and Health are optional. Core workouts remain usable without either permission. Pose analysis is performed on-device by Vision in this build.") }
        }.navigationTitle("Native Lab")
        .tint(SwayTheme.accent)
        .preferredColorScheme(.dark).onAppear{motion.start()}.onDisappear{motion.stop();pose.stop()}
    }
}
