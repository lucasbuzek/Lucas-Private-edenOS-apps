import Foundation
import AVFoundation
import MusicKit
import ShazamKit
import HealthKit
import SWAYcoreKit

// MARK: Speech — one cue, natural, non-overlapping.
@MainActor public final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private var currentPriority = 0
    public var level: VoiceLevel = .normal
    public override init() { super.init(); synth.delegate = self }
    public func speak(_ cue: CoachCue) {
        guard level != .off, let text = cue.spoken else { return }
        if synth.isSpeaking { if cue.priority > currentPriority { synth.stopSpeaking(at: .immediate) } else { return } }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en-US") ?? AVSpeechSynthesisVoice(language: "en-US")
        u.rate = AVSpeechUtteranceDefaultSpeechRate; currentPriority = cue.priority; synth.speak(u)
    }
    public func stop() { synth.stopSpeaking(at: .immediate) }
    nonisolated public func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { Task { @MainActor in self.currentPriority = 0 } }
}

// MARK: Generated SWAY Beats (offline) — generated audio is its own clock authority.
@MainActor public final class BeatPlayer {
    private let engine = AVAudioEngine(); private let node = AVAudioPlayerNode()
    public private(set) var pattern: BeatPattern?
    public private(set) var startHostTime: TimeInterval = 0
    public init() { engine.attach(node); engine.connect(node, to: engine.mainMixerNode, format: nil) }

    public func start(_ p: BeatPattern, bpm: Double? = nil) throws {
        stop()
        var pat = p; if let bpm { pat.bpm = bpm }
        let sr = 44100.0; let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        let stepSec = 60.0 / pat.bpm / 4.0; let n = AVAudioFrameCount(stepSec * 16 * sr)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n)!; buf.frameLength = n
        let d = buf.floatChannelData![0]; for i in 0..<Int(n) { d[i] = 0 }
        func add(_ step: Int, _ gen: (Double) -> Double, _ dur: Double, _ amp: Float) {
            let s0 = Int(Double(step) * stepSec * sr)
            for i in 0..<Int(dur * sr) where s0 + i < Int(n) { d[s0 + i] += amp * Float(gen(Double(i) / sr)) }
        }
        var seed: UInt32 = 12345
        func noise() -> Double { seed = seed &* 1664525 &+ 1013904223; return Double(seed >> 8) / Double(1 << 24) * 2 - 1 }
        for s in pat.kick { add(s, { t in sin(2 * .pi * (150 * exp(-t * 18) + 45) * t) * exp(-t * 7) }, 0.3, 0.9) }
        for s in pat.snare { add(s, { t in (noise() * 0.7 + sin(2 * .pi * 190 * t) * 0.3) * exp(-t * 18) }, 0.2, 0.55) }
        for s in pat.hat { add(s, { t in noise() * exp(-t * 60) }, 0.06, 0.25) }
        for s in pat.perc { add(s, { t in sin(2 * .pi * 800 * t) * exp(-t * 40) + noise() * 0.2 * exp(-t * 50) }, 0.12, 0.3) }
        #if os(iOS)
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default); try AVAudioSession.sharedInstance().setActive(true)
        #endif
        try engine.start(); node.scheduleBuffer(buf, at: nil, options: .loops); node.play()
        pattern = pat; startHostTime = ProcessInfo.processInfo.systemUptime
    }
    public var grid: MusicGrid? { pattern?.grid(start: startHostTime) }
    public func stop() { node.stop(); engine.stop(); pattern = nil }
    public func pause() { node.pause() }
    public func resume() { node.play() }
}

