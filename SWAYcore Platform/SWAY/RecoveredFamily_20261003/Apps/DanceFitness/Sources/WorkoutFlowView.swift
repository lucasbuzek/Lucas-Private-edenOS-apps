import SwiftUI
import SWAYcoreKit
import SWAYAppKit

struct WorkoutFlowView: View {
    @EnvironmentObject var model: AppModel
    let plan: WorkoutPlan; var close: () -> Void
    @State private var runner: WorkoutRunner?
    @State private var tracking = true
    @State private var pattern: BeatPattern
    @State private var bpm: Double
    init(plan: WorkoutPlan, close: @escaping () -> Void) { self.plan = plan; self.close = close; _pattern = State(initialValue: plan.pattern); _bpm = State(initialValue: plan.bpm) }

    var body: some View {
        ZStack {
            StageBackground()
            if let r = runner { RunView(runner: r, close: { r.teardown(); close() }) } else { setup }
        }.preferredColorScheme(.dark)
    }

    var setup: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            let stage = CharacterStageView(characterID: model.state.settings.coach.rawValue, pose: model.lookup[plan.movementIDs[0]]?.pose(atBeat: 0))
            let panel = VStack(alignment: .leading, spacing: 16) {
                Text(plan.title).font(.largeTitle.bold())
                Text("Music").font(.headline)
                Picker("Beat", selection: $pattern) { ForEach(BeatPattern.all, id: \.name) { Text($0.name).tag($0) } }.pickerStyle(.menu)
                HStack { Text("Tempo"); Slider(value: $bpm, in: 70...150, step: 1); Text("\(Int(bpm))").monospacedDigit() }
                Text("Mode").font(.headline)
                Picker("Mode", selection: $tracking) { Text("Tracking").tag(true); Text("Follow-Along").tag(false) }.pickerStyle(.segmented)
                Text(tracking ? "The camera sees your movement on this device to match it. Nothing is recorded." : "Dance along — no camera, no scoring.").font(.footnote).foregroundStyle(SwayTheme.subtext)
                Button { var p = plan; p.pattern = pattern; p.bpm = bpm; let r = WorkoutRunner(plan: p, model: model, tracking: tracking); runner = r; r.begin() } label: { Label("Start", systemImage: "play.fill").frame(maxWidth: .infinity) }.buttonStyle(SwayButtonStyle())
                Button("Cancel", action: close).buttonStyle(SwayButtonStyle(prominent: false))
            }.padding().frame(maxWidth: wide ? 440 : .infinity)
            if wide { HStack { stage; panel } } else { VStack { stage.frame(height: geo.size.height * 0.45); panel } }
        }
    }
}
extension BeatPattern: Hashable { public func hash(into h: inout Hasher) { h.combine(name) } }

