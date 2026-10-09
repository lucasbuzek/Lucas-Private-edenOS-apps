import Foundation
import AppKit

@MainActor final class BifrostSystem: ObservableObject {
    @Published var complexity: Complexity = .simple
    @Published var lastMessage = "Ready"
    let headless = HeadlessClient()
    let discovery = DiscoveryService()
    let remote = RemoteDesktopProvider()
    let janitor = JanitorProvider()
    let capabilities = CapabilityRegistry()
    let apps = AppRegistry()

    init() {
        discovery.start()
        refresh()
    }

    func refresh() {
        remote.refresh()
        janitor.refresh()
        capabilities.refresh(remote: remote)
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
