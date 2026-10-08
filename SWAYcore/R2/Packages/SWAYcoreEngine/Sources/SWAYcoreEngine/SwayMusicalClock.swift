import Foundation

/// Monotonic, pause-safe source of the one canonical musical time.
/// Callers supply system uptime; wall-clock time is never accumulated by a timer.
public struct SwayMusicalClock: Sendable {
    public private(set) var musicalTime: TimeInterval = 0
    public private(set) var isRunning = false
    private var anchorUptime: TimeInterval?

    public init() {}

    public mutating func start(at uptime: TimeInterval) {
        musicalTime = 0
        anchorUptime = uptime
        isRunning = true
    }

    public mutating func pause(at uptime: TimeInterval) {
        guard isRunning else { return }
        update(at: uptime)
        isRunning = false
        anchorUptime = nil
    }

    public mutating func resume(at uptime: TimeInterval) {
        guard !isRunning else { return }
        anchorUptime = uptime
        isRunning = true
    }

    public mutating func restart(at uptime: TimeInterval) { start(at: uptime) }

    @discardableResult public mutating func update(at uptime: TimeInterval) -> TimeInterval {
        guard isRunning, let anchor = anchorUptime else { return musicalTime }
        musicalTime += max(0, uptime - anchor)
        anchorUptime = uptime
        return musicalTime
    }

    public func position(bpm: Double) -> SwayMusicalPosition {
        SwayTimelineMath.position(time: musicalTime, bpm: bpm)
    }
}

public struct SwayTimelinePlan: Equatable, Sendable {
    public var bpm: Double
    public var totalCounts: Int
    public init(bpm: Double, totalCounts: Int) {
        self.bpm = max(SwayTimelineMath.minimumBPM, bpm)
        self.totalCounts = max(0, totalCounts)
    }
    public var duration: TimeInterval { Double(totalCounts) * SwayTimelineMath.secondsPerBeat(bpm: bpm) }
    public func isComplete(at musicalTime: TimeInterval) -> Bool { musicalTime >= duration }
}
