import Foundation
import Combine

struct BifrostAccountConnectorObservation: Sendable {
    let observedAt: Date
    let runtimeVerified: Bool
    let rdcProfileIDs: [String]
    let taskDispatch: String
}

enum BifrostConnectorProbeError: LocalizedError {
    case unavailable, invalidResponse, failed
    var errorDescription: String? {
        switch self {
        case .unavailable: "The existing BIFROST connector is unavailable at its established location."
        case .invalidResponse: "Connector response could not be verified. No connection was accepted."
        case .failed: "Connector check failed or timed out. Existing accounts and services were unchanged."
        }
    }
}

/// Thin MCP client for the EXISTING connector. No new server, daemon, credential
/// access, host registration, provider login or duplicated inventory implementation.
@MainActor
final class BifrostAccountConnectorProbe: ObservableObject {
    @Published private(set) var running = false
    @Published private(set) var observation: BifrostAccountConnectorObservation?
    @Published private(set) var feedback = ""

    func inspect() {
        guard !running else { return }
        running = true
        observation = nil // stale evidence must not survive a failed refresh
        feedback = "Checking the existing local BIFROST connector…"
        let home = FileManager.default.homeDirectoryForCurrentUser
        Task {
            do {
                let value = try await Task.detached {
                    try Self.readExistingConnector(home: home)
                }.value
                observation = value
                feedback = "Local connector responded. Provider authentication and remote device access remain unverified."
            } catch { feedback = error.localizedDescription }
            running = false
        }
    }

    nonisolated static func readExistingConnector(home: URL) throws -> BifrostAccountConnectorObservation {
        let folder = home.appendingPathComponent("edenOS/Software Development/Online Plugins & Connectors/EDEN-BIFROST-Connector")
        let server = folder.appendingPathComponent("server.py")
        let manifest = folder.appendingPathComponent("manifest.json")
        for file in [server, manifest] {
            let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard values?.isRegularFile == true, values?.isSymbolicLink == false,
                  let size = values?.fileSize, size <= 65536 else { throw BifrostConnectorProbeError.unavailable }
        }
        guard let meta = try JSONSerialization.jsonObject(with: Data(contentsOf: manifest)) as? [String: Any],
              meta["id"] as? String == "eden.bifrost.connector",
              meta["kind"] as? String == "mcp-stdio",
              meta["entrypoint"] as? String == "server.py",
              let permissions = meta["permissions"] as? [String: Any],
              permissions["writes"] as? Bool == false,
              permissions["credentialAccess"] as? Bool == false,
              permissions["serviceActivation"] as? Bool == false else { throw BifrostConnectorProbeError.unavailable }
        let messages: [[String: Any]] = [
            ["jsonrpc": "2.0", "id": 1, "method": "initialize", "params": [:]],
            ["jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": ["name": "bifrost_bridge_overview", "arguments": [:]]],
            ["jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": ["name": "bifrost_provider_inventory", "arguments": [:]]]
        ]
        var input = Data()
        for message in messages {
            input.append(try JSONSerialization.data(withJSONObject: message))
            input.append(10)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-E", "-B", server.path]
        process.currentDirectoryURL = folder
        process.environment = ["HOME": home.path, "PATH": "/usr/bin:/bin",
                               "PYTHONDONTWRITEBYTECODE": "1",
                               "EDENOS_ROOT": home.appendingPathComponent("edenOS").path]
        let source = Pipe(), output = Pipe()
        process.standardInput = source
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        // Only the exact child process object can be stopped, never a name/PID scan.
        DispatchQueue.global().asyncAfter(deadline: .now() + 8) {
            if process.isRunning { process.terminate() }
        }
        source.fileHandleForWriting.write(input)
        try source.fileHandleForWriting.close()
        var bytes = Data()
        while true {
            let chunk = try output.fileHandleForReading.read(upToCount: 8192) ?? Data()
            if chunk.isEmpty { break }
            bytes.append(chunk)
            if bytes.count > 131072 {
                if process.isRunning { process.terminate() }
                throw BifrostConnectorProbeError.invalidResponse
            }
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw BifrostConnectorProbeError.failed }
        return try decode(bytes)
    }

    nonisolated static func decode(_ bytes: Data) throws -> BifrostAccountConnectorObservation {
        guard bytes.count <= 131072 else { throw BifrostConnectorProbeError.invalidResponse }
        var replies = [Int: [String: Any]]()
        for line in bytes.split(separator: 10) {
            guard let reply = try JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
                  reply["jsonrpc"] as? String == "2.0", let id = reply["id"] as? Int,
                  replies[id] == nil, let result = reply["result"] as? [String: Any],
                  result["isError"] as? Bool != true else { throw BifrostConnectorProbeError.invalidResponse }
            replies[id] = result
        }
        guard Set(replies.keys) == Set([1, 2, 3]),
              let info = replies[1]?["serverInfo"] as? [String: Any],
              info["name"] as? String == "eden-bifrost-connector" else { throw BifrostConnectorProbeError.invalidResponse }
        func content(_ id: Int) throws -> [String: Any] {
            guard let list = replies[id]?["content"] as? [[String: Any]], list.count == 1,
                  let text = list[0]["text"] as? String, let data = text.data(using: .utf8),
                  let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw BifrostConnectorProbeError.invalidResponse }
            return value
        }
        let overview = try content(2), inventory = try content(3)
        guard overview["schema"] as? String == "eden.bifrost.bridge.reconciliation.v1",
              inventory["schema"] as? String == "eden.bifrost.zero.provider-inventory.v1",
              let headless = overview["headless"] as? [String: Any],
              let bridge = overview["bridge"] as? [String: Any],
              let manager = inventory["rdcManager"] as? [String: Any],
              let profiles = manager["profiles"] as? [[String: Any]], profiles.count <= 100 else { throw BifrostConnectorProbeError.invalidResponse }
        let ids = try profiles.map { item -> String in
            guard let id = item["id"] as? String,
                  id.range(of: "^[A-Za-z][A-Za-z0-9_-]{0,39}$", options: .regularExpression) != nil else { throw BifrostConnectorProbeError.invalidResponse }
            return id
        }
        return BifrostAccountConnectorObservation(observedAt: Date(),
            runtimeVerified: headless["identityVerified"] as? Bool == true,
            rdcProfileIDs: ids,
            taskDispatch: bridge["authenticatedTaskDispatch"] as? String ?? "UNKNOWN")
    }
}