// MARK: Offline analysis of imported/local audio files (energy-flux onsets -> BeatAnalyzer).
public enum AudioAnalyzer {
    public static func analyze(url: URL, maxSeconds: Double = 90) throws -> BeatAnalyzer.Result? {
        let f = try AVAudioFile(forReading: url); let sr = f.processingFormat.sampleRate
        let frames = AVAudioFrameCount(min(Double(f.length), maxSeconds * sr))
        guard let buf = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: frames) else { return nil }
        try f.read(into: buf, frameCount: frames)
        guard let ch = buf.floatChannelData?[0] else { return nil }
        let hop = 512; var energies: [Double] = []; var i = 0
        while i + hop <= Int(buf.frameLength) { var e = 0.0; for k in 0..<hop { let v = Double(ch[i + k]); e += v * v }; energies.append(e.squareRoot()); i += hop }
        var flux = [Double](); for k in 1..<max(energies.count, 2) { flux.append(max(0, energies[k] - energies[k - 1])) }
        guard flux.count > 16 else { return nil }
        let mean = flux.reduce(0, +) / Double(flux.count), sd = (flux.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(flux.count)).squareRoot()
        var onsets: [Double] = [], strengths: [Double] = []
        for k in 2..<(flux.count - 2) where flux[k] > mean + 1.2 * sd && flux[k] >= flux[k - 1] && flux[k] > flux[k + 1] {
            let t = Double(k + 1) * Double(hop) / sr
            if let last = onsets.last, t - last < 0.12 { continue }
            onsets.append(t); strengths.append(flux[k])
        }
        return BeatAnalyzer.estimate(onsets: onsets, strengths: strengths)
    }
}

// MARK: MusicKit (Apple Music) — playback/search only; protected audio is never analysed or embedded.
@MainActor public final class AppleMusicService: ObservableObject {
    @Published public var status: MusicAuthorization.Status = MusicAuthorization.currentStatus
    public init() {}
    public func requestAccess() async { status = await MusicAuthorization.request() }
    public func search(_ term: String) async throws -> [Song] {
        guard status == .authorized else { return [] }
        var r = MusicCatalogSearchRequest(term: term, types: [Song.self]); r.limit = 15
        return Array(try await r.response().songs)
    }
    public func play(_ song: Song) async throws {
        let p = ApplicationMusicPlayer.shared; p.queue = [song]; try await p.play()
    }
    public func pause() { ApplicationMusicPlayer.shared.pause() }
    /// Phase for protected audio comes from tap-tempo or Shazam sync, never from analysing the stream.
}

// MARK: ShazamKit — supportive recognition; never the clock authority.
@MainActor public final class ShazamService: ObservableObject {
    @Published public var lastMatch: (title: String, artist: String?)?
    private let session = SHManagedSession()
    public init() {}
    public func recognize() async {
        let r = await session.result()
        if case .match(let m) = r, let item = m.mediaItems.first { lastMatch = (item.title ?? "Unknown", item.artist) }
    }
    public func cancel() { session.cancel() }
}

// MARK: HealthKit — permissions, workout save, explicit error states.
public enum HealthState: Equatable { case unavailable, notDetermined, denied, authorized, error(String) }
@MainActor public final class HealthService: ObservableObject {
    @Published public private(set) var state: HealthState = .notDetermined
    private let store = HKHealthStore()
    public init() { if !HKHealthStore.isHealthDataAvailable() { state = .unavailable } }
    public func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else { state = .unavailable; return }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType(), HKQuantityType(.activeEnergyBurned)], read: [])
            state = store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized ? .authorized : .denied
        } catch { state = .error(error.localizedDescription) }
    }
    public func saveDance(start: Date, end: Date, kilocalories: Double?) async {
        guard state == .authorized else { return }
        let cfg = HKWorkoutConfiguration(); cfg.activityType = .socialDance
        let b = HKWorkoutBuilder(healthStore: store, configuration: cfg, device: .local())
        do {
            try await b.beginCollection(at: start)
            if let k = kilocalories, k > 0 {
                let s = HKQuantitySample(type: HKQuantityType(.activeEnergyBurned), quantity: HKQuantity(unit: .kilocalorie(), doubleValue: k), start: start, end: end)
                try await b.addSamples([s])
            }
            try await b.endCollection(at: end); _ = try await b.finishWorkout()
        } catch { state = .error(error.localizedDescription) }
    }
}
