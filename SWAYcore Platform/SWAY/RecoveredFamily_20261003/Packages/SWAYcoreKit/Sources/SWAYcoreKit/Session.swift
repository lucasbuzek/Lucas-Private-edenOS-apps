import Foundation

public enum SessionPhase: Equatable, Sendable {
    case idle, requestingPermission, acquiring, calibrating, ready, countdown, running, paused, ended
}
public enum SessionMode: Equatable, Sendable { case tracking, followAlong }

/// Session lifecycle. Before READY nothing advances: no timeline, scoring, timer, speech, or move progression.
public struct SessionController: Sendable {
    public private(set) var phase: SessionPhase = .idle
    public let mode: SessionMode
    public let countdownSeconds: TimeInterval
    private var countdownStart: TimeInterval = 0
    private var runStart: TimeInterval = 0
    private var pausedAccum: TimeInterval = 0
    private var pauseStart: TimeInterval?
    public private(set) var runningElapsedAtEnd: TimeInterval?
    public private(set) var score = ScoreAccumulator()

    public init(mode: SessionMode, countdownSeconds: TimeInterval = 3) { self.mode = mode; self.countdownSeconds = countdownSeconds }

    public var scoringEnabled: Bool { mode == .tracking }

    public mutating func begin() {
        guard phase == .idle else { return }
        phase = mode == .tracking ? .requestingPermission : .ready   // follow-along: Setup -> Countdown -> Workout
    }
    public mutating func permissionResolved(granted: Bool, now: TimeInterval) {
        guard phase == .requestingPermission else { return }
        phase = granted ? .acquiring : .idle   // denied: caller may offer follow-along as a separate session
    }
    public mutating func bodyAcquired() { if phase == .acquiring { phase = .calibrating } }
    public mutating func calibrationFinished(_ s: CalibrationState) { if phase == .calibrating && s.isReady { phase = .ready } }
    public mutating func startCountdown(now: TimeInterval) {
        guard phase == .ready else { return }
        phase = .countdown; countdownStart = now
    }
    public func countdownRemaining(now: TimeInterval) -> TimeInterval? {
        guard phase == .countdown else { return nil }
        return max(0, countdownSeconds - (now - countdownStart))
    }
    /// Call each frame/tick. Moves countdown -> running when the countdown elapses.
    public mutating func tick(now: TimeInterval) {
        if phase == .countdown, now - countdownStart >= countdownSeconds {
            phase = .running; runStart = now; pausedAccum = 0
        }
    }
    /// Seconds of workout time; frozen while paused, zero before running.
    public func workoutTime(now: TimeInterval) -> TimeInterval {
        switch phase {
        case .running: return now - runStart - pausedAccum
        case .paused: return (pauseStart ?? now) - runStart - pausedAccum
        case .ended: return runningElapsedAtEnd ?? 0
        default: return 0
        }
    }
    public mutating func pause(now: TimeInterval) { guard phase == .running else { return }; phase = .paused; pauseStart = now }
    public mutating func resume(now: TimeInterval) {
        guard phase == .paused, let p = pauseStart else { return }
        pausedAccum += now - p; pauseStart = nil; phase = .running
    }
    public mutating func end(now: TimeInterval) {
        guard phase != .idle, phase != .ended else { return }
        runningElapsedAtEnd = (phase == .running || phase == .paused) ? workoutTime(now: now) : 0
        phase = .ended
    }
    /// Records a result only while running in tracking mode; other times cannot earn or lose credit.
    public mutating func record(_ r: MatchResult) {
        guard phase == .running, scoringEnabled else { return }
        score.record(r)
    }
}
