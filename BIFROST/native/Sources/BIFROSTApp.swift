import SwiftUI

@main
struct BIFROSTApp: App {
    @StateObject private var system = BifrostSystem()

    var body: some Scene {
        WindowGroup("BIFROST", id: "main") {
            RootView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
        }
        .defaultSize(width: 1180, height: 760)

        // A real macOS menu-bar item: the system draws a high-contrast,
        // always identifiable title and SF Symbol in light and dark menus.
        // Headless remains an independent launchd service when this GUI quits.
        MenuBarExtra("BIFROST", systemImage: "network") {
            StatusMenu()
                .environmentObject(system)
                .environmentObject(system.headless)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
        }
    }
}

enum Complexity: String, CaseIterable, Identifiable {
    case simple = "Simple", advanced = "Advanced", expert = "Expert"
    var id: String { rawValue }
}
