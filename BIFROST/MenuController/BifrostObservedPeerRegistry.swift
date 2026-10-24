import Foundation
import AppKit
import Combine

/// Read-only observation of a SMALL, source-recovered set of known launchd
/// service entries. A plist or PID is NOT an owner-approved control adapter,
/// health proof, or authorization to use launchctl start/stop.
struct BifrostObservedPeer: Identifiable {
    enum State: String {
        case configured = "Configured · not loaded"
        case loaded = "Loaded · not running"
        case processObserved = "Process observed · health unverified"
        case changed = "Configuration differs · unverified"
        case unavailable = "Unavailable"
    }
    let id: String
    let name: String
    let owner: String
    let state: State
    let observedAt: Date?
    let controllable = false
}

@MainActor
final class BifrostObservedPeerRegistry: ObservableObject {
    @Published private(set) var peers: [BifrostObservedPeer] = []
    @Published private(set) var observedAt: Date?
    @Published private(set) var feedback = "Peer observations not yet refreshed."

    private struct Known {
        let id: String
        let name: String
        let owner: String
        let expectedScript: String
    }
    // Exact entries recovered from the Mac on 19 Oct; not new ownership.
    // No service is approved for controls by this registry.
    private let known: [Known] = [
        .init(id: "eden.bifrost.raven-bridge", name: "Raven bridge",
              owner: "Online Plugins & Connectors / RavenNest",
              expectedScript: "/Users/lucas/edenOS/Software Development/Online Plugins & Connectors/RavenNest/bifrostctl.py"),
        .init(id: "org.eden.bifrost.core", name: "BIFROSTcore",
              owner: "Existing independent BIFROST core",
              expectedScript: "/Users/lucas/Library/Application Support/EDEN/BIFROST/Core/app.py"),
        .init(id: "org.eden.heimdall.headless", name: "HEIMDALL Headless",
              owner: "HEIMDALL (separate specialist)",
              expectedScript: "/Users/lucas/Library/Application Support/HEIMDALL/App/Headless/server/app.py")
    ]

    var observedRunningCount: Int {
        guard let observedAt, Date().timeIntervalSince(observedAt) <= 45 else { return 0 }
        return peers.filter { $0.state == .processObserved }.count
    }
    var hasFreshObservation: Bool {
        guard let observedAt else { return false }
        let age = Date().timeIntervalSince(observedAt)
        return age >= 0 && age <= 45
    }

    /// One bounded read-only refresh when opening the Menu or explicitly
    /// selecting Refresh. No periodic discovery or Headless auto-start.
    func refresh() {
        let listed = observedLaunchdEntries()
        let moment = Date()
        peers = known.map { entry in
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/LaunchAgents/" + entry.id + ".plist")
            guard FileManager.default.fileExists(atPath: url.path) else {
                return BifrostObservedPeer(id: entry.id, name: entry.name,
                                           owner: entry.owner, state: .unavailable,
                                           observedAt: moment)
            }
            guard let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(
                    from: data, options: [], format: nil
                  ) as? [String: Any],
                  plist["Label"] as? String == entry.id,
                  let arguments = plist["ProgramArguments"] as? [String],
                  arguments.contains(entry.expectedScript) else {
                return BifrostObservedPeer(id: entry.id, name: entry.name,
                                           owner: entry.owner, state: .changed,
                                           observedAt: moment)
            }
            let state: BifrostObservedPeer.State
            if let pid = listed?[entry.id] {
                state = pid > 0 ? .processObserved : .loaded
            } else {
                state = listed == nil ? .unavailable : .configured
            }
            return BifrostObservedPeer(id: entry.id, name: entry.name,
                                       owner: entry.owner, state: state,
                                       observedAt: moment)
        }
        observedAt = moment
        feedback = listed == nil
            ? "launchd could not be inspected. All peer health and controls unverified."
            : "Launchd process state observed. Application health and peer controls NOT verified."
    }

    /// launchctl list only: never bootstrap, bootout, kickstart or modify peers.
    private func observedLaunchdEntries() -> [String: Int]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0,
                  let text = String(data: data, encoding: .utf8) else { return nil }
            var result: [String: Int] = [:]
            for line in text.split(separator: "\n") {
                let fields = line.split(whereSeparator: { $0.isWhitespace })
                guard fields.count == 3,
                      known.contains(where: { $0.id == String(fields[2]) }) else { continue }
                result[String(fields[2])] = Int(fields[0]) ?? 0
            }
            return result
        } catch {
            return nil
        }
    }
}

