import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var system: BifrostSystem
    @EnvironmentObject var raven: RavenAgentController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(title: "Connections", subtitle: "Live providers and controls.")
            GroupBox("RavenNest · Optional Mac bridge") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(raven.localSummary).font(.headline)
                            Text("Cloudflare orchestration operates independently of this Mac.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if raven.isRunning || raven.autoStartDisabled != true {
                            Button("Stop Mac Bridge") { raven.stop() }
                                .disabled(raven.isBusy)
                        } else {
                            Button("Start Mac Bridge…") { raven.requestStart() }
                                .disabled(raven.isBusy || raven.autoStartDisabled != true)
                        }
                        Button("Refresh") { raven.refresh() }
                    }
                    Text(raven.autoStartDisabled == true ?
                         "Automatic startup and crash restart are disabled." :
                         "Automatic startup needs review.")
                        .font(.caption).foregroundStyle(.secondary)
                    if !raven.feedback.isEmpty {
                        Text(raven.feedback).font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(10)
            }
            GroupBox("Remote Desktop Commander") {
                HStack {
                    VStack(alignment: .leading) {
                        Text(system.remote.state.rawValue).font(.headline)
                        Text(system.remote.detail).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Start") { system.remote.start(); system.refresh() }
                        .disabled(system.remote.state == .running)
                    Button("Stop") { system.remote.stop(); system.refresh() }
                        .disabled(system.remote.state != .running)
                }.padding(10)
            }
        }.frame(maxWidth: 960, alignment: .leading)
    }
}

struct CapabilitiesView: View {
    @EnvironmentObject var system: BifrostSystem
    @ObservedObject var capabilities: CapabilityRegistry

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(title: "Capabilities", subtitle: "Real capabilities and providers visible to this Mac.")
            HStack {
                Text("\(capabilities.items.filter { $0.available }.count) available")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") { system.refresh() }
            }
            List(capabilities.items) { capability in
                HStack {
                    BifrostFeatureIcon(symbol: capability.available ? "checkmark.circle.fill" : "circle.dashed", feature: .capabilities, size: 15)
                    VStack(alignment: .leading) {
                        Text(capability.name).font(.headline)
                        Text("\(capability.provider) · \(capability.kind.rawValue) · \(capability.detail)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(capability.available ? "Available" : "Unavailable")
                        .foregroundStyle(.secondary)
                }
            }
            GroupBox("Shortcuts") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(capabilities.shortcutsStatus)
                        .font(.caption).foregroundStyle(.secondary)
                    if !capabilities.shortcuts.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], alignment: .leading) {
                                ForEach(capabilities.shortcuts, id: \.self) {
                                    Label($0, systemImage: "command")
                                }
                            }
                        }
                    }
                }.padding(8)
            }
        }.frame(maxWidth: 960, alignment: .leading)
    }
}

struct RepresentationsView: View {
    @EnvironmentObject var system: BifrostSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(title: "Representations", subtitle: "Observed endpoints are evidence, not automatically trusted identities.")
            ForEach(Dictionary(grouping: system.discovery.services, by: { $0.name }).keys.sorted(), id: \.self) { name in
                let services = system.discovery.services.filter { $0.name == name }
                GroupBox { nameRow(name, services) }
            }
        }.frame(maxWidth: 960, alignment: .leading)
    }

    private func nameRow(_ name: String, _ services: [NearbyService]) -> some View {
        HStack {
            BifrostFeatureIcon(symbol: "network", feature: .representation, size: 18)
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(services.map { $0.type }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("Observed").foregroundStyle(.secondary)
        }.padding(6)
    }
}

