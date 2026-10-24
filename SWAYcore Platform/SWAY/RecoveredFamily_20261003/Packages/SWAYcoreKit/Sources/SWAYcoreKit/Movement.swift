import Foundation

public enum Discipline: String, Codable, Sendable { case dance, fitness, yoga, taiChi, martialArts }
public enum Complexity: Int, Codable, CaseIterable, Sendable { case simple, easy, moderate, complex, expert }
public enum Mastery: Int, Codable, CaseIterable, Sendable { case discovered, learning, familiar, mastered }
public enum HierarchyLevel: String, Codable, CaseIterable, Sendable { case move, variation, combination, routine, workout, challenge, program }
public enum Intensity: Int, Codable, Sendable { case low, medium, high }

/// One authored count (1...8). Pose is derived from the stance but stored so imported content is exact.
public struct CountKeyframe: Codable, Equatable, Sendable {
    public var count: Int
    public var pose: Pose
    public var hold: Bool
    public var cue: String?
    public init(count: Int, pose: Pose, hold: Bool = false, cue: String? = nil) {
        self.count = count; self.pose = pose; self.hold = hold; self.cue = cue
    }
}

public struct MovementDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var discipline: Discipline
    public var complexity: Complexity
    public var intensity: Intensity
    public var lowImpact: Bool
    public var symmetric: Bool          // true: mirrored variant is the same move
    public var beatsPerCycle: Int       // normally 8
    public var keyframes: [CountKeyframe]
    public var instruction: String
    public var level: HierarchyLevel
    public var revision: Int

    public init(id: String, name: String, discipline: Discipline = .dance, complexity: Complexity = .easy,
                intensity: Intensity = .medium, lowImpact: Bool = false, symmetric: Bool = true,
                beatsPerCycle: Int = 8, keyframes: [CountKeyframe], instruction: String = "",
                level: HierarchyLevel = .move, revision: Int = 1) {
        self.id = id; self.name = name; self.discipline = discipline; self.complexity = complexity
        self.intensity = intensity; self.lowImpact = lowImpact; self.symmetric = symmetric
        self.beatsPerCycle = beatsPerCycle; self.keyframes = keyframes.sorted { $0.count < $1.count }
        self.instruction = instruction; self.level = level; self.revision = revision
    }

    public enum ValidationError: Error, Equatable { case noKeyframes, badCount(Int), duplicateCount(Int), missingJoints(count: Int), badCycle }

    public func validate() throws {
        guard !keyframes.isEmpty else { throw ValidationError.noKeyframes }
        guard (1...64).contains(beatsPerCycle) else { throw ValidationError.badCycle }
        var seen = Set<Int>()
        for k in keyframes {
            guard (1...beatsPerCycle).contains(k.count) else { throw ValidationError.badCount(k.count) }
            guard seen.insert(k.count).inserted else { throw ValidationError.duplicateCount(k.count) }
            guard SWAYJoint.allCases.allSatisfy({ k.pose[$0] != nil }) else { throw ValidationError.missingJoints(count: k.count) }
        }
    }

    /// State exactly at integer count (1-based): deterministic selected-count display.
    public func pose(atCount count: Int, mirrored: Bool = false) -> Pose {
        let c = ((count - 1) % beatsPerCycle + beatsPerCycle) % beatsPerCycle
        return pose(atBeat: Double(c), mirrored: mirrored)
    }

    /// Interpolated pose at a cycle-relative beat (0 == count 1). Cyclic; hold keyframes dwell until the next count.
    public func pose(atBeat beat: Double, mirrored: Bool = false) -> Pose {
        guard !keyframes.isEmpty else { return Pose() }
        let cyc = Double(beatsPerCycle)
        var b = beat.truncatingRemainder(dividingBy: cyc); if b < 0 { b += cyc }
        let beats = keyframes.map { Double($0.count - 1) }
        let prev: CountKeyframe, next: CountKeyframe
        let prevBeat: Double, nextBeat: Double
        if let i = beats.lastIndex(where: { $0 <= b }) {
            prev = keyframes[i]; prevBeat = beats[i]
            if i + 1 < keyframes.count { next = keyframes[i + 1]; nextBeat = beats[i + 1] }
            else { next = keyframes[0]; nextBeat = beats[0] + cyc }
        } else {
            prev = keyframes[keyframes.count - 1]; prevBeat = beats[beats.count - 1] - cyc
            next = keyframes[0]; nextBeat = beats[0]
        }
        var result: Pose
        if prev.hold || nextBeat - prevBeat < 1e-9 { result = prev.pose }
        else { result = Pose.lerp(prev.pose, next.pose, (b - prevBeat) / (nextBeat - prevBeat)) }
        return mirrored ? result.mirroredPose() : result
    }
}

/// Reusable hierarchy above Move (Move -> Variation -> Combination -> Routine -> Workout -> Challenge -> Program).
public struct ContentStep: Codable, Equatable, Sendable {
    public var movementID: String
    public var repetitions: Int
    public var mirrored: Bool
    public var formation: String?   // optional choreography metadata (SWAYZ)
    public init(movementID: String, repetitions: Int = 1, mirrored: Bool = false, formation: String? = nil) {
        self.movementID = movementID; self.repetitions = repetitions; self.mirrored = mirrored; self.formation = formation
    }
}

public struct Combination: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var level: HierarchyLevel
    public var steps: [ContentStep]
    public var children: [String]       // ids of lower-level Combination/Routine content
    public var complexity: Complexity
    public var intensity: Intensity
    public init(id: String, name: String, level: HierarchyLevel = .combination, steps: [ContentStep] = [],
                children: [String] = [], complexity: Complexity = .easy, intensity: Intensity = .medium) {
        self.id = id; self.name = name; self.level = level; self.steps = steps; self.children = children
        self.complexity = complexity; self.intensity = intensity
    }
}

/// Flattened, deterministic choreography timeline: which move/mirror/count at any global beat.
public struct ChoreographyTimeline: Sendable {
    public struct Segment: Sendable { public let movementID: String; public let mirrored: Bool; public let startBeat: Int; public let beats: Int }
    public let segments: [Segment]
    public let totalBeats: Int

    public init(steps: [ContentStep], movements: [String: MovementDefinition]) {
        var segs: [Segment] = []; var cursor = 0
        for s in steps {
            guard let m = movements[s.movementID], s.repetitions > 0 else { continue }
            let len = m.beatsPerCycle * s.repetitions
            segs.append(Segment(movementID: s.movementID, mirrored: s.mirrored, startBeat: cursor, beats: len)); cursor += len
        }
        segments = segs; totalBeats = cursor
    }

    public func segment(atBeat beat: Double) -> (Segment, localBeat: Double)? {
        guard beat >= 0, beat < Double(totalBeats) else { return nil }
        for s in segments where beat < Double(s.startBeat + s.beats) { return (s, beat - Double(s.startBeat)) }
        return nil
    }
    public func next(afterBeat beat: Double) -> Segment? {
        for s in segments where Double(s.startBeat) > beat { return s }
        return nil
    }
}
