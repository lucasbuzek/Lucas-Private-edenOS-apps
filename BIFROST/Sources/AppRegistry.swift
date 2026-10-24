import Foundation
import AppKit

/// Installed application information is read from local macOS application
/// bundles. This is evidence of an on-disk app, not verified automation,
/// registration with Shortcuts, a working plugin, or an available update.
struct EdenAppRecord: Identifiable, Sendable {
    let id: String
    let name: String
    let installed: Bool
    let path: String?
    let bundleID: String?
    let version: String?
    let origin: String
    let shortcutsState: String

    static func missing(_ name: String, bundleID: String) -> Self {
        .init(id: bundleID, name: name, installed: false, path: nil,
              bundleID: bundleID, version: nil, origin: "EDEN candidate",
              shortcutsState: "Not verified")
    }
}

/// Avoid app launching, executable inspection, broad filesystem traversal,
/// private user folders and package updates during discovery. On-disk metadata
/// alone does not confer permission to control another application.
enum BifrostInstalledAppScanner {
    static func inventory(home: URL) -> [EdenAppRecord] {
        let fm = FileManager.default
        let roots: [(URL, String)] = [
            (URL(fileURLWithPath: "/Applications"), "Applications"),
            (URL(fileURLWithPath: "/Applications/Utilities"), "Utilities"),
            (URL(fileURLWithPath: "/System/Applications"), "Apple system"),
            (URL(fileURLWithPath: "/System/Applications/Utilities"), "Apple utilities"),
            (home.appendingPathComponent("Applications", isDirectory: true), "User Applications")
        ]
        var found: [EdenAppRecord] = []
        var seenPaths = Set<String>()
        for (folder, origin) in roots {
            guard let entries = try? fm.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for url in entries where url.pathExtension.lowercased() == "app" {
                let resolved = url.resolvingSymlinksInPath()
                guard seenPaths.insert(resolved.path).inserted else { continue }

                // EDEN automation is explicitly prohibited from operating
                // Google Chrome. Do not read its bundle, profile or metadata.
                if url.lastPathComponent.caseInsensitiveCompare("Google Chrome.app") == .orderedSame {
                    found.append(.init(
                        id: "restricted.chrome", name: "Google Chrome",
                        installed: true, path: nil, bundleID: nil, version: nil,
                        origin: "Restricted · excluded from BIFROST control",
                        shortcutsState: "Disabled by policy"
                    ))
                    continue
                }

                guard let bundle = Bundle(url: resolved),
                      let executable = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String,
                      !executable.isEmpty else { continue }
                let identifier = bundle.bundleIdentifier
                let title = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? resolved.deletingPathExtension().lastPathComponent
                let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                found.append(.init(
                    id: "app.\(resolved.path)",
                    name: title, installed: true, path: resolved.path,
                    bundleID: identifier, version: version,
                    origin: origin, shortcutsState: "Not verified"
                ))
            }
        }
        // Some macOS system/Cryptex applications are available at registered
        // paths but absent from ordinary directory listings (notably Safari).
        // Read these exact built-in locations without crawling system trees.
        for (path, origin) in [
            ("/Applications/Safari.app", "Apple system · Cryptex"),
            ("/System/Library/CoreServices/Finder.app", "Apple system · CoreServices")
        ] {
            let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
            guard let bundle = Bundle(url: url),
                  let executable = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String,
                  !executable.isEmpty, seenPaths.insert(url.path).inserted else { continue }
            found.append(.init(
                id: "app.\(url.path)",
                name: (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent,
                installed: true, path: url.path,
                bundleID: bundle.bundleIdentifier,
                version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                origin: origin, shortcutsState: "Not verified"
            ))
        }
        return found.sorted {
            let comparison = $0.name.localizedStandardCompare($1.name)
            return comparison == .orderedSame ? $0.id < $1.id : comparison == .orderedAscending
        }
    }
}

@MainActor final class AppRegistry: ObservableObject {
    @Published private(set) var apps: [EdenAppRecord] = []
    @Published private(set) var lastOpenMessage = ""
    @Published private(set) var scanStatus = "Not scanned"
    @Published private(set) var refreshing = false
    private var generation = 0

    func refresh() {
        generation += 1
        let current = generation
        refreshing = true
        scanStatus = "Inspecting installed application metadata…"
        let home = FileManager.default.homeDirectoryForCurrentUser
        Task {
            let discovered = await Task.detached(priority: .utility) {
                BifrostInstalledAppScanner.inventory(home: home)
            }.value
            guard current == generation else { return }
            // EDEN products with canonical source but no installed bundle are
            // candidates, not evidence that a usable app is installed.
            let known = [
                ("JANITOR", "eden.private.janitor"),
                ("LINGUA", "eden.private.lingua"),
                ("LECTOR", "eden.private.lector"),
                ("HEIMDALL", "eden.private.heimdall"),
                ("PENELOPE", "com.lucasbuzek.penelope")
            ]
            var all = discovered
            for (name, identifier) in known
                where !all.contains(where: { $0.bundleID == identifier }) {
                all.append(.missing(name, bundleID: identifier))
            }
            apps = all.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            refreshing = false
            scanStatus = "\(discovered.count) on-disk apps inventoried; compatibility and automation are not assumed."
        }
    }

    func open(_ app: EdenAppRecord) {
        guard let path = app.path, app.installed,
              FileManager.default.fileExists(atPath: path),
              let bundle = Bundle(path: path),
              let executable = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String,
              !executable.isEmpty else {
            lastOpenMessage = "No approved application launch path. Refresh the inventory."
            return
        }
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: path),
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            Task { @MainActor in
                if let error {
                    self.lastOpenMessage = "Could not open \(app.name): \(error.localizedDescription)"
                } else {
                    self.lastOpenMessage = "macOS accepted the request to open \(app.name)."
                }
            }
        }
    }
}