struct ManagementView: View {
    let title: String
    @EnvironmentObject var system: BifrostSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(
                title: title,
                subtitle: title == "App Management"
                    ? "Installed EDEN apps remain independent capability owners."
                    : "Build and release governance is supporting BIFROST functionality."
            )
            if title == "App Management" {
                HStack {
                    Text("Registered applications").font(.headline)
                    Spacer()
                    Button("Refresh") { system.refresh() }
                }
                List(system.apps.apps) { app in
                    HStack {
                        BifrostFeatureIcon(symbol: app.installed ? "square.grid.2x2.fill" : "square.dashed", feature: .apps, size: 15)
                        VStack(alignment: .leading) {
                            Text(app.name).font(.headline)
                            Text(app.path ?? "Not registered on this Mac")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if app.installed { Button("Open") { system.apps.open(app) } }
                    }
                }
            } else {
                GroupBox("Current project") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("BIFROST", systemImage: "hammer")
                        Text("Canonical workspace: ~/edenOS/Projects/BIFROST")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Release actions appear only when backed by actual build evidence.")
                            .font(.caption)
                    }
                }
            }
        }.frame(maxWidth: 960, alignment: .leading)
    }
}

struct SettingsView: View {
    @EnvironmentObject var system: BifrostSystem
    @EnvironmentObject var headless: HeadlessClient
    @EnvironmentObject var raven: RavenAgentController

    var body: some View {
        Form {
            Section("Interface") {
                Picker("Interface complexity", selection: $system.complexity) {
                    ForEach(Complexity.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            Section("Menu Bar indicators") {
                Toggle("Headless", isOn: Binding(
                    get: { headless.preferences.statusIndicators.contains("headless") },
                    set: { headless.setHeadlessIndicator($0) }
                ))
                Toggle("Active tasks", isOn: Binding(
                    get: { headless.preferences.statusIndicators.contains("activeTasks") },
                    set: { headless.setTasksIndicator($0) }
                ))
            }
            Section("Headless and Web dashboard") {
                LabeledContent("Headless", value: headless.stateMessage)
                HStack {
                    if headless.isRunning {
                        Button("Stop Headless") { headless.stop() }
                        Button("Open Web Dashboard") { headless.openWeb() }
                    } else {
                        Button("Start Headless") { headless.start() }
                    }
                    Button("Refresh") { headless.refresh() }
                }
                LabeledContent("RavenNest Mac bridge", value: raven.localSummary)
            }
            Section("RavenNest · Manual Mac connection") {
                LabeledContent("Local service", value: raven.localSummary)
                LabeledContent("Automatic startup",
                               value: raven.autoStartDisabled == true ? "Disabled" : "Unverified / enabled")
                Text("Cloudflare RavenNest runs independently. The local agent starts only when explicitly confirmed.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    if raven.isRunning || raven.autoStartDisabled != true {
                        Button("Stop RavenNest on Mac") { raven.stop() }
                    } else {
                        Button("Start RavenNest on Mac…") { raven.requestStart() }
                            .disabled(raven.autoStartDisabled != true)
                    }
                    Button("Refresh") { raven.refresh() }
                }.disabled(raven.isBusy)
                if !raven.feedback.isEmpty {
                    Text(raven.feedback).font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Caffeinate") {
                Picker("Default duration", selection: Binding(
                    get: { headless.preferences.caffeinateMinutes },
                    set: { headless.setCaffeinateMinutes($0) }
                )) {
                    Text("30 minutes").tag(30)
                    Text("60 minutes").tag(60)
                    Text("120 minutes").tag(120)
                    Text("Until stopped").tag(0)
                }
                Toggle("Prevent Mac sleep", isOn: Binding(
                    get: { headless.caffeinateActive },
                    set: { $0 ? headless.startCaffeinate() : headless.stopCaffeinate() }
                )).disabled(!headless.isRunning)
            }
            Section("AI routing") {
                Picker("Routing preference", selection: Binding(
                    get: { headless.preferences.aiRouting },
                    set: { headless.setAIMode($0) }
                )) {
                    Text("Automatic").tag("auto")
                    Text("Choose provider").tag("manual")
                    Text("Prefer local/offline").tag("local")
                }
                Text("Provider adapters are not yet connected to this Headless runtime.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Legacy native capabilities") {
                LabeledContent("Remote bridge", value: system.remote.state.rawValue)
                LabeledContent("Discovered services", value: "\(system.discovery.services.count)")
                LabeledContent("Available capabilities", value: "\(system.capabilities.items.filter { $0.available }.count)")
            }
            if !headless.feedback.isEmpty {
                Text(headless.feedback).font(.caption).foregroundStyle(.secondary)
            }
        }.padding().frame(minWidth: 550, minHeight: 560)
    }
}
