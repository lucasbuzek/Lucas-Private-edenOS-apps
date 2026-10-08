import Foundation
import SwiftUI
import SWAYcoreEngine

/// UI-facing owner for calibration. CameraPoseService remains the Vision adapter;
/// views bind only to this stable, testable state surface.
@MainActor final class CalibrationSession: ObservableObject {
    @Published private(set) var stage: SwayCalibrationStage = .frame
    @Published private(set) var instruction = SwayCalibrationStage.frame.title
    @Published private(set) var isReady = false
    @Published private(set) var trackingLost = false
    @Published private(set) var timedOut = false
    @Published private(set) var lowImpact = false
    @Published private(set) var lastEvents: [SwayCalibrationEvent] = []
    private var machine = SwayCalibrationMachine()

    func ingest(_ frame: SwayCalibrationFrame) { lastEvents = machine.ingest(frame); publish() }
    func retry() { machine.continueAfterTimeout(); publish() }
    func skipJump() { lastEvents = machine.skipJump(); publish() }
    func geometryChanged() { machine.geometryChanged(); publish() }
    func restart() { machine.restart(); lastEvents = []; publish() }
    func cancel() { lastEvents = machine.cancel(); publish() }

    private func publish() {
        stage = machine.stage; instruction = machine.status; isReady = machine.isReady
        trackingLost = machine.trackingLost; timedOut = machine.timedOut; lowImpact = machine.lowImpact
    }
}

/// Observable projection of the canonical monotonic timeline. A display-link or
/// audio callback supplies uptime; this service does not create a second timer.
@MainActor final class SwayTimelineSession: ObservableObject {
    @Published private(set) var musicalTime: TimeInterval = 0
    @Published private(set) var position = SwayMusicalPosition(beat: 0, count: 1, bar: 0, phrase: 0, beatPhase: 0)
    @Published private(set) var isPaused = true
    @Published private(set) var isComplete = false
    var bpm: Double { didSet { refresh() } }
    var plan: SwayTimelinePlan { didSet { refresh() } }
    private var clock = SwayMusicalClock()

    init(bpm: Double = 120, totalCounts: Int = 8) { self.bpm = bpm; plan = SwayTimelinePlan(bpm: bpm, totalCounts: totalCounts) }
    func start(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) { clock.start(at: uptime); isPaused = false; refresh() }
    func tick(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) { musicalTime = clock.update(at: uptime); refresh() }
    func pause(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) { clock.pause(at: uptime); isPaused = true; refresh() }
    func resume(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) { clock.resume(at: uptime); isPaused = false }
    func restart(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) { clock.restart(at: uptime); isPaused = false; refresh() }
    private func refresh() { musicalTime = clock.musicalTime; position = clock.position(bpm: bpm); isComplete = plan.isComplete(at: musicalTime) }
}

enum SwayDiagnostics {
    /// Developer destinations may remain compiled but consumer navigation must
    /// expose them only when this explicit launch argument is present.
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-SWAYDiagnostics") }
}
