import SwiftUI
import SWAYcoreKit
import SWAYAppKit

@main struct KidDancersApp: App {
    @StateObject private var kids = KidsModel()
    var body: some Scene { WindowGroup { KidsRoot().environmentObject(kids).preferredColorScheme(.dark) } }
}

/// Local-only. No accounts, no analytics, no network. Only safe necessary settings (see KidsPolicy).
@MainActor final class KidsModel: ObservableObject {
    struct Saved: Codable { var settings = KidsSettings(); var stars: [String: Int] = [:] }
    @Published var saved = Saved() { didSet { try? store.save(saved) } }
    private let store: JSONFileStore<Saved>
    let beats = BeatPlayer(); let speech = SpeechService()
    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("SWAYKids")
        store = JSONFileStore(url: dir.appendingPathComponent("kids.json")); if let s = try? store.load() { saved = s }
    }
    var moves: [MovementDefinition] { KidsPolicy.library() }
}

struct KidsRoot: View {
    @EnvironmentObject var kids: KidsModel
    @State private var dance: MovementDefinition?
    @State private var grownUps = false
    private let bright = [Color(red: 1, green: 0.4, blue: 0.7), Color(red: 0.35, green: 0.8, blue: 1), Color(red: 1, green: 0.8, blue: 0.2), Color(red: 0.6, green: 0.45, blue: 1)]
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.25, green: 0.1, blue: 0.5), Color(red: 0.1, green: 0.05, blue: 0.25)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack {
                HStack { Text("LET'S DANCE!").font(.system(size: 34, weight: .black, design: .rounded)); Spacer()
                    Button { grownUps = true } label: { Image(systemName: "lock.fill").font(.title2).frame(width: 56, height: 56) }.accessibilityLabel("Grown-ups") }.padding()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 16)], spacing: 16) {
                        ForEach(Array(kids.moves.enumerated()), id: \.element.id) { i, m in
                            Button { dance = m } label: {
                                VStack(spacing: 8) { Image(systemName: "figure.dance").font(.system(size: 44)); Text(m.name).font(.title3.weight(.heavy)).multilineTextAlignment(.center)
                                    Text(String(repeating: "⭐️", count: kids.saved.stars[m.id] ?? 0)).font(.title3) }
                                .frame(maxWidth: .infinity, minHeight: 130).padding().background(bright[i % bright.count].opacity(0.85), in: RoundedRectangle(cornerRadius: 28))
                            }.buttonStyle(.plain).foregroundStyle(.white).accessibilityLabel("\(m.name)")
                        }
                    }.padding()
                }
            }
        }
        .fullScreenCover(item: $dance) { m in KidDanceView(movement: m) { dance = nil } }
        .sheet(isPresented: $grownUps) { GrownUpsView() }
    }
}

