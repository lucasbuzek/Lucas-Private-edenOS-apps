import SwiftUI
import SWAYcoreKit
import SWAYAppKit

@main struct SWAYZApp: App {
    @StateObject private var studio = AuthoringModel()
    var body: some Scene { WindowGroup { SWAYZRoot().environmentObject(studio).preferredColorScheme(.dark).tint(SwayTheme.magenta) } }
}

/// SWAYZ authoring state. Uses the SAME MovementDefinition / SwayPack the learner runtime consumes (no second schema).
@MainActor final class AuthoringModel: ObservableObject {
    struct Doc: Codable { var moves: [MovementDefinition] = []; var steps: [ContentStep] = []; var title = "Untitled Routine"; var grid: MusicGrid? }
    @Published var doc = Doc() { didSet { try? store.save(doc) } }
    @Published var draft = MoveDraft(name: "New Move")
    @Published var message: String?
    private let store: JSONFileStore<Doc>
    let beats = BeatPlayer()
    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("SWAYZ")
        store = JSONFileStore(url: dir.appendingPathComponent("library.json"))
        if let d = try? store.load() { doc = d }
    }
    var library: [String: MovementDefinition] { Dictionary(uniqueKeysWithValues: (MoveLibrary.all + doc.moves).map { ($0.id, $0) }) }
    func commitDraft() { do { let m = try draft.build(); if let i = doc.moves.firstIndex(where: { $0.id == m.id }) { doc.moves[i] = m } else { doc.moves.append(m) }; message = "Saved \(m.name) (rev \(m.revision))" } catch { message = "Author at least one count first." } }
    func exportURL() throws -> URL {
        var ch = ChoreographyDraft(id: "routine-" + doc.title, name: doc.title); ch.steps = doc.steps; ch.grid = doc.grid
        let pack = try ch.pack(movements: library, author: nil)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(doc.title.replacingOccurrences(of: "/", with: "-") + ".swaypack")
        try pack.export().write(to: url); return url
    }
    func importPack(_ url: URL) {
        let ok = url.startAccessingSecurityScopedResource(); defer { if ok { url.stopAccessingSecurityScopedResource() } }
        do {
            let p = try SwayPack.import(try Data(contentsOf: url))
            for m in p.movements where MoveLibrary.byID[m.id] == nil { if let i = doc.moves.firstIndex(where: { $0.id == m.id }) { doc.moves[i] = m } else { doc.moves.append(m) } }
            if let c = p.combinations.first { doc.steps = c.steps; doc.title = p.title }
            if let g = p.musicReferences.compactMap(\.grid).first { doc.grid = g }
            message = "Imported \(p.title)"
        } catch { message = "Couldn't import: \(error)" }
    }
}
