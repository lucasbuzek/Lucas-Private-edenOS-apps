import Foundation

public struct SwayMusicalPosition: Equatable, Sendable {
    public var beat: Int, count: Int, bar: Int, phrase: Int
    public var beatPhase: Double
    public init(beat: Int, count: Int, bar: Int, phrase: Int, beatPhase: Double) {
        self.beat = beat; self.count = count; self.bar = bar; self.phrase = phrase; self.beatPhase = beatPhase
    }
}

/// Pure musical-time → beat/count/bar/phrase mapping used by SwayTimelineEngine (behaviour recovered from Build 149/153).
/// Count cycles 1...8, bar = 4 beats, phrase = 32 beats. Floor is 20 BPM per the Learn contract (20–180).
public enum SwayTimelineMath {
    public static let minimumBPM = 20.0
    public static func position(time: TimeInterval, bpm: Double, gridBeats: [TimeInterval]? = nil, gridBPM: Double? = nil) -> SwayMusicalPosition {
        if let beats = gridBeats, !beats.isEmpty {
            let i = max(0, min(beats.count - 1, firstIndex(in: beats, greaterThan: time) - 1))
            let start = beats[i]
            let end = i + 1 < beats.count ? beats[i + 1] : start + 60.0 / max(minimumBPM, gridBPM ?? bpm)
            let phase = min(max((time - start) / max(0.001, end - start), 0), 0.999999)
            return SwayMusicalPosition(beat: i, count: i % 8 + 1, bar: i / 4, phrase: i / 32, beatPhase: phase)
        }
        let spb = 60.0 / max(minimumBPM, bpm)
        let position = max(0, time / spb)
        let b = Int(floor(position))
        return SwayMusicalPosition(beat: b, count: b % 8 + 1, bar: b / 4, phrase: b / 32, beatPhase: position - floor(position))
    }
    /// Seconds per beat honouring the shared floor.
    public static func secondsPerBeat(bpm: Double) -> Double { 60.0 / max(minimumBPM, bpm) }

    static func firstIndex(in a: [TimeInterval], greaterThan t: TimeInterval) -> Int {
        var lo = 0, hi = a.count
        while lo < hi { let mid = (lo + hi) / 2; if a[mid] > t { hi = mid } else { lo = mid + 1 } }
        return lo
    }
}
