import SwiftUI
import AVFoundation
import SWAYcoreKit
import SWAYAppKit

struct WorkoutPlan: Identifiable {
    let id = UUID()
    var title: String
    var steps: [ContentStep]
    var movementIDs: [String]
    var pattern: BeatPattern
    var bpm: Double
    var experience: String
    @MainActor static func quick(model: AppModel) -> WorkoutPlan {
        let pool = model.visibleLibrary.filter { $0.complexity.rawValue <= Complexity.easy.rawValue }
        let picks = Array(pool.prefix(4))
        return WorkoutPlan(title: "Quick Dance", steps: picks.map { ContentStep(movementID: $0.id, repetitions: 2) }, movementIDs: picks.map(\.id),
                           pattern: BeatPattern.all[1], bpm: BeatPattern.all[1].bpm, experience: "Quick Dance")
    }
    static func practice(_ m: MovementDefinition, model: AppModel) -> WorkoutPlan {
        WorkoutPlan(title: m.name, steps: [ContentStep(movementID: m.id, repetitions: 4)], movementIDs: [m.id],
                    pattern: BeatPattern.all[0], bpm: BeatPattern.all[0].bpm, experience: "Practice")
    }
}

/// Orchestrates: Tracking(permission -> acquisition -> calibration -> READY -> countdown -> workout) or Follow-Along(setup -> countdown -> workout).
@MainActor final class WorkoutRunner: ObservableObject {
    let plan: WorkoutPlan; let model: AppModel
    let trackingRequested: Bool
    @Published private(set) var phase: SessionPhase = .idle
    @Published private(set) var calibration = CalibrationState()
    @Published private(set) var coachPose: Pose?
    @Published private(set) var youPose: Pose?
    @Published private(set) var youOpacity = 0.0
    @Published private(set) var countdown: Int?
    @Published private(set) var count = 1
    @Published private(set) var currentName = ""
    @Published private(set) var nextName: String?
    @Published private(set) var progress = 0.0
    @Published private(set) var cueText: String?
    @Published private(set) var permissionDenied = false
    @Published private(set) var matchState: MatchResult?
    @Published private(set) var finished: Summary?

    struct Summary { var score: ScoreAccumulator; var movementIDs: [String]; var duration: TimeInterval; var cameraUsed: Bool }

    private var session: SessionController
    private var engine = CalibrationEngine()
    private var presence = TrackingPresence()
    private var latest: TrackingObservation?
    private let camera = CameraPoseService()
    private var timeline: ChoreographyTimeline
    private var timer: Timer?
    private var readyAt: TimeInterval?
    private var lastPhase: SessionPhase = .idle
    private var lastCountdown = -1
    private var windowScore = ScoreAccumulator(); private var lastCycle = -1
    private var lastRepositionCue = -100.0; private var lastNextCue = -1
    private var startedAt = Date()
    private var firstGoodObservation = false

    init(plan: WorkoutPlan, model: AppModel, tracking: Bool) {
        self.plan = plan; self.model = model; self.trackingRequested = tracking
        session = SessionController(mode: tracking ? .tracking : .followAlong, countdownSeconds: 3)
        timeline = ChoreographyTimeline(steps: plan.steps, movements: model.lookup)
        model.speech.level = model.state.settings.voice
    }

