import SwiftUI

struct RootView: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    private var selection: String { system.selectedSection }

    private let primary = [
        "Overview", "Devices", "App Management", "Install & Setup", "Index & Identity", "JANITOR",
        "Connections", "Capabilities", "Representations"
    ]
    private let management = ["Development & Releases"]

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
                    ForEach(primary, id: \.self) { name in
                        sidebarItem(name).tag(name)
                    }
                }
                if system.complexity != .simple {
                    Section("Management") {
                        ForEach(management, id: \.self) { name in
                            sidebarItem(name).tag(name)
                        }
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
        .toolbar {
            ToolbarItem {
                Picker("Interface level", selection: $system.complexity) {
                    ForEach(Complexity.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 242)
            }
        }
        .tint(BifrostUI.apps)
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
            BifrostDashboardView(onNavigate: { system.selectedSection = $0 })
        case "JANITOR":
            JanitorView()
        case "Install & Setup":
            SetupView()
        case "Index & Identity":
            KernelView()
        case "Devices":
            DevicesView()
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
        case "JANITOR": "paintbrush.pointed.fill"
        case "Install & Setup": "shippingbox.fill"
        case "Index & Identity": "point.3.connected.trianglepath.dotted"
        case "Devices": "macbook.and.iphone"
        case "Connections": "point.3.connected.trianglepath.dotted"
        case "Capabilities": "square.stack.3d.up.fill"
        case "Representations": "rectangle.on.rectangle.angled"
        case "App Management": "square.grid.3x3.fill"
        case "Development & Releases": "hammer.fill"
        case "Settings": "gearshape.fill"
        default: "circle"
        }
    }
}
