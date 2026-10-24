import Foundation

/// Device discovery is not pairing. This adapter never runs a network scan
/// until the user requests it; it never tries passwords or opens services.
@MainActor final class LANDiscoveryAdapter: ObservableObject {
    @Published private(set) var interfaces: [LANInterface] = []
    @Published var selectedID = ""
    @Published private(set) var hosts: [LANHostObservation] = []
    @Published private(set) var status = "Select an interface to scan"
    @Published private(set) var scanned = 0
    @Published private(set) var total = 0
    @Published private(set) var scanning = false
    private var task: Task<Void, Never>?
    private var epoch = 0

    var selected: LANInterface? {
        interfaces.first { $0.id == selectedID }
    }

    init() { refreshInterfaces() }

    func refreshInterfaces() {
        let previous = selectedID
        interfaces = LANProbe.interfaces()
        selectedID = interfaces.contains { $0.id == previous }
            ? previous : (interfaces.first?.id ?? "")
        if interfaces.isEmpty {
            status = "No active private IPv4 LAN adapter found. Connect to Wi-Fi or Ethernet."
        } else if !scanning {
            status = "Ready · select Scan to probe this local subnet. No scans run automatically."
        }
    }

    func stop() {
        epoch += 1
        task?.cancel()
        task = nil
        if scanning { status = "Scan cancelled · observed results retained." }
        scanning = false
    }

    func scan() {
        guard !scanning, let adapter = selected else {
            status = "Select an active local interface first."
            return
        }
        epoch += 1
        let currentEpoch = epoch
        hosts.removeAll()
        scanned = 0
        total = adapter.addresses.count
        scanning = true
        status = "Scanning \(adapter.rangeLabel) · ICMP only, max 8 concurrent probes"
        let addresses = adapter.addresses
        task = Task {
            let cached = await Task.detached(priority: .utility) {
                LANProbe.arpCached(on: adapter)
            }.value
            guard !Task.isCancelled, epoch == currentEpoch else { return }
            for ip in cached {
                hosts.append(.init(address: ip, evidence: "ARP cache",
                                   message: "Previously observed · availability unknown"))
            }
            await withTaskGroup(of: (String, Bool).self) { group in
                var iterator = addresses.makeIterator()
                for _ in 0..<min(8, addresses.count) {
                    if let ip = iterator.next() {
                        group.addTask { (ip, LANProbe.ping(ip)) }
                    }
                }
                while let (ip, responds) = await group.next() {
                    if Task.isCancelled || currentEpoch != epoch {
                        group.cancelAll()
                        break
                    }
                    scanned += 1
                    if responds {
                        hosts.removeAll { $0.address == ip }
                        hosts.append(.init(address: ip, evidence: "ICMP response",
                                           message: "Responded to ping · not paired or trusted"))
                        hosts.sort { $0.address.localizedStandardCompare($1.address) == .orderedAscending }
                    }
                    status = "Scanned \(scanned)/\(total) · \(hosts.filter { $0.evidence == "ICMP response" }.count) responding · \(hosts.filter { $0.evidence == "ARP cache" }.count) cached"
                    if let next = iterator.next() {
                        group.addTask { (next, LANProbe.ping(next)) }
                    }
                }
            }
            guard currentEpoch == epoch else { return }
            scanning = false
            task = nil
            status = "Completed \(scanned)/\(total). Nonresponders may still be online. Bonjour and ARP may detect additional peers."
        }
    }

    /// User-triggered single-target ping, restricted to selected private LAN.
    func ping(_ address: String) {
        guard !scanning, let adapter = selected,
              adapter.addresses.contains(address) else {
            status = "Address must be on the selected local private subnet (excluding this Mac)."
            return
        }
        epoch += 1
        let currentEpoch = epoch
        status = "Pinging \(address)…"
        task = Task {
            let responded = await Task.detached(priority: .utility) {
                LANProbe.ping(address)
            }.value
            guard currentEpoch == epoch else { return }
            if responded {
                hosts.removeAll { $0.address == address }
                hosts.append(.init(address: address, evidence: "ICMP response",
                                   message: "Responded to ping · not paired or trusted"))
                hosts.sort { $0.address.localizedStandardCompare($1.address) == .orderedAscending }
            }
            status = responded ? "\(address) responded to ICMP; device identity remains unverified."
                : "No ICMP response from \(address). This does not prove it is offline."
            task = nil
        }
    }
}
