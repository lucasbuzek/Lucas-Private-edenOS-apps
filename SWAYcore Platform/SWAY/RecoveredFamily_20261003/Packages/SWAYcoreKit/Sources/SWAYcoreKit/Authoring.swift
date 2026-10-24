import Foundation

/// SWAYZ / Create Move authoring model. Produces the SAME MovementDefinition/SwayPack the learner runtime consumes.
public struct MoveDraft: Equatable, Sendable {
    public var id: String, name: String, instruction: String
    public var complexity: Complexity = .easy
    public var intensity: Intensity = .medium
    public var beatsPerCycle = 8
    /// One stance per count (1...beatsPerCycle); nil = not yet authored (interpolates between neighbours).
    public private(set) var stances: [Int: Stance] = [:]
    public private(set) var holds: Set<Int> = []
    public private(set) var cues: [Int: String] = [:]
    public private(set) var revision = 1

    public init(id: String = UUID().uuidString, name: String, instruction: String = "") { self.id = id; self.name = name; self.instruction = instruction }

    public init(editing m: MovementDefinition) {
        self.init(id: m.id, name: m.name, instruction: m.instruction)
        complexity = m.complexity; intensity = m.intensity; beatsPerCycle = m.beatsPerCycle; revision = m.revision + 1
        capturedPoses = Dictionary(uniqueKeysWithValues: m.keyframes.map { ($0.count, $0.pose) })
        for k in m.keyframes { if k.hold { holds.insert(k.count) }; if let c = k.cue { cues[k.count] = c } }
    }
    /// Poses imported from existing content/camera capture (take precedence over stances when no stance set).
    public private(set) var capturedPoses: [Int: Pose] = [:]

    public mutating func set(count: Int, stance: Stance) throws {
        guard (1...beatsPerCycle).contains(count) else { throw MovementDefinition.ValidationError.badCount(count) }
        stances[count] = stance; capturedPoses[count] = nil
    }
    public mutating func set(count: Int, capturedPose: Pose) throws {
        guard (1...beatsPerCycle).contains(count) else { throw MovementDefinition.ValidationError.badCount(count) }
        guard SWAYJoint.allCases.allSatisfy({ capturedPose[$0] != nil }) else { throw MovementDefinition.ValidationError.missingJoints(count: count) }
        capturedPoses[count] = capturedPose; stances[count] = nil
    }
    public mutating func setHold(count: Int, _ on: Bool) { if on { holds.insert(count) } else { holds.remove(count) } }
    public mutating func setCue(count: Int, _ text: String?) { cues[count] = (text?.isEmpty ?? true) ? nil : text }
    public mutating func clear(count: Int) { stances[count] = nil; capturedPoses[count] = nil; holds.remove(count); cues[count] = nil }

    public var authoredCounts: [Int] { Set(stances.keys).union(capturedPoses.keys).sorted() }

    /// Needs at least 2 authored counts (or 1 hold) to be a movement.
    public func build() throws -> MovementDefinition {
        guard !authoredCounts.isEmpty else { throw MovementDefinition.ValidationError.noKeyframes }
        let kfs = authoredCounts.map { c in
            CountKeyframe(count: c, pose: capturedPoses[c] ?? PoseBuilder.build(stances[c]!), hold: holds.contains(c), cue: cues[c])
        }
        let m = MovementDefinition(id: id, name: name, complexity: complexity, intensity: intensity, beatsPerCycle: beatsPerCycle,
                                   keyframes: kfs, instruction: instruction, revision: revision)
        try m.validate(); return m
    }
}

/// Builds a movement from a sequence of camera-captured normalized poses (Create Move).
public enum PoseCapture {
    public enum CaptureError: Error, Equatable { case tooFewPoses, lowQuality(count: Int) }
    /// `poses`: time-ordered normalized poses sampled across one cycle. They are resampled to `beatsPerCycle` counts.
    /// Missing joints (low confidence) are rejected rather than invented. Depth (z) is unknown and set to 0.
    public static func movement(id: String, name: String, poses: [Pose], beatsPerCycle: Int = 8) throws -> MovementDefinition {
        guard poses.count >= 2 else { throw CaptureError.tooFewPoses }
        var draft = MoveDraft(id: id, name: name); draft.beatsPerCycle = beatsPerCycle
        for c in 1...beatsPerCycle {
            let f = Double(c - 1) / Double(beatsPerCycle) * Double(poses.count)
            let i = min(Int(f), poses.count - 1), j = (i + 1) % poses.count
            let blended = Pose.lerp(poses[i], poses[j], f - Double(i))
            let complete = PoseCompleter.complete(blended)
            guard SWAYJoint.allCases.allSatisfy({ complete[$0] != nil }) else { throw CaptureError.lowQuality(count: c) }
            try draft.set(count: c, capturedPose: complete)
        }
        return try draft.build()
    }
}

