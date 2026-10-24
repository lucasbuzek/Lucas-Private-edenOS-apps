import Foundation
import AppKit

@MainActor final class BifrostSystem: ObservableObject {
    @Published var complexity: Complexity = .simple {
        didSet {
            UserDefaults.standard.set(complexity.rawValue,
                                      forKey: "bifrost.interface.complexity")
        }
    }
    @Published var lastMessage = "Ready"
    /// Shared selection permits real menu-bar quick links to native views.
    @Published var selectedSection = "Overview"
    let headless = HeadlessClient()
    let discovery = DiscoveryService()
    let lan = LANDiscoveryAdapter()
    let janitor = JanitorProvider()
    let capabilities = CapabilityRegistry()
    let apps = AppRegistry()

    init() {
        if let saved = UserDefaults.standard.string(forKey: "bifrost.interface.complexity"),
           let level = Complexity(rawValue: saved) {
            complexity = level
        }
        discovery.start()
        consumeShortcutNavigation()
        refresh()
    }

    func consumeShortcutNavigation() {
        if let requested = BifrostIntentRoute.consume() {
            selectedSection = requested
        }
    }

    func refresh() {
        janitor.refresh()
        capabilities.refresh()
        apps.refresh()
        headless.refresh()
    }

    // Compatibility with the existing OverviewView control.
    // Headless, not SwiftUI, owns the caffeinate process.
    var keepAwake: Bool { headless.caffeinateActive }

    func setKeepAwake(_ enabled: Bool) {
        if enabled {
            headless.startCaffeinate()
        } else {
            headless.stopCaffeinate()
        }
    }
}
