import SwiftUI

/// The complete native BIFROST interface. Its process and windows are
/// independent from both BIFROST Menu and BIFROST Headless.
/// The dedicated BIFROSTMenu target owns the one authoritative status item.
@main
struct BIFROSTApp: App {
    @StateObject private var system = BifrostSystem()
    @StateObject private var permissions = BifrostPermissionCenter()

    var body: some Scene {
        WindowGroup("BIFROST", id: "main") {
            RootView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
                .environmentObject(permissions)
        }
        .defaultSize(width: 1180, height: 760)

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
                .environmentObject(permissions)
        }
    }
}

enum Complexity: String, CaseIterable, Identifiable {
    case simple = "Simple", advanced = "Advanced", expert = "Expert"
    var id: String { rawValue }
}
