import Foundation
import Network

struct NearbyService: Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let domain: String
}

/// Passive, Apple-native Bonjour service advertisements: NOT unique device
/// identities and NOT evidence of authorization/pairing or reachability.
@MainActor final class DiscoveryService: ObservableObject {
    // Explicitly declared in BIFROST's NSBonjourServices privacy metadata.
    static let serviceTypes = [
        "_airplay._tcp", "_raop._tcp", "_companion-link._tcp",
        "_ssh._tcp", "_smb._tcp", "_afpovertcp._tcp",
        "_device-info._tcp", "_workstation._tcp", "_http._tcp",
        "_https._tcp", "_ipp._tcp", "_ipps._tcp",
        "_printer._tcp", "_hap._tcp", "_googlecast._tcp",
        "_rfb._tcp", "_adisk._tcp"
    ]

    @Published private(set) var services: [NearbyService] = []
    @Published private(set) var status = "Not started"
    @Published private(set) var activeTypes = 0
    @Published private(set) var problems: [String] = []

    private var browsers: [String: NWBrowser] = [:]
    private var observations: [String: Set<NWBrowser.Result>] = [:]
    private var stateByType: [String: String] = [:]
    private var generation = 0

    func start() {
        guard browsers.isEmpty else { return }
        generation += 1
        let epoch = generation
        status = "Preparing native Bonjour discovery…"
        for type in Self.serviceTypes {
            let browser = NWBrowser(
                for: .bonjour(type: type, domain: nil),
                using: .tcp
            )
            browser.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self, self.generation == epoch else { return }
                    switch state {
                    case .ready: self.stateByType[type] = "ready"
                    case .waiting(let error): self.stateByType[type] = "waiting: \(error)"
                    case .failed(let error): self.stateByType[type] = "failed: \(error)"
                    case .setup: self.stateByType[type] = "setup"
                    case .cancelled: self.stateByType.removeValue(forKey: type)
                    @unknown default: self.stateByType[type] = "unknown"
                    }
                    self.updateStatus()
                }
            }
            browser.browseResultsChangedHandler = { [weak self] results, _ in
                Task { @MainActor in
                    guard let self, self.generation == epoch else { return }
                    self.observations[type] = results
                    self.rebuildServices()
                }
            }
            browsers[type] = browser
            browser.start(queue: .global(qos: .utility))
        }
    }

    func refresh() {
        generation += 1
        for (_, browser) in browsers { browser.cancel() }
        browsers.removeAll()
        observations.removeAll()
        stateByType.removeAll()
        services.removeAll()
        activeTypes = 0
        problems.removeAll()
        status = "Restarting Bonjour discovery…"
        start()
    }

    private func rebuildServices() {
        var found: [String: NearbyService] = [:]
        for (_, results) in observations {
            for result in results {
                if case let .service(name, type, domain, _) = result.endpoint {
                    let id = "\(name)|\(type)|\(domain)"
                    found[id] = NearbyService(id: id, name: name,
                                               type: type, domain: domain)
                }
            }
        }
        services = found.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        updateStatus()
    }

    private func updateStatus() {
        activeTypes = stateByType.values.filter { $0 == "ready" }.count
        problems = stateByType.filter {
            $0.value.hasPrefix("failed:") || $0.value.hasPrefix("waiting:")
        }.map { "\($0.key): \($0.value)" }.sorted()
        let summary = "Bonjour: \(activeTypes)/\(Self.serviceTypes.count) service types browsing · \(services.count) advertisements"
        status = problems.isEmpty ? summary :
            summary + " · \(problems.count) waiting/failed (check Local Network permission)"
    }
}
