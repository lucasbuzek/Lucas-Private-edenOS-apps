import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct JANITORApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = Model()

    var body: some Scene {
        WindowGroup("JANITOR") {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(model.appearance.scheme)
                .frame(minWidth: 1000, minHeight: 680)
        }
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