struct KidDanceView: View {
    @EnvironmentObject var kids: KidsModel
    let movement: MovementDefinition; var close: () -> Void
    @State private var clock = PracticeClock(bpm: 80)
    @State private var phase = 0   // 0 watch, 1 copy, 2 done
    @State private var cameraOn = false
    @State private var cam = CameraPoseService()
    @State private var latest: TrackingObservation?
    @State private var score = ScoreAccumulator()
    @State private var you: Pose?
    @State private var timer: Timer?
    @State private var started = 0.0
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.3, green: 0.12, blue: 0.55), Color(red: 0.1, green: 0.05, blue: 0.25)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack {
                if phase == 2 {
                    Spacer(); Text("🎉").font(.system(size: 100)); Text(KidsPolicy.feedback(score: score, cameraEnabled: cameraOn)).font(.system(size: 36, weight: .black, design: .rounded)).multilineTextAlignment(.center).padding()
                    Spacer(); Button("Done") { finish() }.font(.title.bold()).padding(.horizontal, 40).frame(minHeight: 72).background(Capsule().fill(.pink)).foregroundStyle(.white).padding()
                } else {
                    Text(phase == 0 ? "WATCH" : "NOW YOU!").font(.system(size: 40, weight: .black, design: .rounded)).padding(.top)
                    TimelineView(.animation(paused: !clock.isPlaying)) { _ in
                        CharacterStageView(characterID: "zuri", pose: movement.pose(atBeat: clock.beat(at: ProcessInfo.processInfo.systemUptime)),
                                           youCharacterID: cameraOn ? "yourdancer" : nil, youPose: you, youOpacity: 0.4)
                    }
                    Text(movement.instruction).font(.title3).multilineTextAlignment(.center).padding(.horizontal)
                    HStack(spacing: 20) {
                        Button { toggle() } label: { Image(systemName: clock.isPlaying ? "pause.fill" : "play.fill").font(.largeTitle).frame(width: 84, height: 84).background(Circle().fill(.pink)) }.accessibilityLabel(clock.isPlaying ? "Pause" : "Play")
                        Button { nextPhase() } label: { Text(phase == 0 ? "I'M READY" : "ALL DONE").font(.title2.weight(.heavy)).padding(.horizontal, 24).frame(minHeight: 84).background(Capsule().fill(.cyan.opacity(0.8))) }
                        Button { finish() } label: { Image(systemName: "xmark").font(.title).frame(width: 64, height: 64).background(Circle().fill(.white.opacity(0.2))) }.accessibilityLabel("Stop")
                    }.foregroundStyle(.white).padding(.bottom)
                }
            }.foregroundStyle(.white)
        }
        .onAppear { cameraOn = kids.saved.settings.cameraMatchingEnabled; clock.setBPM(min(80, kids.saved.settings.practiceBPMCap), at: ProcessInfo.processInfo.systemUptime) }
        .onDisappear { teardown() }
    }
    func toggle() { let n = ProcessInfo.processInfo.systemUptime; if clock.isPlaying { clock.pause(at: n); kids.beats.pause() } else { if phase == 0 && started == 0 { try? kids.beats.start(BeatPattern.all[0], bpm: clock.bpm) } else { kids.beats.resume() }; started = n; clock.play(at: n) } }
    func nextPhase() {
        if phase == 0 {
            phase = 1
            if cameraOn { Task { guard await CameraPoseService.requestAccess() else { cameraOn = false; return }
                cam.onObservation = { o in Task { @MainActor in latest = o; if let o, let n = PoseNormalizer.normalize(o.raw) { you = PoseCompleter.smooth(PoseCompleter.complete(n, fallback: you), previous: you) } } }
                try? cam.start(); startMatching() } }
        } else { phase = 2; teardown(); if cameraOn, let a = score.accuracy, score.coverage >= 0.3, a >= 0.7 { kids.saved.stars[movement.id] = max(kids.saved.stars[movement.id] ?? 0, a >= 0.9 ? 3 : 2) } else if !cameraOn { kids.saved.stars[movement.id] = max(kids.saved.stars[movement.id] ?? 0, 1) } }
    }
    func startMatching() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in Task { @MainActor in
            guard clock.isPlaying else { return }
            let n = ProcessInfo.processInfo.systemUptime
            score.record(Matcher.compare(expected: movement.pose(atBeat: clock.beat(at: n)), observed: latest, now: n)) } }
    }
    func teardown() { timer?.invalidate(); cam.stop(); kids.beats.stop(); kids.speech.stop() }
    func finish() { teardown(); close() }
}

/// Adult gate -> safe necessary settings only.
struct GrownUpsView: View {
    @EnvironmentObject var kids: KidsModel; @Environment(\.dismiss) var dismiss
    @State private var answer = ""; @State private var unlocked = false
    private let gate = KidsPolicy.adultGate(seed: Int(Date().timeIntervalSince1970) % 1000)
    var body: some View {
        NavigationStack {
            if !unlocked {
                VStack(spacing: 16) { Text("For grown-ups").font(.title.bold()); Text("What is \(gate.question)?"); TextField("Answer", text: $answer).keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(width: 160)
                    Button("Unlock") { unlocked = Int(answer) == gate.answer }.buttonStyle(.borderedProminent) }.padding()
            } else {
                Form {
                    Section("Camera") { Toggle("Let the camera see movement (on this device only)", isOn: $kids.saved.settings.cameraMatchingEnabled)
                        Text("Off by default. Pictures are never saved or sent. With the camera off, dancing along still works but isn't scored.").font(.footnote) }
                    Section("Sound") { Picker("Voice", selection: $kids.saved.settings.voice) { Text("Off").tag(VoiceLevel.off); Text("Minimal").tag(VoiceLevel.minimal); Text("Normal").tag(VoiceLevel.normal) } }
                    Section("Practice speed") { Slider(value: $kids.saved.settings.practiceBPMCap, in: 50...120, step: 5); Text("Top speed \(Int(kids.saved.settings.practiceBPMCap)) BPM") }
                    Section("Privacy") { Text("No accounts. No ads. No tracking. No internet needed. Progress stays on this device.") }
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
