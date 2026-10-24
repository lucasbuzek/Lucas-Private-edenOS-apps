import AppKit
import WebKit
import Foundation

@main
struct BifrostAccountBrowserSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let fixtureURL = URL(fileURLWithPath: CommandLine.arguments[1])
        // Stable, test-only fixture IDs avoid creating new stores every run.
        // No provider page, cookies, account metadata or credentials are loaded.
        let ids: [UUID]
        if FileManager.default.fileExists(atPath: fixtureURL.path) {
            ids = try JSONDecoder().decode([UUID].self, from: Data(contentsOf: fixtureURL))
            precondition(ids.count == 2 && ids[0] != ids[1])
        } else {
            ids = [UUID(), UUID()]
            try JSONEncoder().encode(ids).write(to: fixtureURL, options: .atomic)
        }
        let first = BifrostAccountIdentity(id: ids[0], provider: .chatgpt, purpose: .personal,
                                          label: "Isolated fixture one", createdAt: Date())
        let second = BifrostAccountIdentity(id: ids[1], provider: .chatgpt, purpose: .personal,
                                           label: "Isolated fixture two", createdAt: Date())
        let a = BifrostAccountBrowserSession(identity: first)
        let b = BifrostAccountBrowserSession(identity: second)
        precondition(a.webView.configuration.websiteDataStore.identifier == first.id)
        precondition(b.webView.configuration.websiteDataStore.identifier == second.id)
        precondition(a.webView.configuration.websiteDataStore.identifier != b.webView.configuration.websiteDataStore.identifier)
        precondition(a.webView.configuration.websiteDataStore.isPersistent)
        let restored = BifrostAccountBrowserSession(identity: first)
        precondition(restored.webView.configuration.websiteDataStore.identifier == first.id)
        let selector = NSSelectorFromString("webView:decidePolicyForNavigationAction:decisionHandler:")
        precondition(a.responds(to: selector), "Policy delegate is not registered")
        // The real delegate must reject this top-level navigation BEFORE any
        // request reaches the network. A fake allowlist-only test is insufficient.
        a.webView.load(URLRequest(url: URL(string: "https://bifrost-test.invalid/")!))
        let deadline = Date().addingTimeInterval(8)
        while a.message.isEmpty && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        precondition(a.message.contains("Navigation blocked"), "WebKit did not reject an unknown destination")
        a.stop(); b.stop(); restored.stop()
        print("PASS: actual WebKit identity isolation, persistent UUID reuse, registered navigation delegate and real rejection. Two credential-free fixture stores retained; deletion API is not used by the product.")
    }
}
