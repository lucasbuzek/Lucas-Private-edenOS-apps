import Foundation

/// Deterministic transport-to-musical-time clock used by workout consumers.
/// Host time is injected so pausing never accumulates wall-clock time.
public struct SwayMusicalClock: Equatable, Sendable {
    public private(set) var musicalTime: TimeInterval
    public private(set) var isPaused: Bool
    private var hostAnchor: TimeInterval

    public init(musicalTime: TimeInterval = 0, hostTime: TimeInterval = 0, paused: Bool = false) {
        self.musicalTime = max(0, musicalTime)
        self.hostAnchor = hostTime
        self.isPaused = paused
    }

    @discardableResult
    public mutating func sample(hostTime: TimeInterval) -> TimeInterval {
        guard !isPaused else { return musicalTime }
        musicalTime += max(0, hostTime - hostAnchor)
        hostAnchor = max(hostAnchor, hostTime)
        return musicalTime
    }

    public mutating func pause(hostTime: TimeInterval) {
        guard !isPaused else { return }
        sample(hostTime: hostTime)
        isPaused = true
    }

    public mutating func resume(hostTime: TimeInterval) {
        guard isPaused else { return }
        hostAnchor = hostTime
        isPaused = false
    }

    public mutating func seek(to time: TimeInterval, hostTime: TimeInterval) {
        musicalTime = max(0, time)
        hostAnchor = hostTime
    }
}
