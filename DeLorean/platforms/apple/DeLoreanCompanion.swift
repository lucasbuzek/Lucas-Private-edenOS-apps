// DeLorean TimeMachine | Read-only Apple companion source candidate.
// iOS 17+ / macOS 14+, SwiftUI. Import exported catalog JSON through Files.
// No provider credentials or restore capability are embedded in this client.
import SwiftUI
import UniformTypeIdentifiers

struct DeLoreanCatalog: Decodable {
    let schema: String
    let snapshots: [Checkpoint]
    let events: [HistoryEvent]?
}
struct HistoryEvent: Decodable, Identifiable {
    let event_id: String
    let project: String
    let owner: String
    let provider: String
    let event_type: String
    let occurred_at: String
    let evidence: String
    var id: String { event_id }
}
struct Checkpoint: Decodable, Identifiable {
    let snapshot_id: String
    let project: String
    let owner: String
    let provider: String
    let provider_ref: String
    let recorded_at: String
    let evidence: String
    let files: [CheckpointFile]
    var id: String { snapshot_id }
}
struct CheckpointFile: Decodable, Identifiable {
    let path: String
    let size: Int64
    let sha256: String
    var id: String { path }
}

@MainActor
final class DeLoreanCatalogStore: ObservableObject {
    @Published var snapshots: [Checkpoint] = []
    @Published var events: [HistoryEvent] = []
    @Published var errorMessage: String?
    func importCatalog(from fileURL: URL) {
        let scoped = fileURL.startAccessingSecurityScopedResource()
        defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            guard (attr[.size] as? NSNumber)?.intValue ?? 0 < 8_388_608 else {
                throw NSError(domain: "DeLorean", code: 1, userInfo: [NSLocalizedDescriptionKey: "Catalog exceeds 8 MiB"])
            }
            let data = try Data(contentsOf: fileURL)
            let parsed = try JSONDecoder().decode(DeLoreanCatalog.self, from: data)
            guard parsed.schema == "eden.delorean.catalog.v1" else {
                throw NSError(domain: "DeLorean", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported catalog format"])
            }
            snapshots = parsed.snapshots
            events = parsed.events ?? []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct DeLoreanTimelineView: View {
    @StateObject private var store = DeLoreanCatalogStore()
    @State private var importPresented = false
    @State private var selected: Checkpoint?
    private var grouped: [String: [Checkpoint]] {
        Dictionary(grouping: store.snapshots, by: { "\($0.project) · \($0.owner)" })
    }
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(grouped.keys.sorted(), id: \.self) { key in
                    Section(key) {
                        ForEach((grouped[key] ?? []).sorted { $0.recorded_at > $1.recorded_at }) { checkpoint in
                            Button {
                                selected = checkpoint
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(checkpoint.recorded_at).font(.headline)
                                    Text("\(checkpoint.provider) · \(checkpoint.files.count) indexed files")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityLabel("Checkpoint \(checkpoint.recorded_at), \(checkpoint.files.count) files")
                        }
                    }
                }
                if !store.events.isEmpty {
                    Section("Provider history") {
                        ForEach(store.events.sorted { $0.occurred_at > $1.occurred_at }) { event in
                            VStack(alignment: .leading) {
                                Text("\(event.event_type) · \(event.provider)")
                                Text("\(event.occurred_at) · \(event.evidence)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if store.snapshots.isEmpty && store.events.isEmpty {
                    ContentUnavailableView("No catalog imported", systemImage: "clock.arrow.circlepath",
                                           description: Text("Open a local DeLorean JSON export to browse offline."))
                }
            }
            .navigationTitle("DeLorean")
            .toolbar {
                Button("Import Catalog", systemImage: "square.and.arrow.down") { importPresented = true }
            }
        } detail: {
            if let checkpoint = selected {
                List {
                    Section("Snapshot Evidence") {
                        LabeledContent("Project", value: checkpoint.project)
                        LabeledContent("Owner", value: checkpoint.owner)
                        LabeledContent("Provider", value: checkpoint.provider)
                        LabeledContent("Reference", value: checkpoint.provider_ref)
                        LabeledContent("Evidence", value: checkpoint.evidence)
                    }
                    Section("Files") {
                        ForEach(checkpoint.files) { f in
                            VStack(alignment: .leading) {
                                Text(f.path)
                                Text("\(f.size) bytes · SHA-256 \(f.sha256.prefix(12))…")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Restore") {
                        Text("Read-only companion. Isolated restore requires the authenticated local DeLorean adapter and explicit destination approval.")
                            .foregroundStyle(.secondary)
                    }
                }.navigationTitle("Snapshot")
            } else {
                ContentUnavailableView("Choose a checkpoint", systemImage: "clock")
            }
        }
        .fileImporter(isPresented: $importPresented, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls): if let url = urls.first { store.importCatalog(from: url) }
            case .failure(let error): store.errorMessage = error.localizedDescription
            }
        }
        .alert("Catalog could not be opened", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }
}

@main
struct DeLoreanCompanionApp: App {
    var body: some Scene {
        WindowGroup { DeLoreanTimelineView() }
    }
}