struct RunView: View {
    @ObservedObject var runner: WorkoutRunner
    var close: () -> Void
    @EnvironmentObject var model: AppModel
    var body: some View {
        ZStack {
            if let s = runner.finished { ResultsView(summary: s, close: close) } else {
                // ONE performance space: coach large, graphical YOU overlaid. Camera is input, not a window.
                CharacterStageView(characterID: model.state.settings.coach.rawValue, pose: runner.coachPose ?? MoveLibrary.all[0].pose(atBeat: 0),
                                   youCharacterID: runner.trackingRequested ? "yourdancer" : nil, youPose: runner.youPose, youOpacity: runner.youOpacity,
                                   hair: model.state.settings.dancer.hair, outfit: model.state.settings.dancer.outfit)
                overlay
            }
        }
    }
    @ViewBuilder var overlay: some View {
        VStack {
            switch runner.phase {
            case .requestingPermission, .acquiring: banner(runner.permissionDenied ? "CAMERA OFF" : "STEP INTO VIEW", sub: runner.permissionDenied ? "Turn on the camera in Settings, or use Follow-Along." : nil)
            case .calibrating: calibrationOverlay
            case .ready: banner("READY TO SWAY", sub: nil)
            case .countdown: Text("\(runner.countdown ?? 0)").font(.system(size: 160, weight: .black, design: .rounded)).foregroundStyle(SwayTheme.gradient)
            case .running, .paused:
                HStack { VStack(alignment: .leading) { Text(runner.currentName.uppercased()).font(.title2.weight(.heavy)); if let n = runner.nextName { Text("NEXT: \(n)").font(.subheadline).foregroundStyle(SwayTheme.subtext) } }; Spacer()
                    Text("\(runner.count)").font(.system(size: 88, weight: .black, design: .rounded)).foregroundStyle(SwayTheme.gradient) }.padding()
                if let c = runner.cueText { Text(c).font(.title3.bold()).padding(8).background(.ultraThinMaterial, in: Capsule()) }
                Spacer()
                ProgressView(value: runner.progress).tint(SwayTheme.cyan).padding(.horizontal)
                HStack { Button { runner.phase == .paused ? runner.resume() : runner.pause() } label: { Label(runner.phase == .paused ? "Resume" : "Pause", systemImage: runner.phase == .paused ? "play.fill" : "pause.fill") }.buttonStyle(SwayButtonStyle())
                    Button("End") { runner.end() }.buttonStyle(SwayButtonStyle(prominent: false)) }.padding(.bottom)
            default: EmptyView()
            }
            if [.requestingPermission, .acquiring, .calibrating].contains(runner.phase) { Spacer(); Button("Cancel", action: close).buttonStyle(SwayButtonStyle(prominent: false)).padding(.bottom) }
        }
    }
    var calibrationOverlay: some View {
        VStack(spacing: 10) {
            Text(runner.calibration.step.prompt).font(.system(size: 44, weight: .black, design: .rounded)).foregroundStyle(SwayTheme.gradient).multilineTextAlignment(.center).padding(.top, 40)
            HStack { ForEach(CalibrationStep.allCases.dropLast(), id: \.self) { s in Circle().fill(runner.calibration.completed.contains(s) ? SwayTheme.cyan : Color.white.opacity(0.25)).frame(width: 12, height: 12) } }
            if !runner.calibration.inView && runner.calibration.step != .stepIntoView { Text("STEP INTO VIEW").font(.headline).foregroundStyle(SwayTheme.magenta) }
        }.accessibilityElement(children: .combine)
    }
    func banner(_ t: String, sub: String?) -> some View {
        VStack(spacing: 6) { Text(t).font(.system(size: 44, weight: .black, design: .rounded)).foregroundStyle(SwayTheme.gradient); if let sub { Text(sub).font(.callout).foregroundStyle(SwayTheme.subtext) } }.padding(.top, 40)
    }
}

struct ResultsView: View {
    @EnvironmentObject var model: AppModel
    let summary: WorkoutRunner.Summary; var close: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Text("NICE WORK").font(.largeTitle.weight(.black)).foregroundStyle(SwayTheme.gradient)
            if summary.cameraUsed {
                if let a = summary.score.accuracy, let stars = summary.score.stars {
                    Text("\(Int(a * 100))% matched").font(.title.bold()); Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars)).font(.title)
                    Text("Camera saw you for \(Int(summary.score.coverage * 100))% of the dance.").foregroundStyle(SwayTheme.subtext)
                } else { Text("Not enough camera evidence to score this one.").font(.title3).multilineTextAlignment(.center); Text("Stay fully in view next time to earn a score.").foregroundStyle(SwayTheme.subtext) }
            } else { Text("You danced along for \(Int(summary.duration)) seconds.").font(.title3); Text("Follow-Along isn't scored.").foregroundStyle(SwayTheme.subtext) }
            VStack(alignment: .leading) { ForEach(summary.movementIDs, id: \.self) { id in HStack { Text(model.lookup[id]?.name ?? id); Spacer(); Text(String(describing: model.mastery(id)).capitalized).foregroundStyle(SwayTheme.cyan) } } }.padding().background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            Button("Done", action: close).buttonStyle(SwayButtonStyle())
        }.padding()
    }
}
