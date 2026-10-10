import Foundation
import Network

struct NearbyService: Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let domain: String
}

@MainActor final class DiscoveryService: ObservableObject {
    @Published private(set) var services: [NearbyService] = []
    private var browsers: [NWBrowser] = []

    func start() {
        guard browsers.isEmpty else { return }
        for type in ["_airplay._tcp", "_raop._tcp", "_companion-link._tcp", "_ssh._tcp"] {
            let descriptor = NWBrowser.Descriptor.bonjour(type: type, domain: nil)
            let browser = NWBrowser(for: descriptor, using: .tcp)
            browser.browseResultsChangedHandler = { [weak self] results, _ in
                Task { @MainActor in self?.merge(results, type: type) }
            }
            browser.start(queue: .global(qos: .utility))
            browsers.append(browser)
        }
    }

    private func merge(_ results: Set<NWBrowser.Result>, type: String) {
        services.removeAll { $0.type == type }
        for result in results {
            if case let .service(name, serviceType, domain, _) = result.endpoint {
                services.append(.init(id: "\(name)|\(serviceType)|\(domain)", name: name, type: serviceType, domain: domain))
            }
        }
        services.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
