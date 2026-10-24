import Foundation

/// Beat grid: beat(t) = (t - phase) * bpm/60. Half-time keeps phase and halves the effective rate.
public struct MusicGrid: Codable, Equatable, Sendable {
    public var bpm: Double
    public var phase: TimeInterval        // time of beat 0 (first downbeat)
    public var beatsPerBar: Int
    public var downbeatOffset: Int        // beats from beat 0 to the first bar line
    public var halfTime: Bool
    public init(bpm: Double, phase: TimeInterval = 0, beatsPerBar: Int = 4, downbeatOffset: Int = 0, halfTime: Bool = false) {
        self.bpm = bpm; self.phase = phase; self.beatsPerBar = beatsPerBar; self.downbeatOffset = downbeatOffset; self.halfTime = halfTime
    }
    public var effectiveBPM: Double { halfTime ? bpm / 2 : bpm }
    public func beat(at time: TimeInterval) -> Double { (time - phase) * effectiveBPM / 60.0 }
    public func time(ofBeat beat: Double) -> TimeInterval { phase + beat * 60.0 / effectiveBPM }
    public func bar(atBeat beat: Double) -> Int { Int(floor((beat - Double(downbeatOffset)) / Double(beatsPerBar))) }
    /// Phrase = 8 beats-per-bar-pairs (two bars of 4 == one 8-count) by default.
    public func phrase(atBeat beat: Double, barsPerPhrase: Int = 2) -> Int { Int(floor(Double(bar(atBeat: beat)) / Double(barsPerPhrase))) }
}

public struct CountPosition: Equatable, Sendable {
    public var count: Int        // 1...cycle
    public var fraction: Double  // 0..<1 within the count
    public var cycleIndex: Int
}

public enum Counting {
    public static func position(atBeat beat: Double, cycle: Int = 8) -> CountPosition {
        let b = max(0, beat)
        let whole = Int(floor(b))
        return CountPosition(count: whole % cycle + 1, fraction: b - Double(whole), cycleIndex: whole / cycle)
    }
}

/// Estimates tempo and phase from onset times (deterministic; no randomness).
public enum BeatAnalyzer {
    public struct Result: Equatable, Sendable { public var grid: MusicGrid; public var confidence: Double }

    public static func estimate(onsets: [TimeInterval], minBPM: Double = 70, maxBPM: Double = 180, strengths: [Double]? = nil) -> Result? {
        let o = onsets.sorted()
        guard o.count >= 8 else { return nil }
        // Score candidate BPMs (0.5 BPM steps) by how tightly onsets cluster on the grid.
        var best: (bpm: Double, phase: Double, score: Double) = (0, 0, -1)
        var bpm = minBPM
        while bpm <= maxBPM {
            let period = 60.0 / bpm
            // circular mean of onset phases
            var sx = 0.0, sy = 0.0
            for t in o { let a = 2 * Double.pi * (t.truncatingRemainder(dividingBy: period)) / period; sx += cos(a); sy += sin(a) }
            let r = (sx * sx + sy * sy).squareRoot() / Double(o.count)
            if r > best.score {
                var meanAngle = atan2(sy, sx); if meanAngle < 0 { meanAngle += 2 * .pi }
                best = (bpm, meanAngle / (2 * .pi) * period, r)
            }
            bpm += 0.5
        }
        guard best.score > 0.6 else { return nil }
        // Prefer the octave inside 90...150 when scores are equivalent (half/double ambiguity).
        var chosen = best
        for factor in [0.5, 2.0] {
            let cand = best.bpm * factor
            if cand >= minBPM && cand <= maxBPM && abs(cand - 120) < abs(chosen.bpm - 120) - 15 {
                chosen = (cand, best.phase, best.score * 0.98)
            }
        }
        // Downbeat: pick the beat-in-bar with the strongest accumulated onset strength.
        let period = 60.0 / chosen.bpm
        var strengthByBeat = [Double](repeating: 0, count: 4)
        for (i, t) in o.enumerated() {
            let idx = Int((((t - chosen.phase) / period).rounded())) 
            strengthByBeat[((idx % 4) + 4) % 4] += strengths?[safe: i] ?? 1
        }
        let down = strengthByBeat.enumerated().max { $0.element < $1.element }?.offset ?? 0
        return Result(grid: MusicGrid(bpm: chosen.bpm, phase: chosen.phase, beatsPerBar: 4, downbeatOffset: down), confidence: best.score)
    }
}

extension Array { subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil } }

/// Practice clock: user-controlled tempo, no auto-speed-up. Pause freezes count and character.
public struct PracticeClock: Equatable, Sendable {
    public private(set) var bpm: Double
    public private(set) var isPlaying = false
    private var anchorTime: TimeInterval = 0
    private var anchorBeat: Double = 0
    public init(bpm: Double = 90) { self.bpm = bpm }

