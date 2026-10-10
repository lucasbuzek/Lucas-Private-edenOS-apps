import SwiftUI

@main
struct BIFROSTApp: App {
    @StateObject private var system = BifrostSystem()
    @StateObject private var raven = RavenAgentController()

    var body: some Scene {
        WindowGroup("BIFROST", id: "main") {
            RootView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
                .environmentObject(raven)
        }
        .defaultSize(width: 1180, height: 760)

        // Native NSMenu presentation, with the recovered spectral bridge mark
        // rather than a generic network icon. No dark custom popover.
        // Headless remains an independent launchd service if the GUI quits.
        MenuBarExtra {
            StatusMenu()
                .environmentObject(system)
                .environmentObject(system.headless)
                .environmentObject(raven)
        } label: {
            HStack(spacing: 4) {
                BifrostBridgeSymbol(width: 24, height: 18)
                Text("BIFROST")
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: raven.isRunning ? "circle.fill" : "circle")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(raven.isRunning ? Color.green : Color.secondary)
            }
            .accessibilityLabel("BIFROST menu · RavenNest Mac bridge " + (raven.isRunning ? "running" : "stopped"))
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
                .environmentObject(raven)
        }
    }
}

enum Complexity: String, CaseIterable, Identifiable {
    case simple = "Simple", advanced = "Advanced", expert = "Expert"
    var id: String { rawValue }
}
