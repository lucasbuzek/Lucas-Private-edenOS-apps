import SwiftUI

@main
struct BIFROSTApp: App {
    @StateObject private var system = BifrostSystem()

    var body: some Scene {
        WindowGroup("BIFROST", id: "main") {
            RootView().environmentObject(system)
        }
        .defaultSize(width: 1180, height: 760)

        MenuBarExtra("BIFROST", systemImage: "point.3.connected.trianglepath.dotted") {
            StatusMenu().environmentObject(system)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environmentObject(system)
        }
    }
}

enum Complexity: String, CaseIterable, Identifiable {
    case simple = "Simple", advanced = "Advanced", expert = "Expert"
    var id: String { rawValue }
}
