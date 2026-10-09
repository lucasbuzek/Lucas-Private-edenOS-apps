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

        MenuBarExtra {
            StatusMenu()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
        } label: {
            HeadlessMenuBarLabel(client: system.headless)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
        }
    }
}

struct HeadlessMenuBarLabel: View {
    @ObservedObject var client: HeadlessClient
    var body: some View {
        HStack(spacing: 4) {
            BifrostMark(size: 20)
            Text(client.menuBarTitle).font(.system(size: 11, weight: .medium))
        }
        .accessibilityLabel("BIFROST, " + client.menuBarTitle)
    }
}

enum Complexity: String, CaseIterable, Identifiable {
    case simple = "Simple", advanced = "Advanced", expert = "Expert"
    var id: String { rawValue }
}
