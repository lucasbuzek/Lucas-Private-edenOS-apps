import SwiftUI
import SWAYcoreKit
import SWAYAppKit

struct SWAYZRoot: View {
    @EnvironmentObject var m: AuthoringModel
    enum Section: String, CaseIterable { case choreograph = "CHOREOGRAPH", create = "CREATE", teach = "TEACH" }
    @State private var section: Section = .choreograph
    var body: some View {
        ZStack { StageBackground()
            VStack(spacing: 0) {
                Picker("", selection: $section) { ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).padding()
                switch section { case .choreograph: ChoreographView(); case .create: MoveEditorView(); case .teach: RehearseView() }
            }
        }
    }
}

/// Stage-first choreography: big instructor canvas + direct-manipulation timeline + music grid.
struct ChoreographView: View {
    @EnvironmentObject var m: AuthoringModel
    @State private var beat = 0.0
    @State private var playing = false
    @State private var importing = false
    @State private var shareURL: URL?
    @State private var bpm = 100.0
    var timeline: ChoreographyTimeline { ChoreographyTimeline(steps: m.doc.steps, movements: m.library) }
    var pose: Pose? {
        guard let (seg, local) = timeline.segment(atBeat: beat), let mv = m.library[seg.movementID] else { return nil }
        return mv.pose(atBeat: local, mirrored: seg.mirrored)
    }
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            let stage = TimelineView(.animation(paused: !playing)) { ctx in
                CharacterStageView(characterID: "thabo", pose: pose ?? MoveLibrary.all[0].pose(atBeat: 0))
                    .onChange(of: ctx.date) { _, _ in if playing { advance() } }
            }
            let side = VStack(spacing: 10) {
                TextField("Routine title", text: $m.doc.title).textFieldStyle(.roundedBorder)
                timelineStrip
                HStack { Button(playing ? "Pause" : "Rehearse") { playing.toggle(); lastTick = ProcessInfo.processInfo.systemUptime }.buttonStyle(SwayButtonStyle())
                    Stepper("\(Int(bpm)) BPM", value: $bpm, in: 40...180, step: 2).onChange(of: bpm) { _, v in m.doc.grid = MusicGrid(bpm: v, phase: 0) } }
                Slider(value: $beat, in: 0...Double(max(timeline.totalBeats, 1)))
                Text(String(format: "Beat %.1f · bar %d · count %d", beat, Int(beat) / 4 + 1, Counting.position(atBeat: beat).count)).font(.caption.monospacedDigit()).foregroundStyle(SwayTheme.subtext)
                List { Section("Add move") { ForEach(Array(m.library.values).sorted { $0.name < $1.name }) { mv in
                    Button { m.doc.steps.append(ContentStep(movementID: mv.id, repetitions: 2)) } label: { HStack { Text(mv.name); Spacer(); Image(systemName: "plus.circle") } } } } }.scrollContentBackground(.hidden)
                HStack {
                    Button("Import") { importing = true }.buttonStyle(.bordered)
                    Button("Export") { do { shareURL = try m.exportURL() } catch { m.message = "Export failed: \(error)" } }.buttonStyle(.bordered)
                    if let shareURL { ShareLink(item: shareURL) }
                }
                if let msg = m.message { Text(msg).font(.footnote) }
            }.padding().frame(maxWidth: wide ? 460 : .infinity)
            if wide { HStack { stage; side } } else { VStack { stage.frame(height: geo.size.height * 0.45); side } }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .data]) { if case .success(let u) = $0 { m.importPack(u) } }
        .onAppear { bpm = m.doc.grid?.bpm ?? 100 }
    }
    @State private var lastTick = ProcessInfo.processInfo.systemUptime
    func advance() {
        let n = ProcessInfo.processInfo.systemUptime; beat += (n - lastTick) * bpm / 60; lastTick = n
        if beat >= Double(timeline.totalBeats) { beat = 0; playing = false }
    }
    /// Direct-manipulation timeline: drag to reorder, tap to toggle mirror, swipe to delete.
    var timelineStrip: some View {
        List {
            ForEach(Array(m.doc.steps.enumerated()), id: \.offset) { i, s in
                HStack { Text(m.library[s.movementID]?.name ?? s.movementID); Spacer()
                    Stepper("×\(s.repetitions)", value: Binding(get: { s.repetitions }, set: { m.doc.steps[i].repetitions = $0 }), in: 1...16).labelsHidden(); Text("×\(s.repetitions)")
                    Toggle("Mirror", isOn: Binding(get: { s.mirrored }, set: { m.doc.steps[i].mirrored = $0 })).toggleStyle(.button).labelsHidden(); Image(systemName: "arrow.left.and.right") }
            }.onMove { m.doc.steps.move(fromOffsets: $0, toOffset: $1) }.onDelete { m.doc.steps.remove(atOffsets: $0) }
        }.scrollContentBackground(.hidden).frame(minHeight: 160)
    }
}

