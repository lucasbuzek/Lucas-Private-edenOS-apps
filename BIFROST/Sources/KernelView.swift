import SwiftUI
import Foundation
import UniformTypeIdentifiers

private struct KernelIndexStatus: Decodable {
    let schema: String
    let state: String
    let sourceCount: Int?
    let objectCount: Int?
    let locationCount: Int?
    let relationshipCount: Int?
    let provenanceCount: Int?
    let scan: String?
}

private struct KernelHit: Decodable, Identifiable {
    let objectId: String
    let classification: String
    let mime: String
    let bytes: Int
    let source: String
    let relative: String
    var id: String { objectId + "|" + source + "|" + relative }
}

private struct KernelSearch: Decodable {
    let state: String
    let matches: [KernelHit]
}

/// DP0.1: explicit local folder selection -> portable kernel CLI -> shared SQLite.
/// BIFROST Headless remains the independent read/API surface.
struct KernelView: View {
    @EnvironmentObject private var headless: HeadlessClient
    @State private var index: KernelIndexStatus?
    @State private var feedback = "Index status not checked"
    @State private var term = ""
    @State private var results: [KernelHit] = []
    @State private var showingPicker = false
    @State private var selectedFolder: URL?
    @State private var loading = false
    @State private var indexing = false

    private let base = URL(string: "http://127.0.0.1:8798")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    BifrostColorIcon("Index & Identity", symbol: "point.3.connected.trianglepath.dotted",
                                     accent: BifrostUI.bridge)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Index & Identity").font(.title2.bold())
                        Text("DP0.1 · Portable metadata and relationships")
                            .font(.caption).foregroundStyle(BifrostUI.muted)
                    }
                    Spacer()
                    Button("Refresh") { Task { await refresh() } }
                        .disabled(loading || indexing)
                    Button("Headless Web") { headless.openWeb() }
                        .disabled(!headless.isRunning)
                }

                BifrostPanel(title: "Persistent BIFROST kernel",
                             symbol: "externaldrive.fill",
                             accent: BifrostUI.bridge) {
                    Text("Content-based identities, file locations, basic metadata, directory relationships, SHA-256 and provenance are preserved in a local SQLite database.")
                        .font(.caption).foregroundStyle(BifrostUI.muted)
                    HStack(spacing: 10) {
                        metric("Sources", count: index?.sourceCount)
                        metric("Objects", count: index?.objectCount)
                        metric("Locations", count: index?.locationCount)
                        metric("Relationships", count: index?.relationshipCount)
                    }
                    Text(index?.state == "INDEX_AVAILABLE" ? "Index available" :
                         (index?.state == "NOT_INDEXED" ? "No source indexed yet" :
                          (index?.state == "INDEX_ERROR" ? "Index needs recovery" : "Status unknown")))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(index?.state == "INDEX_AVAILABLE" ?
                                         BifrostUI.healthy : BifrostUI.warning)
                }
                BifrostPanel(title: "Index an authorized folder",
                             symbol: "folder.badge.plus",
                             accent: BifrostUI.devices) {
                    Text("Choose a folder on this Mac. Indexing is read-only for original files: it hashes at most 250 files, up to 32 MB per file, and skips hidden paths, secrets and symlinks. Metadata is stored locally. Partial scans are reported as partial.")
                        .font(.caption).foregroundStyle(BifrostUI.muted)
                    HStack(spacing: 9) {
                        Button(indexing ? "Indexing…" : "Choose Folder…") {
                            showingPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(indexing)
                        if indexing {
                            ProgressView().controlSize(.small)
                            Text("Processing approved folder")
                                .font(.caption).foregroundStyle(BifrostUI.muted)
                        }
                    }
                    Label("No folder is scanned automatically. Cloud and mobile interfaces cannot trigger this action.",
                          systemImage: "lock.shield")
                        .font(.caption2).foregroundStyle(BifrostUI.muted)
                }

                BifrostPanel(title: "Search indexed representations",
                             symbol: "magnifyingglass",
                             accent: BifrostUI.apps) {
                    HStack(spacing: 9) {
                        TextField("Name or category", text: $term)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { Task { await search() } }
                        Button("Search") { Task { await search() } }
                            .disabled(loading || term.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if results.isEmpty {
                        Text("No search results loaded. Headless provides local-session-controlled read access.")
                            .font(.caption).foregroundStyle(BifrostUI.muted)
                    }
                    ForEach(results) { item in
                        Divider().overlay(BifrostUI.line)
                        HStack(spacing: 8) {
                            Image(systemName: symbol(for: item.classification))
                                .foregroundStyle(BifrostUI.apps)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.relative).font(.subheadline)
                                Text("\(item.classification) · \(item.mime) · \(item.bytes) bytes")
                                    .font(.caption2).foregroundStyle(BifrostUI.muted)
                            }
                            Spacer()
                        }.padding(.vertical, 4)
                    }
                }
                Text(feedback)
                    .font(.caption).foregroundStyle(BifrostUI.muted)
                Text("Evidence boundary: this DP0.1 slice indexes basic filesystem metadata only. Cross-App manifests, richer metadata extractors, provider resolution and remote grants remain future gates.")
                    .font(.caption2).foregroundStyle(BifrostUI.warning)
            }
            .frame(maxWidth: 1020, alignment: .leading)
        }
        .fileImporter(isPresented: $showingPicker, allowedContentTypes: [.folder],
                      allowsMultipleSelection: false) { outcome in
            switch outcome {
            case .success(let files):
                if let first = files.first {
                    selectedFolder = first
                }
            case .failure(let error):
                feedback = "Folder selection failed: \(error.localizedDescription)"
            }
        }
        .confirmationDialog("Index selected folder on this Mac?",
                            isPresented: Binding(
                                get: { selectedFolder != nil },
                                set: { if !$0 { selectedFolder = nil } }
                            ), titleVisibility: .visible) {
            Button("Index selected folder") {
                if let url = selectedFolder {
                    selectedFolder = nil
                    Task { await indexFolder(url) }
                }
            }
            Button("Cancel", role: .cancel) { selectedFolder = nil }
        } message: {
            Text("Reads and hashes up to 250 selected-folder files of 32 MB each; skips hidden and sensitive paths, and never alters originals. SQLite metadata stays on this Mac.")
        }
        .task { await refresh() }
    }

    private func metric(_ name: String, count: Int?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name).font(.caption2).foregroundStyle(BifrostUI.muted)
            Text(count.map(String.init) ?? "—")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(BifrostUI.elevated, in: RoundedRectangle(cornerRadius: 8))
    }

    private func symbol(for classification: String) -> String {
        switch classification {
        case "image": "photo"
        case "audio": "waveform"
        case "video": "film"
        case "document": "doc.text"
        case "source": "chevron.left.forwardslash.chevron.right"
        case "directory": "folder"
        default: "doc"
        }
    }

    @MainActor private func refresh() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let (data, response) = try await URLSession.shared.data(
                from: base.appendingPathComponent("api/kernel/status"))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            index = try decoder.decode(KernelIndexStatus.self, from: data)
            feedback = index?.state == "INDEX_AVAILABLE" ?
                "Index ready. Native and Headless read the same local SQLite store." :
                "No index yet. Choose a folder to build one; no automatic scans."
        } catch {
            index = nil
            feedback = "Headless index unavailable: \(error.localizedDescription)"
        }
    }

    @MainActor private func search() async {
        let value = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !loading, !value.isEmpty else { return }
        loading = true
        defer { loading = false }
        do {
            let (sessionData, _) = try await URLSession.shared.data(
                from: base.appendingPathComponent("api/session"))
            guard let dict = try JSONSerialization.jsonObject(with: sessionData)
                as? [String: Any], let token = dict["token"] as? String else {
                throw URLError(.userAuthenticationRequired)
            }
            var components = URLComponents(url: base.appendingPathComponent("api/kernel/search"),
                                           resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "q", value: value),
                                     URLQueryItem(name: "limit", value: "40")]
            var request = URLRequest(url: components.url!)
            request.setValue(token, forHTTPHeaderField: "X-Bifrost-Token")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.userAuthenticationRequired)
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let answer = try decoder.decode(KernelSearch.self, from: data)
            results = answer.matches
            feedback = "\(results.count) matching indexed locations"
        } catch {
            results = []
            feedback = "Search unavailable: \(error.localizedDescription)"
        }
    }

    @MainActor private func indexFolder(_ url: URL) async {
        guard !indexing else { return }
        guard let script = Bundle.main.resourceURL?
                .appendingPathComponent("core/portable_kernel.py"),
              FileManager.default.fileExists(atPath: script.path) else {
            feedback = "The portable kernel is not included in this App candidate."
            return
        }
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        indexing = true
        feedback = "Indexing user-selected folder. Originals remain unchanged."
        let database = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BIFROST/kernel/index.sqlite")
        let path = url.path
        let scriptPath = script.path
        let dbPath = database.path
        let outcome = await Task.detached(priority: .utility) { () -> (Int32, String) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [
                "-B", scriptPath, "--db", dbPath,
                "scan", path, "--max-files", "250",
                "--max-bytes", "33554432", "--max-total-bytes", "268435456",
                "--max-depth", "8"
            ]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = output
            process.standardInput = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
                let text = String(data: output.fileHandleForReading.readDataToEndOfFile(),
                                  encoding: .utf8) ?? ""
                return (process.terminationStatus, text)
            } catch {
                return (-1, error.localizedDescription)
            }
        }.value
        indexing = false
        await refresh()
        if outcome.0 == 0 {
            feedback = "Read-only indexing completed. Persistent locations are available in search."
        } else if outcome.0 == 2 {
            feedback = "Partial index; scan limits or unreadable files were reached. No originals changed."
        } else {
            feedback = "Index failed: " + String(outcome.1.prefix(320))
        }
    }
}
