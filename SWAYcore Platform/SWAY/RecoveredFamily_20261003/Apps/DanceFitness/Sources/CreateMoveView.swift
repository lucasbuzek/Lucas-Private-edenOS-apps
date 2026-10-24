import SwiftUI
import SWAYcoreKit
import SWAYAppKit

/// Create Move: capture (camera) or compose -> movement definition -> count/pose preview -> save -> use/share.
struct CreateMoveView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var name = "My Move"
    @State private var stances: [Int: Stance] = [1: .neutral, 5: .neutral]
    @State private var count = 1
    @State private var message: String?
    @State private var shareURL: URL?
    @State private var capturing = false
    @State private var captured: [Pose] = []
    @State private var camera = CameraPoseService()
    @State private var captureStart = 0.0

    static let armNames: [(String, LimbPose)] = [("Down", Arm.down), ("Side", Arm.side), ("High", Arm.high), ("Forward", Arm.forward), ("Bent", Arm.flex), ("Hip", Arm.hipHand), ("Cross", Arm.cross), ("Diagonal", Arm.diagUp)]
    static let legNames: [(String, LimbPose)] = [("Stand", Leg.stand), ("Wide", Leg.wide), ("Lift", Leg.lift), ("Low lift", Leg.liftLow), ("Squat", Leg.squat), ("Lunge", Leg.lunge), ("Touch", Leg.touch), ("Back", Leg.back), ("Kick", Leg.kick)]

    var current: Stance { stances[count] ?? .neutral }
    func binding(_ get: @escaping (Stance) -> LimbPose, _ set: @escaping (inout Stance, LimbPose) -> Void, _ table: [(String, LimbPose)]) -> Binding<Int> {
        Binding(get: { table.firstIndex { $0.1 == get(current) } ?? 0 }, set: { var s = current; set(&s, table[$0].1); stances[count] = s })
    }
    func draft() throws -> MovementDefinition {
        var d = MoveDraft(id: UUID().uuidString, name: name)
        for (c, s) in stances { try d.set(count: c, stance: s) }
        return try d.build()
    }
    var previewPose: Pose { (try? draft().pose(atCount: count)) ?? PoseBuilder.build(current) }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let wide = geo.size.width > geo.size.height
                let stage = CharacterStageView(characterID: model.state.settings.coach.rawValue, pose: PoseBuilder.build(current))
                let form = Form {
                    TextField("Name", text: $name)
                    Picker("Count", selection: $count) { ForEach(1...8, id: \.self) { Text("\($0)\(stances[$0] != nil ? " ●" : "")").tag($0) } }.pickerStyle(.segmented)
                    Picker("Left arm", selection: binding({ $0.armL }, { $0.armL = $1 }, Self.armNames)) { ForEach(Self.armNames.indices, id: \.self) { Text(Self.armNames[$0].0).tag($0) } }
                    Picker("Right arm", selection: binding({ $0.armR }, { $0.armR = $1 }, Self.armNames)) { ForEach(Self.armNames.indices, id: \.self) { Text(Self.armNames[$0].0).tag($0) } }
                    Picker("Left leg", selection: binding({ $0.legL }, { $0.legL = $1 }, Self.legNames)) { ForEach(Self.legNames.indices, id: \.self) { Text(Self.legNames[$0].0).tag($0) } }
                    Picker("Right leg", selection: binding({ $0.legR }, { $0.legR = $1 }, Self.legNames)) { ForEach(Self.legNames.indices, id: \.self) { Text(Self.legNames[$0].0).tag($0) } }
                    Slider(value: Binding(get: { current.lean }, set: { var s = current; s.lean = $0; stances[count] = s }), in: -20...20) { Text("Lean") }
                    Button("Set count \(count)") { stances[count] = current }
                    Section("Capture with camera") {
                        Button(capturing ? "Stop & build" : "Record \(8)-count capture") { toggleCapture() }
                        Text("Frames are analysed on-device and discarded; only joint positions are kept.").font(.caption).foregroundStyle(.secondary)
                    }
                    Section {
                        Button("Save to Library") { do { let m = try draft(); model.save(move: m); message = "Saved \(m.name)" } catch { message = "Add at least one count first." } }
                        Button("Export .swaypack") { do { let m = try draft(); model.save(move: m); shareURL = try model.exportPack(title: name, ids: [m.id]) } catch { message = "Couldn't export: \(error)" } }
                        if let shareURL { ShareLink(item: shareURL) }
                        if let message { Text(message).font(.footnote) }
                    }
                }.scrollContentBackground(.hidden)
                ZStack { StageBackground(); if wide { HStack { stage; form.frame(width: 380) } } else { VStack { stage.frame(height: geo.size.height * 0.4); form } } }
            }
            .navigationTitle("Create Move").toolbar { Button("Close") { camera.stop(); dismiss() } }
        }
    }
    func toggleCapture() {
        if capturing {
            camera.stop(); capturing = false
            do { let m = try PoseCapture.movement(id: UUID().uuidString, name: name, poses: captured); model.save(move: m); message = "Captured and saved \(m.name)" }
            catch { message = "Couldn't build a move from that capture — stay fully in view and try again." }
        } else {
            captured = []
            Task {
                guard await CameraPoseService.requestAccess() else { message = "Camera access is off. Use the count editor instead."; return }
                let last = TimeBox()
                camera.onObservation = { o in
                    guard let o, let p = PoseNormalizer.normalize(o.raw), o.timestamp - last.v > 0.1 else { return }
                    last.v = o.timestamp; Task { @MainActor in captured.append(p) }
                }
                try? camera.start(); capturing = true
            }
        }
    }
}

final class TimeBox: @unchecked Sendable { var v = 0.0 }
