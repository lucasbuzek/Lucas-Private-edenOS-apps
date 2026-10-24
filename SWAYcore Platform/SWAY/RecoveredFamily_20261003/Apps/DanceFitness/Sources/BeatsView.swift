import SwiftUI
import UniformTypeIdentifiers
import MusicKit
import SWAYcoreKit
import SWAYAppKit

struct BeatsView: View {
    @EnvironmentObject var model: AppModel
    @State private var playing: String?
    @State private var bpm = 100.0
    @State private var order: PlaybackOrder = .inOrder
    @State private var importing = false
    @State private var analysis: String?
    @State private var tap = TapTempo()
    @State private var term = ""
    @State private var songs: [Song] = []
    var body: some View {
        NavigationStack {
            List {
                Section("SWAY Beats (offline)") {
                    Picker("Order", selection: $order) { Text("Automatic").tag(PlaybackOrder.automatic); Text("In order").tag(PlaybackOrder.inOrder); Text("Shuffle").tag(PlaybackOrder.shuffle) }.pickerStyle(.segmented)
                    let names = Playlist.order(BeatPattern.all.map(\.name), mode: order, seed: 7, currentTempo: Dictionary(uniqueKeysWithValues: BeatPattern.all.map { ($0.name, $0.bpm) }))
                    ForEach(names, id: \.self) { n in
                        let p = BeatPattern.all.first { $0.name == n }!
                        HStack { VStack(alignment: .leading) { Text(p.name).font(.headline); Text("\(Int(p.bpm)) BPM").font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Button(playing == n ? "Stop" : "Play") { toggle(p) }.buttonStyle(.bordered) }
                    }
                    if playing != nil { HStack { Text("Tempo"); Slider(value: $bpm, in: 70...160, step: 1) { _ in restart() }; Text("\(Int(bpm))").monospacedDigit() } }
                }
                Section("Your music") {
                    Button("Analyze an audio file…") { importing = true }
                    if let analysis { Text(analysis).font(.footnote) }
                    Text("Tempo, beat phase and bar line are estimated from the audio itself.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Apple Music") {
                    if model.music.status != .authorized { Button("Connect Apple Music") { Task { await model.music.requestAccess() } } } else {
                        TextField("Search songs", text: $term).onSubmit { Task { songs = (try? await model.music.search(term)) ?? [] } }
                        ForEach(songs, id: \.id) { s in Button { Task { try? await model.music.play(s) } } label: { VStack(alignment: .leading) { Text(s.title); Text(s.artistName).font(.caption).foregroundStyle(.secondary) } } }
                        Button("Tap the beat (\(tap.bpm.map { "\(Int($0)) BPM" } ?? "tap 4+ times"))") { tap.tap(at: ProcessInfo.processInfo.systemUptime) }
                        Button("Recognize what's playing (Shazam)") { Task { await model.shazam.recognize() } }
                        if let m = model.shazam.lastMatch { Text("\(m.title) — \(m.artist ?? "")").font(.footnote) }
                        Text("Protected Apple Music audio is never analysed; tempo comes from tapping.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.scrollContentBackground(.hidden).navigationTitle("BEATS")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.audio]) { r in
                guard case .success(let u) = r else { return }
                let ok = u.startAccessingSecurityScopedResource(); defer { if ok { u.stopAccessingSecurityScopedResource() } }
                do { if let a = try AudioAnalyzer.analyze(url: u) { analysis = String(format: "%.1f BPM · downbeat offset %d · confidence %.0f%%", a.grid.bpm, a.grid.downbeatOffset, a.confidence * 100) } else { analysis = "Couldn't find a steady beat in this file." } }
                catch { analysis = "Couldn't read this file: \(error.localizedDescription)" }
            }
        }
    }
    func toggle(_ p: BeatPattern) { if playing == p.name { model.beats.stop(); playing = nil } else { bpm = p.bpm; try? model.beats.start(p); playing = p.name } }
    func restart() { if let n = playing, let p = BeatPattern.all.first(where: { $0.name == n }) { try? model.beats.start(p, bpm: bpm) } }
}
