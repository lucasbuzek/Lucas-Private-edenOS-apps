#if canImport(SwiftUI)
import SwiftUI

/// Embed in the existing BIFROST capability surface, not a new application.
@MainActor public struct ChatGPTCapabilityView: View {
    private let client: any ChatGPTCapabilityClient
    private let thread: String
    @State private var connected = false
    @State private var busy = false
    @State private var prompt = ""
    @State private var reply = ""
    @State private var notice = ""
    @State private var files: [URL] = []
    @State private var pickingFiles = false
    @State private var activeRequest: UUID?
    @State private var rdcNotice = ""

    public init(client: any ChatGPTCapabilityClient, thread: String = UUID().uuidString) {
        self.client = client; self.thread = thread
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ChatGPT").font(.title2)
            if connected {
                ScrollView { Text(reply).textSelection(.enabled) }
                TextField("Ask ChatGPT", text: $prompt)
                if !files.isEmpty { Text(files.map(\.lastPathComponent).joined(separator: ", ")) }
                HStack {
                    Button("Attach files") { pickingFiles = true }.disabled(busy)
                    Button("Send") { send() }.disabled(busy || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Disconnect") { disconnect() }.disabled(busy)
                }
            } else {
                Text("Use your eligible ChatGPT plan. Continue in your browser to authorize access.")
                Button("Continue with ChatGPT") { connect() }.disabled(busy)
            }
            DisclosureGroup("Mac capabilities (optional)") {
                Button("Connect Remote Desktop Commander") { connectRDC() }.disabled(busy)
                if !rdcNotice.isEmpty { Text(rdcNotice).font(.caption) }
            }
            if busy { ProgressView() }
            if !notice.isEmpty { Text(notice).font(.callout) }
        }
        .padding()
        .fileImporter(isPresented: $pickingFiles, allowedContentTypes: [.pdf, .plainText, .json, .commaSeparatedText, .image],
                      allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls): files = Array(urls.prefix(4))
            case .failure: notice = "The selected files could not be opened."
            }
        }
        .task {
            if let result = try? await client.send("status", values: [:], onDelta: { _ in }) {
                connected = result["state"]?.text == "connected"
            }
        }
    }

    private func connect() {
        busy = true; notice = ""
        Task {
            defer { busy = false }
            do {
                let result = try await client.send("connect", values: ["confirmed": .bool(true)], onDelta: { _ in })
                connected = result["state"]?.text == "connected"
                if !connected { notice = "ChatGPT plan access was not granted. Review the official consent options." }
            } catch { notice = "Connection could not finish. Your saved connection is preserved." }
        }
    }

    private func disconnect() {
        busy = true
        Task {
            defer { busy = false }
            do {
                _ = try await client.send("disconnect", values: [:], onDelta: { _ in })
                connected = false; reply = ""; files = []
            } catch { notice = "Sign-out could not finish. Try again." }
        }
    }

    private func connectRDC() {
        busy = true
        Task {
            defer { busy = false }
            do {
                _ = try await client.send("rdc.connect", values: ["confirmed": .bool(true)], onDelta: { _ in })
                rdcNotice = "Connected to the optional provider. Mac access still depends on its device authorization."
            } catch { rdcNotice = "The optional Mac provider could not connect. ChatGPT remains independent." }
        }
    }

    private func send() {
        busy = true; reply = ""; notice = ""
        let selected = files
        let requestID = UUID()
        activeRequest = requestID
        Task {
            // The Python helper cannot inherit sandbox-scoped access from the UI.
            // Stage only explicitly selected files into this app's private temporary directory.
            let staging = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            defer { try? FileManager.default.removeItem(at: staging); activeRequest = nil; busy = false }
            do {
                try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true,
                                                        attributes: [.posixPermissions: 0o700])
                var paths: [WireValue] = []
                for (index, url) in selected.enumerated() {
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    let target = staging.appendingPathComponent("\(index)-\(url.lastPathComponent)")
                    let info = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey])
                    guard info.isRegularFile == true, info.isSymbolicLink != true,
                          (info.fileSize ?? Int.max) <= 10 * 1024 * 1024 else {
                        throw ChatGPTIntegrationError.requestTooLarge
                    }
                    try FileManager.default.copyItem(at: url, to: target)
                    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: target.path)
                    paths.append(.string(target.path))
                }
                let result = try await client.send("chat", values: [
                    "thread": .string(thread), "prompt": .string(prompt),
                    "files": .array(paths), "files_confirmed": .bool(true)
                ], onDelta: { delta in Task { @MainActor in if activeRequest == requestID { reply += delta } } })
                reply = result["text"]?.text ?? reply
                prompt = ""; files = []
            } catch { notice = "The response did not complete. Partial text is shown; retry when ready." }
        }
    }
}
#endif