/// Ordered choreography authored in SWAYZ (moves + mirror + reps + formation metadata) mapped onto the common model.
public struct ChoreographyDraft: Equatable, Sendable {
    public var id: String, name: String
    public var steps: [ContentStep] = []
    public var grid: MusicGrid?
    public init(id: String = UUID().uuidString, name: String) { self.id = id; self.name = name }
    public mutating func append(_ movementID: String, repetitions: Int = 1, mirrored: Bool = false, formation: String? = nil) { steps.append(ContentStep(movementID: movementID, repetitions: max(1, repetitions), mirrored: mirrored, formation: formation)) }
    public mutating func move(from: Int, to: Int) { guard steps.indices.contains(from), (0...steps.count - 1).contains(to) else { return }; steps.insert(steps.remove(at: from), at: to) }
    public mutating func remove(at i: Int) { if steps.indices.contains(i) { steps.remove(at: i) } }
    public func combination(complexity: Complexity = .easy) -> Combination { Combination(id: id, name: name, steps: steps, complexity: complexity) }
    /// Cue placement: (global beat, cue text) from each move's authored cues, in timeline order.
    public func cues(movements: [String: MovementDefinition]) -> [(beat: Int, text: String)] {
        let tl = ChoreographyTimeline(steps: steps, movements: movements); var out: [(Int, String)] = []
        for seg in tl.segments { guard let m = movements[seg.movementID] else { continue }
            for rep in 0..<(seg.beats / m.beatsPerCycle) { for k in m.keyframes { if let c = k.cue { out.append((seg.startBeat + rep * m.beatsPerCycle + k.count - 1, c)) } } } }
        return out
    }
    /// Package for export with only the moves the choreography uses (+ any extras).
    public func pack(movements: [String: MovementDefinition], author: String? = nil, music: [SwayPack.MusicReference] = []) throws -> SwayPack {
        let used = Set(steps.map(\.movementID)); var refs = music
        if let g = grid, refs.isEmpty { refs = [SwayPack.MusicReference(title: "Grid", bpm: g.bpm, grid: g)] }
        let ms = used.sorted().compactMap { movements[$0] }
        let p = SwayPack(id: id, title: name, author: author, movements: ms, combinations: [combination()], musicReferences: refs)
        try p.validate(); return p
    }
}

/// Derives structural joints that camera pose estimators do not report, and (for DISPLAY only) fills missing joints from a fallback.
/// Matching never uses completed joints: it reads raw observations with their confidences.
public enum PoseCompleter {
    public static func complete(_ pose: Pose, fallback: Pose? = nil) -> Pose {
        var out = pose
        if let h = out[.hips], let n = out[.neck] {
            out[.spine] = out[.spine] ?? JointSample(Vec3.lerp(h.position, n.position, 0.35))
            out[.chest] = out[.chest] ?? JointSample(Vec3.lerp(h.position, n.position, 0.7))
            out[.root] = out[.root] ?? JointSample(h.position + Vec3(0, -0.05, 0))
            if let head = out[.head] { out[.headEnd] = out[.headEnd] ?? JointSample(head.position + (head.position - n.position).normalized * 0.3) }
        }
        for s in ["L", "R"] {
            func J(_ n: String) -> SWAYJoint { SWAYJoint(rawValue: n + s)! }
            if let w = out[J("wrist")], let e = out[J("elbow")] { out[J("hand")] = out[J("hand")] ?? JointSample(w.position + (w.position - e.position).normalized * Proportions.hand) }
            if let a = out[J("ankle")] { out[J("toes")] = out[J("toes")] ?? JointSample(a.position + Vec3(0, 0, Proportions.foot)) }
        }
        if let fb = fallback { for j in SWAYJoint.allCases where out[j] == nil { out[j] = fb[j] } }
        return out
    }
    /// Exponential smoothing for display.
    public static func smooth(_ new: Pose, previous: Pose?, alpha: Double = 0.5) -> Pose {
        guard let prev = previous else { return new }
        var out = new
        for j in SWAYJoint.allCases { if let a = new[j], let b = prev[j] { out[j] = JointSample(Vec3.lerp(b.position, a.position, alpha), confidence: a.confidence) } }
        return out
    }
}