    func begin() {
        startedAt = Date(); session.begin(); phase = session.phase
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in Task { @MainActor in self?.tick() } }
        if trackingRequested {
            Task {
                let granted = await CameraPoseService.requestAccess()
                session.permissionResolved(granted: granted, now: now)
                if granted {
                    camera.onObservation = { [weak self] o in Task { @MainActor in self?.receive(o) } }
                    do { try camera.start() } catch { permissionDenied = true; session.end(now: now) }
                } else { permissionDenied = true }
                phase = session.phase
            }
        } else { session.startCountdown(now: now); phase = session.phase }
    }

    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    private func receive(_ o: TrackingObservation?) {
        latest = o; presence.observe(o)
        if let o, let n = PoseNormalizer.normalize(o.raw) {
            youPose = PoseCompleter.smooth(PoseCompleter.complete(n, fallback: youPose), previous: youPose, alpha: 0.6)
            if session.phase == .acquiring, o.raw.values.filter({ $0.confidence >= PoseNormalizer.minConfidence }).count >= 8 { session.bodyAcquired() }
        }
        if session.phase == .calibrating || session.phase == .acquiring {
            if session.phase == .calibrating { calibration = engine.ingest(o); session.calibrationFinished(calibration); if calibration.isReady, readyAt == nil { readyAt = now } }
        }
        phase = session.phase
    }

    func pause() { session.pause(now: now); model.beats.pause(); phase = session.phase }
    func resume() { session.resume(now: now); model.beats.resume(); phase = session.phase }
    func end() { finish(early: true) }

    private func tick() {
        let t = now
        if session.phase == .ready, let r = readyAt, t - r > 1.2 { session.startCountdown(now: t) }   // READY TO SWAY shown briefly
        session.tick(now: t)
        if session.phase == .running, lastPhase != .running { try? model.beats.start(plan.pattern, bpm: plan.bpm) }
        lastPhase = session.phase; phase = session.phase

        // YOU visibility: tracked -> fade after loss; reacquisition restores.
        if trackingRequested { youOpacity = 0.55 * presence.youConfidence(at: t) }

        switch session.phase {
        case .countdown:
            let n = Int(ceil(session.countdownRemaining(now: t) ?? 0)); countdown = n
            if n != lastCountdown, n > 0 { lastCountdown = n; model.speech.speak(CueFactory.countdown(n, now: t, level: model.state.settings.voice)) }
        case .running:
            countdown = nil
            let beat = session.workoutTime(now: t) * plan.bpm / 60.0
            guard let (seg, local) = timeline.segment(atBeat: beat), let m = model.lookup[seg.movementID] else { finish(early: false); return }
            let pose = m.pose(atBeat: local, mirrored: seg.mirrored); coachPose = pose
            currentName = m.name; count = Counting.position(atBeat: local, cycle: m.beatsPerCycle).count
            progress = beat / Double(max(timeline.totalBeats, 1))
            if let n = timeline.next(afterBeat: beat), let nm = model.lookup[n.movementID] {
                nextName = nm.name
                if Double(n.startBeat) - beat < 2, lastNextCue != n.startBeat { lastNextCue = n.startBeat; let c = CueFactory.nextMove(nm.name, now: t, level: model.state.settings.voice); cueText = c.visual; model.speech.speak(c) }
            } else { nextName = nil }
            // Truthful tracking: only fresh, confident, sufficient observations can match.
            if trackingRequested {
                let r = Matcher.compare(expected: pose, observed: latest, now: t); matchState = r; session.record(r); windowScore.record(r)
                if presence.isLost(at: t), t - lastRepositionCue > 4 { lastRepositionCue = t; let c = CueFactory.reposition(now: t, level: model.state.settings.voice); cueText = c.visual; model.speech.speak(c) }
                let cyc = Int(beat) / 8
                if cyc != lastCycle { if lastCycle >= 0, let p = CueFactory.praise(accuracy: windowScore.accuracy, coverage: windowScore.coverage, now: t, level: model.state.settings.voice, coach: model.state.settings.coach) { cueText = p.visual; model.speech.speak(p) }; windowScore = ScoreAccumulator(); lastCycle = cyc }
            }
        default: break
        }
    }

    private func finish(early: Bool) {
        guard session.phase != .ended else { return }
        let t = now; let dur = session.workoutTime(now: t)
        session.end(now: t); timer?.invalidate(); camera.stop(); model.beats.stop(); model.speech.stop(); phase = .ended
        let s = Summary(score: session.score, movementIDs: plan.movementIDs, duration: dur, cameraUsed: trackingRequested)
        if !early || dur > 10 { model.complete(movementIDs: plan.movementIDs, score: session.score)
            Task { await model.health.saveDance(start: startedAt, end: Date(), kilocalories: nil) } }
        finished = s
    }
    deinit { }
    func teardown() { timer?.invalidate(); camera.stop(); model.beats.stop(); model.speech.stop() }
}
