import Foundation

/// Canonical calibration: STEP INTO VIEW → WAVE LEFT → WAVE RIGHT → LIFT LEFT FOOT → LIFT RIGHT FOOT → JUMP → READY TO SWAY.
/// Case names are preserved from the recovered Build 147/149 implementation so app code keeps compiling.
public enum SwayCalibrationStage: Int, CaseIterable, Sendable {
    case frame, waveLeft, waveRight, liftLeft, liftRight, jump, ready
    public var title: String {
        switch self {
        case .frame: return "STEP INTO VIEW"
        case .waveLeft: return "WAVE LEFT"
        case .waveRight: return "WAVE RIGHT"
        case .liftLeft: return "LIFT LEFT FOOT"
        case .liftRight: return "LIFT RIGHT FOOT"
        case .jump: return "JUMP"
        case .ready: return "READY TO SWAY"
        }
    }
}

public struct SwayPoint: Equatable, Sendable {
    public var x: Double, y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// One camera frame summarised in DISPLAY coordinates (origin top-left, y grows downward), as produced by CameraPoseService.
/// Only joints that already passed the detector confidence floor are present; absent means "not observed".
public struct SwayCalibrationFrame: Sendable {
    public var timestamp: TimeInterval
    public var bodyPresent: Bool          // any joints at all
    public var scoringReady: Bool         // full body usable (CameraPoseService.scoringReady)
    public var root: SwayPoint?
    public var leftWrist: SwayPoint?, rightWrist: SwayPoint?
    public var leftAnkle: SwayPoint?, rightAnkle: SwayPoint?
    public init(timestamp: TimeInterval, bodyPresent: Bool, scoringReady: Bool, root: SwayPoint? = nil,
                leftWrist: SwayPoint? = nil, rightWrist: SwayPoint? = nil, leftAnkle: SwayPoint? = nil, rightAnkle: SwayPoint? = nil) {
        self.timestamp = timestamp; self.bodyPresent = bodyPresent; self.scoringReady = scoringReady; self.root = root
        self.leftWrist = leftWrist; self.rightWrist = rightWrist; self.leftAnkle = leftAnkle; self.rightAnkle = rightAnkle
    }
}

public enum SwayCalibrationEvent: Equatable, Sendable {
    case stageCompleted(SwayCalibrationStage)
    case ready
    case trackingLost
    case trackingRecovered
    case timedOut(SwayCalibrationStage)
    case cancelled
}

/// Thresholds marked LEGACY are the recovered Build 147/149 values (kept unchanged).
/// Thresholds marked NEW are additive robustness values that need physical confirmation (see Docs/UNRESOLVED_ITEMS.md).
public struct SwayCalibrationConfig: Sendable {
    public var framedStableFrames = 6          // LEGACY
    public var waveMotionTotal = 0.32          // LEGACY
    public var footLift = 0.055                // LEGACY (display-y difference between ankles)
    public var footStableFrames = 4            // LEGACY
    public var jumpRise = 0.045                // LEGACY (display-y rise of root above baseline)
    public var jumpStableFrames = 2            // LEGACY
    public var waveJitterDeadband = 0.004      // NEW: per-frame wrist deltas below this are sensor jitter, not waving
    public var waveDecayPerFrame = 0.995       // NEW: leaky integration so drift/jitter can never sum to a "wave"
    public var stageTimeout: TimeInterval = 60 // NEW: surfaces timedOut so UI can offer skip/low-impact/cancel
    public var baselineMinSamples = 5          // NEW: jump baseline starts as the median of the first N ready frames
    public var baselineMaxStepPerFrame = 0.0007 // NEW: baseline follows only SLOW drift (~0.02/s); a jump is far faster
    public init() {}
}

public struct SwayCalibrationMachine: Sendable {
    public private(set) var stage: SwayCalibrationStage = .frame
    public private(set) var completed: [SwayCalibrationStage] = []
    public private(set) var status: String = "STEP INTO VIEW"
    public private(set) var trackingLost = false
    public private(set) var timedOut = false
    public private(set) var cancelled = false
    public private(set) var lowImpact = false
    public let config: SwayCalibrationConfig

    private var stable = 0
    private var motion = 0.0
    private var previousWrist: SwayPoint?
    private var rootHistory: [Double] = []
    private var baselineRoot: Double?
    private var stageStartedAt: TimeInterval?

    public init(config: SwayCalibrationConfig = SwayCalibrationConfig()) { self.config = config }

    public var isReady: Bool { stage == .ready }
    public var isActive: Bool { !isReady && !cancelled }

