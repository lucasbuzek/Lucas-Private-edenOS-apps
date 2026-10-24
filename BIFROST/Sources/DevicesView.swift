import SwiftUI

/// Native first: nearby Bonjour advertisements and explicitly requested,
/// bounded local IPv4 probes. No control/pairing/remote login is implied.
struct DevicesView: View {
    @EnvironmentObject private var system: BifrostSystem
    @ObservedObject var discovery: DiscoveryService
    @ObservedObject var lan: LANDiscoveryAdapter
    @State private var targetIP = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                BifrostHeader(title: "Devices & Local Network",
                              subtitle: "Discover first. Identify and authorize before connecting.")
                HStack(spacing: 10) {
                    metric("Bonjour", "\(discovery.services.count) services", "dot.radiowaves.left.and.right", .devices)
                    metric("LAN", "\(lan.hosts.count) observed", "network", .connections)
                    metric("Adapters", "\(lan.interfaces.count) local", "cable.connector", .capabilities)
                }

                BifrostPanel(title: "Local interfaces & network scan",
                             symbol: "network", accent: BifrostUI.devices) {
                    VStack(alignment: .leading, spacing: 10) {
                        if lan.interfaces.isEmpty {
                            ContentUnavailableView("No private IPv4 LAN",
                                systemImage: "wifi.slash",
                                description: Text("Connect to Wi-Fi or Ethernet. Public WAN and VPN tunnel scanning is not permitted."))
                        } else {
                            Picker("Network adapter", selection: $lan.selectedID) {
                                ForEach(lan.interfaces) { adapter in
                                    Text(adapter.rangeLabel).tag(adapter.id)
                                }
                            }
                            .disabled(lan.scanning)
                            Text("This Mac: \(lan.selected?.address ?? "Unavailable"). Scan is restricted to the selected private subnet (up to 254 addresses).")
                                .font(.caption).foregroundStyle(BifrostUI.muted)
                            HStack(spacing: 10) {
                                if lan.scanning {
                                    Button("Stop Scan") { lan.stop() }
                                        .tint(BifrostUI.warning)
                                    ProgressView(value: Double(lan.scanned),
                                                 total: Double(max(lan.total, 1)))
                                        .frame(maxWidth: 170)
                                    Text("\(lan.scanned)/\(lan.total)")
                                        .font(.caption.monospacedDigit())
                                } else {
                                    Button {
                                        lan.scan()
                                    } label: {
                                        Label("Scan Local Network", systemImage: "dot.radiowaves.left.and.right")
                                    }
                                    .tint(BifrostUI.devices)
                                }
                                Button("Refresh Adapters") { lan.refreshInterfaces() }
                                    .disabled(lan.scanning)
                            }
                            HStack {
                                TextField("Ping IPv4 address on selected LAN", text: $targetIP)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 320)
                                    .onSubmit { lan.ping(targetIP.trimmingCharacters(in: .whitespaces)) }
                                Button("Ping Host") { lan.ping(targetIP.trimmingCharacters(in: .whitespaces)) }
                                    .disabled(lan.scanning || !(lan.selected?.addresses.contains(
                                        targetIP.trimmingCharacters(in: .whitespaces)) ?? false))
                            }
                            Text(lan.status)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        Text("ICMP silence does not mean a host is offline. Cached ARP neighbors are historical observations. No scan automatically pairs, authenticates or controls a device.")
                            .font(.caption2).foregroundStyle(BifrostUI.muted)
                    }
                }

                BifrostPanel(title: "Observed LAN neighbors",
                             symbol: "desktopcomputer", accent: BifrostUI.devices) {
                    if lan.hosts.isEmpty {
                        Label("No scan results. Select Scan Local Network to inspect this adapter.",
                              systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(lan.hosts) { peer in
                            HStack(spacing: 11) {
                                BifrostFeatureIcon(symbol: peer.evidence == "ICMP response" ?
                                                   "checkmark.circle" : "clock.arrow.circlepath", feature: .devices)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(peer.address).font(.headline.monospacedDigit())
                                    Text(peer.evidence + " · " + peer.message)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 10)
                                Text("Untrusted").font(.caption)
                                    .foregroundStyle(BifrostUI.warning)
                            }
                            .padding(.vertical, 3)
                            Divider()
                        }
                    }
                }

                BifrostPanel(title: "Bonjour · local service advertisements",
                             symbol: "bonjour", accent: BifrostUI.bridge) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(discovery.status).font(.callout)
                            Text("Services are not unique device identities.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 10)
                        Button("Refresh Bonjour") { discovery.refresh() }
                    }
                    if !discovery.problems.isEmpty {
                        Text("Local Network permission may require approval in System Settings → Privacy & Security → Local Network.")
                            .font(.caption).foregroundStyle(BifrostUI.warning)
                        if system.complexity != .simple {
                            ForEach(discovery.problems, id: \.self) { issue in
                                Text(issue).font(.caption2.monospaced()).textSelection(.enabled)
                            }
                        }
                    }
                    if discovery.services.isEmpty {
                        Text("No advertised services observed. Some devices do not advertise Bonjour; try Scan Local Network. Check permission and Wi-Fi client isolation.")
                            .font(.callout).foregroundStyle(.secondary)
                    } else {
                        ForEach(discovery.services) { service in
                            HStack(spacing: 11) {
                                BifrostFeatureIcon(symbol: "network", feature: .representation)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(service.name).font(.headline)
                                    Text(service.type + " · " + service.domain)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 10)
                                Text("Observed").font(.caption)
                                    .foregroundStyle(BifrostUI.bridge)
                            }
                            .padding(.vertical, 3)
                            Divider()
                        }
                    }
                }
            }
            .frame(maxWidth: 1050, alignment: .leading)
        }
    }

    private func metric(_ title: String, _ value: String, _ symbol: String,
                        _ feature: BifrostFeature) -> some View {
        HStack(spacing: 8) {
            BifrostFeatureIcon(symbol: symbol, feature: feature)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.callout.weight(.semibold))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(BifrostUI.panel, in: RoundedRectangle(cornerRadius: 12))
    }
}