    public func beat(at now: TimeInterval) -> Double { isPlaying ? anchorBeat + (now - anchorTime) * bpm / 60.0 : anchorBeat }
    public mutating func play(at now: TimeInterval) { guard !isPlaying else { return }; anchorTime = now; isPlaying = true }
    public mutating func pause(at now: TimeInterval) { guard isPlaying else { return }; anchorBeat = beat(at: now); isPlaying = false }
    public mutating func setBPM(_ new: Double, at now: TimeInterval) {
        let b = beat(at: now); anchorBeat = b; anchorTime = now; bpm = min(max(new, 30), 200)
    }
    /// Learn: choose count N (1-based) -> frozen at exactly that count.
    public mutating func select(count: Int, cycle: Int = 8, at now: TimeInterval) {
        isPlaying = false; anchorBeat = Double(min(max(count, 1), cycle) - 1); anchorTime = now
    }
}

/// Tap tempo for music whose audio cannot be analysed (e.g. protected Apple Music streams).
public struct TapTempo: Sendable {
    public private(set) var taps: [TimeInterval] = []
    public init() {}
    public mutating func tap(at t: TimeInterval) {
        if let last = taps.last, t - last > 2.5 { taps.removeAll() }   // pause longer than 2.5s starts over
        taps.append(t); if taps.count > 12 { taps.removeFirst() }
    }
    public var bpm: Double? {
        guard taps.count >= 4 else { return nil }
        let intervals = zip(taps.dropFirst(), taps).map { $0 - $1 }
        let sorted = intervals.sorted(); let median = sorted[sorted.count / 2]
        guard median > 0 else { return nil }
        let v = 60.0 / median
        return (30...300).contains(v) ? v : nil
    }
    public var grid: MusicGrid? { bpm.map { MusicGrid(bpm: $0, phase: taps.last ?? 0) } }
}

/// Generated "SWAY Beats": 16-step patterns per recovered style name (ND-010: pattern content is new, replaceable).
public struct BeatPattern: Equatable, Sendable {
    public var name: String, bpm: Double, kick: [Int], snare: [Int], hat: [Int], perc: [Int]
    public static let all: [BeatPattern] = [
        BeatPattern(name: "Simple",    bpm: 100, kick: [0, 8],            snare: [4, 12],       hat: [0, 4, 8, 12],       perc: []),
        BeatPattern(name: "Pop",       bpm: 116, kick: [0, 6, 8, 14],     snare: [4, 12],       hat: Array(stride(from: 0, to: 16, by: 2)), perc: [15]),
        BeatPattern(name: "House",     bpm: 124, kick: [0, 4, 8, 12],     snare: [4, 12],       hat: [2, 6, 10, 14],      perc: [7]),
        BeatPattern(name: "Hip-Hop",   bpm: 92,  kick: [0, 7, 10],        snare: [4, 12],       hat: Array(stride(from: 0, to: 16, by: 2)), perc: [14]),
        BeatPattern(name: "Disco",     bpm: 120, kick: [0, 4, 8, 12],     snare: [4, 12],       hat: [2, 6, 10, 14],      perc: [0, 8]),
        BeatPattern(name: "Latin",     bpm: 104, kick: [0, 6, 10],        snare: [4, 13],       hat: [0, 3, 6, 10, 12],   perc: [2, 5, 9, 14]),
        BeatPattern(name: "Afro",      bpm: 108, kick: [0, 5, 8, 11],     snare: [4, 12],       hat: [0, 2, 4, 6, 8, 10, 12, 14], perc: [3, 7, 10, 15]),
        BeatPattern(name: "Percussion", bpm: 100, kick: [0, 8],           snare: [6, 14],       hat: [],                  perc: [0, 2, 3, 6, 8, 10, 11, 14]),
        BeatPattern(name: "Rock",      bpm: 112, kick: [0, 2, 8, 10],     snare: [4, 12],       hat: Array(stride(from: 0, to: 16, by: 2)), perc: []),
        BeatPattern(name: "Minimal",   bpm: 96,  kick: [0],               snare: [8],           hat: [4, 12],             perc: [])
    ]
    public func isValid() -> Bool { ([kick, snare, hat, perc].allSatisfy { $0.allSatisfy { (0..<16).contains($0) } }) && !kick.isEmpty }
    /// Beat grid for a generated track started at `start` (generated audio is its own clock authority).
    public func grid(start: TimeInterval) -> MusicGrid { MusicGrid(bpm: bpm, phase: start, beatsPerBar: 4, downbeatOffset: 0) }
}

public enum PlaybackOrder: String, Codable, Sendable { case automatic, inOrder, shuffle }
public enum Playlist {
    /// Deterministic ordering (seeded) so shuffle is testable and stable across relaunch.
    public static func order(_ ids: [String], mode: PlaybackOrder, seed: UInt64 = 1, currentTempo: [String: Double] = [:]) -> [String] {
        switch mode {
        case .inOrder: return ids
        case .automatic: return ids.sorted { (currentTempo[$0] ?? 0, $0) < (currentTempo[$1] ?? 0, $1) }   // gentle build by tempo
        case .shuffle:
            var s = seed == 0 ? 1 : seed; var a = ids
            for i in stride(from: a.count - 1, to: 0, by: -1) {
                s = s &* 6364136223846793005 &+ 1442695040888963407
                a.swapAt(i, Int((s >> 33) % UInt64(i + 1)))
            }
            return a
        }
    }
}