    public mutating func cancel() -> [SwayCalibrationEvent] {
        guard isActive else { return [] }
        cancelled = true; status = "TRACKING OFF"; return [.cancelled]
    }
    /// Orientation/camera geometry changed: positional baselines are invalid; in-progress evidence is discarded.
    public mutating func geometryChanged() { resetEvidence(); rootHistory.removeAll(); baselineRoot = nil }
    /// After a timeout the user may keep trying.
    public mutating func continueAfterTimeout() { timedOut = false; stageStartedAt = nil }
    /// Low-impact path: skipping the jump is only allowed at the jump step.
    public mutating func skipJump() -> [SwayCalibrationEvent] {
        guard stage == .jump, isActive else { return [] }
        lowImpact = true; return complete("Low-impact calibration ✓")
    }
    public mutating func restart() { self = SwayCalibrationMachine(config: config) }

    @discardableResult
    public mutating func ingest(_ f: SwayCalibrationFrame) -> [SwayCalibrationEvent] {
        guard isActive else { return [] }
        var events: [SwayCalibrationEvent] = []
        if stageStartedAt == nil { stageStartedAt = f.timestamp }
        if !timedOut, let s = stageStartedAt, f.timestamp - s > config.stageTimeout { timedOut = true; events.append(.timedOut(stage)) }

        guard f.bodyPresent else {
            if !trackingLost { trackingLost = true; events.append(.trackingLost) }
            resetEvidence(); status = "STEP INTO VIEW"; return events
        }
        if trackingLost { trackingLost = false; events.append(.trackingRecovered) }

        // The jump baseline follows slow drift only, so stepping away from the camera is not mistaken for a jump.
        if let r = f.root, f.scoringReady { trackRoot(r.y) }

        switch stage {
        case .frame:
            if f.scoringReady { stable += 1; status = "HOLD THERE" }
            else { stable = max(0, stable - 1); status = f.bodyPresent ? "STEP BACK — SHOW YOUR FEET" : "STEP INTO VIEW" }
            if stable >= config.framedStableFrames { events += complete("Body ready ✓") }
        case .waveLeft: events += wave(f.leftWrist, label: "LEFT HAND", done: "Left hand ✓")
        case .waveRight: events += wave(f.rightWrist, label: "RIGHT HAND", done: "Right hand ✓")
        case .liftLeft: events += lift(moving: f.leftAnkle, other: f.rightAnkle, label: "LEFT FOOT", done: "Left foot ✓")
        case .liftRight: events += lift(moving: f.rightAnkle, other: f.leftAnkle, label: "RIGHT FOOT", done: "Right foot ✓")
        case .jump:
            guard let r = f.root, let base = baselineRoot else { status = "STEP INTO VIEW"; return events }
            if base - r.y > config.jumpRise { stable += 1; status = "JUMP DETECTED" } else { stable = max(0, stable - 1); status = "JUMP WHEN READY" }
            if stable >= config.jumpStableFrames { events += complete("Jump ✓") }
        case .ready: break
        }
        return events
    }

    // MARK: private
    private mutating func resetEvidence() { stable = 0; motion = 0; previousWrist = nil }

    private mutating func wave(_ wrist: SwayPoint?, label: String, done: String) -> [SwayCalibrationEvent] {
        guard let w = wrist else { status = "SHOW YOUR \(label)"; previousWrist = nil; return [] }
        motion *= config.waveDecayPerFrame
        if let old = previousWrist {
            let dx = abs(w.x - old.x), dy = abs(w.y - old.y)
            let delta = dx + dy
            if delta >= config.waveJitterDeadband { motion += delta }
        }
        previousWrist = w; status = "WAVE SIDE TO SIDE"
        return motion > config.waveMotionTotal ? complete(done) : []
    }

    private mutating func lift(moving: SwayPoint?, other: SwayPoint?, label: String, done: String) -> [SwayCalibrationEvent] {
        guard let a = moving, let b = other else { status = "SHOW BOTH FEET"; stable = 0; return [] }
        if b.y - a.y > config.footLift { stable += 1; status = "HOLD IT" } else { stable = max(0, stable - 1); status = "LIFT YOUR \(label)" }
        return stable >= config.footStableFrames ? complete(done) : []
    }

    private mutating func trackRoot(_ y: Double) {
        if let b = baselineRoot {
            baselineRoot = b + max(-config.baselineMaxStepPerFrame, min(config.baselineMaxStepPerFrame, y - b)); return
        }
        rootHistory.append(y)
        if rootHistory.count >= config.baselineMinSamples { let sorted = rootHistory.sorted(); baselineRoot = sorted[sorted.count / 2] }
    }

    private mutating func complete(_ message: String) -> [SwayCalibrationEvent] {
        let finished = stage
        completed.append(finished)
        resetEvidence(); timedOut = false; stageStartedAt = nil
        var ev: [SwayCalibrationEvent] = [.stageCompleted(finished)]
        if let next = SwayCalibrationStage(rawValue: finished.rawValue + 1) {
            stage = next
            if next == .ready { status = "READY TO SWAY"; ev.append(.ready) } else { status = "FOLLOW COACH" }
        }
        _ = message
        return ev
    }
}
