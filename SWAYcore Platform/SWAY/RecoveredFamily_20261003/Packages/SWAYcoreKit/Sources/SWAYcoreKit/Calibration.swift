import Foundation

/// Six-action calibration contract: STEP INTO VIEW -> WAVE LEFT -> WAVE RIGHT -> LIFT LEFT FOOT -> LIFT RIGHT FOOT -> JUMP -> READY TO SWAY.
public enum CalibrationStep: Int, CaseIterable, Codable, Sendable {
    case stepIntoView, waveLeft, waveRight, liftLeftFoot, liftRightFoot, jump, ready
    public var prompt: String {
        switch self {
        case .stepIntoView: return "STEP INTO VIEW"
        case .waveLeft: return "WAVE LEFT"
        case .waveRight: return "WAVE RIGHT"
        case .liftLeftFoot: return "LIFT LEFT FOOT"
        case .liftRightFoot: return "LIFT RIGHT FOOT"
        case .jump: return "JUMP"
        case .ready: return "READY TO SWAY"
        }
    }
}

public struct CalibrationState: Equatable, Sendable {
    public init() {}
    public var step: CalibrationStep = .stepIntoView
    public var completed: [CalibrationStep] = []
    public var inView = false
    public var isReady: Bool { step == .ready }
}

/// Deterministic, evidence-driven calibration. Joint L/R are the SUBJECT's left/right.
public struct CalibrationEngine: Sendable {
    public private(set) var state = CalibrationState()
    private var inViewFrames = 0
    private var raisedFrames = 0
    private var waveXs: [Double] = []
    private var liftFrames = 0
    private var baselineHipY: Double?
    private var baselineAnkleY: Double?
    private var jumpPeaked = false
    public var requiredInViewFrames = 8
    public var requiredLiftFrames = 4

    public init() {}

    public mutating func reset() { self = CalibrationEngine() }

    /// Feed one observation (nil = nothing observed). Returns the updated state.
    @discardableResult
    public mutating func ingest(_ obs: TrackingObservation?) -> CalibrationState {
        guard state.step != .ready else { return state }
        guard let obs, let torso = PoseNormalizer.torsoLength(obs.raw) else { loseTrack(); return state }
        let r = obs.raw
        func ok(_ j: SWAYJoint) -> JointSample? { if let s = r[j], s.confidence >= PoseNormalizer.minConfidence { return s }; return nil }

        let required: [SWAYJoint] = [.neck, .shoulderL, .shoulderR, .hipL, .hipR, .ankleL, .ankleR, .wristL, .wristR]
        let full = required.allSatisfy { j in
            guard let s = ok(j) else { return false }
            return s.position.x > 0.02 && s.position.x < 0.98 && s.position.y > 0.02 && s.position.y < 0.98
        }
        state.inView = full
        if !full && state.step != .stepIntoView { raisedFrames = 0; liftFrames = 0; return state }

        switch state.step {
        case .stepIntoView:
            inViewFrames = full ? inViewFrames + 1 : 0
            if inViewFrames >= requiredInViewFrames {
                baselineHipY = PoseNormalizer.hipCenter(r)?.y
                baselineAnkleY = ((ok(.ankleL)?.position.y ?? 0) + (ok(.ankleR)?.position.y ?? 0)) / 2
                advance()
            }
        case .waveLeft: waveStep(wrist: .wristL, shoulder: .shoulderL, torso: torso, r: r, ok: ok)
        case .waveRight: waveStep(wrist: .wristR, shoulder: .shoulderR, torso: torso, r: r, ok: ok)
        case .liftLeftFoot: liftStep(lifted: .ankleL, other: .ankleR, torso: torso, ok: ok)
        case .liftRightFoot: liftStep(lifted: .ankleR, other: .ankleL, torso: torso, ok: ok)
        case .jump:
            guard let hip = PoseNormalizer.hipCenter(r), let h0 = baselineHipY, let a0 = baselineAnkleY,
                  let aL = ok(.ankleL), let aR = ok(.ankleR) else { break }
            let rise = (hip.y - h0) / torso
            let ankleRise = ((aL.position.y + aR.position.y) / 2 - a0) / torso
            if rise > 0.12 && ankleRise > 0.1 { jumpPeaked = true }
            if jumpPeaked && rise < 0.04 { advance() }
        case .ready: break
        }
        return state
    }

    private mutating func waveStep(wrist: SWAYJoint, shoulder: SWAYJoint, torso: Double, r: [SWAYJoint: JointSample], ok: (SWAYJoint) -> JointSample?) {
        guard let w = ok(wrist), let s = ok(shoulder) else { return }
        if (w.position.y - s.position.y) / torso > 0.1 {
            raisedFrames += 1; waveXs.append(w.position.x / torso)
            if waveXs.count > 60 { waveXs.removeFirst() }
            // require raised hand plus lateral oscillation (>= 2 reversals, amplitude > 0.12 torso)
            if raisedFrames >= 6 && Self.reversals(waveXs, minDelta: 0.04) >= 2 && ((waveXs.max() ?? 0) - (waveXs.min() ?? 0)) > 0.12 { advance() }
        } else { raisedFrames = 0; waveXs.removeAll() }
    }

    private mutating func liftStep(lifted: SWAYJoint, other: SWAYJoint, torso: Double, ok: (SWAYJoint) -> JointSample?) {
        guard let a = ok(lifted), let b = ok(other) else { return }
        if (a.position.y - b.position.y) / torso > 0.2 { liftFrames += 1 } else { liftFrames = 0 }
        if liftFrames >= requiredLiftFrames { advance() }
    }

    private mutating func advance() {
        state.completed.append(state.step)
        state.step = CalibrationStep(rawValue: state.step.rawValue + 1) ?? .ready
        raisedFrames = 0; waveXs.removeAll(); liftFrames = 0; jumpPeaked = false
    }

    /// Tracking loss keeps completed steps; in-progress evidence is discarded.
    private mutating func loseTrack() {
        state.inView = false; inViewFrames = 0; raisedFrames = 0; waveXs.removeAll(); liftFrames = 0
    }

    static func reversals(_ xs: [Double], minDelta: Double) -> Int {
        var count = 0; var dir = 0; var anchor = xs.first ?? 0
        for x in xs.dropFirst() {
            let d = x - anchor
            if abs(d) < minDelta { continue }
            let nd = d > 0 ? 1 : -1
            if dir != 0 && nd != dir { count += 1 }
            dir = nd; anchor = x
        }
        return count
    }
}
