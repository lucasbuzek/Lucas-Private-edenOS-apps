import SwiftUI
import SWAYcoreKit
import SWAYAppKit

/// Learn: Tempo -> beat -> count -> COACH on ONE practice clock. Pause freezes count and character.
struct LearnView: View {
    @EnvironmentObject var model: AppModel
    let movement: MovementDefinition
    var practice: () -> Void
    @State private var clock = PracticeClock(bpm: 70)
    @State private var mirrored = false
    @State private var frozenAt: TimeInterval = ProcessInfo.processInfo.systemUptime
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            StageBackground()
            GeometryReader { geo in
                let wide = geo.size.width > geo.size.height
                let stage = TimelineView(.animation(paused: !clock.isPlaying)) { _ in
                    let now = ProcessInfo.processInfo.systemUptime
                    let beat = clock.beat(at: now)
                    CharacterStageView(characterID: model.state.settings.coach.rawValue, pose: movement.pose(atBeat: beat, mirrored: mirrored))
                        .overlay(alignment: .topLeading) { countBadge(beat) }
                }
                let controls = VStack(spacing: 14) {
                    Text(movement.name).font(.title.bold())
                    TimelineView(.animation(paused: !clock.isPlaying)) { _ in
                        let beat = clock.beat(at: ProcessInfo.processInfo.systemUptime)
                        Text(instruction(atBeat: beat)).font(.title3).multilineTextAlignment(.center).foregroundStyle(SwayTheme.subtext).frame(minHeight: 60)
                    }
                    HStack { ForEach(1...movement.beatsPerCycle, id: \.self) { c in
                        Button("\(c)") { clock.select(count: c, cycle: movement.beatsPerCycle, at: ProcessInfo.processInfo.systemUptime); frozenAt = ProcessInfo.processInfo.systemUptime }
                            .buttonStyle(.bordered).tint(SwayTheme.cyan).frame(minWidth: 36, minHeight: 44).accessibilityLabel("Count \(c)") } }
                    HStack(spacing: 16) {
                        Button { toggle() } label: { Label(clock.isPlaying ? "Pause" : "Play", systemImage: clock.isPlaying ? "pause.fill" : "play.fill") }.buttonStyle(SwayButtonStyle())
                        Toggle("Mirror", isOn: $mirrored).toggleStyle(.button)
                    }
                    HStack { Text("Tempo"); Slider(value: Binding(get: { clock.bpm }, set: { clock.setBPM($0, at: ProcessInfo.processInfo.systemUptime) }), in: 40...130, step: 1); Text("\(Int(clock.bpm)) BPM").monospacedDigit() }
                    HStack { Button("Practice with music") { practice() }.buttonStyle(SwayButtonStyle(prominent: false)); Button("Close") { dismiss() }.buttonStyle(SwayButtonStyle(prominent: false)) }
                }.padding().frame(maxWidth: wide ? 460 : .infinity)
                if wide { HStack { stage; controls } } else { VStack { stage.frame(height: geo.size.height * 0.56); controls } }
            }
        }
        .onAppear { clock.select(count: 1, cycle: movement.beatsPerCycle, at: ProcessInfo.processInfo.systemUptime) }
    }
    func toggle() { let n = ProcessInfo.processInfo.systemUptime; if clock.isPlaying { clock.pause(at: n) } else { clock.play(at: n) } }
    func countBadge(_ beat: Double) -> some View {
        let c = Counting.position(atBeat: beat, cycle: movement.beatsPerCycle).count
        return Text("\(c)").font(.system(size: 72, weight: .black, design: .rounded)).foregroundStyle(SwayTheme.gradient).padding(16).accessibilityLabel("Count \(c)")
    }
    /// Instruction always describes the pose currently shown.
    func instruction(atBeat beat: Double) -> String {
        let c = Counting.position(atBeat: beat, cycle: movement.beatsPerCycle).count
        if let k = movement.keyframes.first(where: { $0.count == c }), let cue = k.cue { return cue }
        return "Count \(c): \(movement.instruction)"
    }
}
