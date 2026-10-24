import AppKit
import SwiftUI

@main
struct BifrostAccountRenderSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let name = "eden.bifrost.tests.render." + UUID().uuidString
        let preferences = UserDefaults(suiteName: name)!
        defer { preferences.removePersistentDomain(forName: name) }
        let accounts = BifrostAccountStore(preferences: preferences)
        _ = try accounts.add(provider: .chatgpt, purpose: .personal, label: "Lucas Personal")
        _ = try accounts.add(provider: .claude, purpose: .personal, label: "Lucas Creative")
        _ = try accounts.add(provider: .rdc, purpose: .personal, label: "BifrostBridge1")
        _ = try accounts.add(provider: .rdc, purpose: .personal, label: "BifrostBridge2")
        let host = NSHostingView(rootView: BifrostAccountJourneyView(accounts: accounts)
            .environment(\.colorScheme, .dark)
            .background(BifrostUI.canvas))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 980, height: 760),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.frame = NSRect(x: 0, y: 0, width: 980, height: 760)
        host.layoutSubtreeIfNeeded()
        let deadline = Date().addingTimeInterval(0.5)
        while Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("No bitmap") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("No PNG") }
        try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
        precondition(bitmap.pixelsWide >= 980 && bitmap.pixelsHigh >= 760)
        print("PASS: offscreen native Accounts & Access rendered; isolated fixture identities; no provider page or user window opened")
    }
}
