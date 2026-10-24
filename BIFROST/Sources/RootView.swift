import SwiftUI

struct RootView: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    private var selection: String { system.selectedSection }

    // Distinct workspaces on the same authoritative state, not feature-list
    // length variants. Simple is task-led, Advanced configures BIFROST,
    // Expert opens inspection and release evidence without extra authority.
    private let simpleWorkspace = [
        "Overview", "Devices", "Accounts & Access", "Install & Setup", "App Management", "Index & Identity", "Headless"
    ]
    private let fullWorkspace = [
        "Overview", "Headless", "Devices", "Accounts & Access", "App Management", "Install & Setup",
        "Index & Identity", "JANITOR", "Connections", "Capabilities",
        "Representations"
    ]
    private var visibleWorkspace: [String] {
        system.complexity == .simple ? simpleWorkspace : fullWorkspace
    }

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { system.selectedSection },
                set: { system.selectedSection = $0 }
            )) {
                HStack(spacing: 12) {
                    BifrostMark(size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BIFROST").font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("CONNECT · KEEP · RESOLVE")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(BifrostUI.muted)
                    }
                }
                .padding(.vertical, 7)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityElement(children: .combine)

                Section("Workspace") {
                    ForEach(visibleWorkspace, id: \.self) { name in
                        sidebarItem(name).tag(name)
                    }
                }
                if system.complexity == .expert {
                    Section("Expert workbench") {
                        sidebarItem("Diagnostics").tag("Diagnostics")
                        sidebarItem("Development & Releases").tag("Development & Releases")
                    }
                } else if system.complexity == .advanced {
                    Section("Management") {
                        sidebarItem("Development & Releases").tag("Development & Releases")
                    }
                }
                Section {
                    sidebarItem("Settings").tag("Settings")
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(BifrostUI.sidebar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 9) {
                    BifrostStatusDot(status: headless.isRunning ? "running" : "offline")
                    VStack(alignment: .leading, spacing: 1) {
                        Text("BIFROST Headless").font(.caption.weight(.medium))
                        Text(headless.isRunning ? "Running" : "Not connected")
                            .font(.caption2).foregroundStyle(BifrostUI.muted)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2).foregroundStyle(BifrostUI.muted)
                }
                .padding(13)
                .background(BifrostUI.elevated.opacity(0.65))
                .accessibilityElement(children: .combine)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 232, max: 275)
        } detail: {
            detail
                .padding(22)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(BifrostUI.canvas)
        }
        // Interface level lives in the integrated Settings destination.
        // Presentation is not an authority or permission control.
        .tint(BifrostUI.apps)
        // Changing disclosure level changes the actual experience.
        // Keep selection valid when deliberately returning to Simple.
        .onChange(of: system.complexity) { _, level in
            if level == .simple && !simpleWorkspace.contains(selection)
                && selection != "Settings" {
                system.selectedSection = "Overview"
            }
        }
        .onAppear { system.consumeShortcutNavigation() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            system.consumeShortcutNavigation()
        }
    }

    private func sidebarItem(_ name: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon(name))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BifrostUI.featureColor(name))
                .frame(width: 23)
            Text(name)
                .font(.system(size: 13, weight: selection == name ? .semibold : .medium))
        }
        .padding(.vertical, 5)
        .accessibilityLabel(name)
    }

    @ViewBuilder private var detail: some View {
        switch selection {
        case "Overview":
            if system.complexity == .simple {
                BifrostSimpleHomeView(navigate: { system.selectedSection = $0 })
            } else {
                BifrostDashboardView(onNavigate: { system.selectedSection = $0 })
            }
        case "Diagnostics":
            BifrostExpertDiagnosticsView()
        case "Headless":
            HeadlessServiceView()
        case "JANITOR":
            JanitorView()
        case "Accounts & Access":
            BifrostAccountJourneyView(onClose: { system.selectedSection = "Overview" })
        case "Install & Setup":
            ScrollView { SetupView() }
        case "Index & Identity":
            KernelView()
        case "Devices":
            DevicesView(discovery: system.discovery, lan: system.lan)
        case "Connections":
            ConnectionsView()
        case "Capabilities":
            CapabilitiesView(capabilities: system.capabilities)
        case "Representations":
            RepresentationsView()
        case "Settings":
            SettingsView()
        default:
            ManagementView(title: selection)
        }
    }

    private func icon(_ name: String) -> String {
        switch name {
        case "Overview": "square.grid.2x2.fill"
        case "Headless": "server.rack"
        case "JANITOR": "paintbrush.pointed.fill"
        case "Accounts & Access": "person.crop.circle.badge.checkmark"
        case "Install & Setup": "shippingbox.fill"
        case "Index & Identity": "point.3.connected.trianglepath.dotted"
        case "Devices": "macbook.and.iphone"
        case "Connections": "point.3.connected.trianglepath.dotted"
        case "Capabilities": "square.stack.3d.up.fill"
        case "Representations": "rectangle.on.rectangle.angled"
        case "App Management": "square.grid.3x3.fill"
        case "Development & Releases": "hammer.fill"
        case "Diagnostics": "waveform.path.ecg.rectangle"
        case "Settings": "gearshape.fill"
        default: "circle"
        }
    }
}
