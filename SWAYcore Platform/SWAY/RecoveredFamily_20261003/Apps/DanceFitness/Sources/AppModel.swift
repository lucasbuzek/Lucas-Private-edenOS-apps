import SwiftUI
import SWAYcoreKit
import SWAYAppKit

struct UserSettings: Codable, Equatable {
    var coach: CoachID = .lucia
    var voice: VoiceLevel = .normal
    var lowImpact = false
    var reducedMotion = false
    var dancer = DancerLook()
    var onboarded = false
}
/// YOUR DANCER customisation: every option maps to a real mesh variant or material tint in the production asset.
struct DancerLook: Codable, Equatable {
    var hair = "short", outfit = "Tee"
    static let hairStyles = ["short", "long", "braids", "afro", "bun"], outfits = ["Tee", "Tank", "Jacket"]
}
struct PersistedState: Codable { var settings = UserSettings(); var progress = LearnerProgress(); var custom: [MovementDefinition] = []; var combos: [Combination] = [] }

@MainActor final class AppModel: ObservableObject {
    @Published var state = PersistedState() { didSet { save() } }
    @Published var importError: String?
    private let store: JSONFileStore<PersistedState>
    let speech = SpeechService(); let beats = BeatPlayer(); let health = HealthService(); let music = AppleMusicService(); let shazam = ShazamService()

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("SWAYcore")
        store = JSONFileStore(url: dir.appendingPathComponent("dance-fitness.json"))
        if let s = try? store.load() { state = s }
    }
    private func save() { try? store.save(state) }

    var library: [MovementDefinition] { MoveLibrary.all + state.custom }
    var lookup: [String: MovementDefinition] { Dictionary(uniqueKeysWithValues: library.map { ($0.id, $0) }) }
    var visibleLibrary: [MovementDefinition] { state.settings.lowImpact ? library.filter(\.lowImpact) : library }
    func mastery(_ id: String) -> Mastery { state.progress.mastery[id] ?? .discovered }

    func today() -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX"); return f.string(from: Date()) }
    func complete(movementIDs: [String], score: ScoreAccumulator) { for id in movementIDs { state.progress.recordAttempt(movementID: id, score: score, day: today()) } }

    // Create / share
    func save(move: MovementDefinition) { if let i = state.custom.firstIndex(where: { $0.id == move.id }) { state.custom[i] = move } else { state.custom.append(move) } }
    func exportPack(title: String, ids: [String]) throws -> URL {
        let ms = ids.compactMap { lookup[$0] }
        let pack = SwayPack(id: UUID().uuidString, title: title, movements: ms)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(title.replacingOccurrences(of: "/", with: "-") + ".swaypack")
        try pack.export().write(to: url); return url
    }
    func importPack(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let pack = try SwayPack.import(try Data(contentsOf: url))
            for m in pack.movements { save(move: m) }
            state.combos.append(contentsOf: pack.combinations.filter { c in !state.combos.contains { $0.id == c.id } })
            importError = nil
        } catch { importError = "Couldn't import that file: \(error)" }
    }
}