struct MoveEditorView: View {
    @EnvironmentObject var m: AuthoringModel
    @State private var count = 1
    @State private var stance = Stance.neutral
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            let stage = CharacterStageView(characterID: "thabo", pose: PoseBuilder.build(stance))
            let form = Form {
                TextField("Name", text: $m.draft.name); TextField("Instruction", text: $m.draft.instruction)
                Picker("Count", selection: $count) { ForEach(1...m.draft.beatsPerCycle, id: \.self) { Text("\($0)\(m.draft.authoredCounts.contains($0) ? " ●" : "")").tag($0) } }.pickerStyle(.segmented)
                limbPicker("Left arm", { stance.armL }, { stance.armL = $0 }, CreateTables.arms)
                limbPicker("Right arm", { stance.armR }, { stance.armR = $0 }, CreateTables.arms)
                limbPicker("Left leg", { stance.legL }, { stance.legL = $0 }, CreateTables.legs)
                limbPicker("Right leg", { stance.legR }, { stance.legR = $0 }, CreateTables.legs)
                Slider(value: $stance.lean, in: -20...20) { Text("Lean") }
                Toggle("Hold", isOn: Binding(get: { m.draft.holds.contains(count) }, set: { m.draft.setHold(count: count, $0) }))
                TextField("Cue at this count", text: Binding(get: { m.draft.cues[count] ?? "" }, set: { m.draft.setCue(count: count, $0) }))
                Button("Set count \(count)") { try? m.draft.set(count: count, stance: stance) }
                Button("Clear count") { m.draft.clear(count: count) }
                Button("Save move") { m.commitDraft() }
                Button("New move") { m.draft = MoveDraft(name: "New Move") }
                if let msg = m.message { Text(msg).font(.footnote) }
            }.scrollContentBackground(.hidden)
            if wide { HStack { stage; form.frame(width: 420) } } else { VStack { stage.frame(height: geo.size.height * 0.4); form } }
        }
    }
    func limbPicker(_ title: String, _ get: @escaping () -> LimbPose, _ set: @escaping (LimbPose) -> Void, _ table: [(String, LimbPose)]) -> some View {
        Picker(title, selection: Binding(get: { table.firstIndex { $0.1 == get() } ?? 0 }, set: { set(table[$0].1) })) { ForEach(table.indices, id: \.self) { Text(table[$0].0).tag($0) } }
    }
}
enum CreateTables {
    static let arms: [(String, LimbPose)] = [("Down", Arm.down), ("Side", Arm.side), ("High", Arm.high), ("Forward", Arm.forward), ("Bent", Arm.flex), ("Hip", Arm.hipHand), ("Cross", Arm.cross), ("Diagonal", Arm.diagUp)]
    static let legs: [(String, LimbPose)] = [("Stand", Leg.stand), ("Wide", Leg.wide), ("Lift", Leg.lift), ("Low lift", Leg.liftLow), ("Squat", Leg.squat), ("Lunge", Leg.lunge), ("Touch", Leg.touch), ("Back", Leg.back), ("Kick", Leg.kick)]
}

/// TEACH: rehearsal at a controlled tempo with the production instructor (same Learn/Practice clock as the learner app).
struct RehearseView: View {
    @EnvironmentObject var m: AuthoringModel
    @State private var selected = MoveLibrary.all[0].id
    @State private var clock = PracticeClock(bpm: 70)
    var body: some View {
        let mv = m.library[selected] ?? MoveLibrary.all[0]
        VStack {
            TimelineView(.animation(paused: !clock.isPlaying)) { _ in CharacterStageView(characterID: "thabo", pose: mv.pose(atBeat: clock.beat(at: ProcessInfo.processInfo.systemUptime))) }
            Picker("Move", selection: $selected) { ForEach(Array(m.library.values).sorted { $0.name < $1.name }) { Text($0.name).tag($0.id) } }.pickerStyle(.menu)
            HStack { Button(clock.isPlaying ? "Pause" : "Play") { let n = ProcessInfo.processInfo.systemUptime; clock.isPlaying ? clock.pause(at: n) : clock.play(at: n) }.buttonStyle(SwayButtonStyle())
                Slider(value: Binding(get: { clock.bpm }, set: { clock.setBPM($0, at: ProcessInfo.processInfo.systemUptime) }), in: 40...140); Text("\(Int(clock.bpm))") }.padding()
        }
    }
}
