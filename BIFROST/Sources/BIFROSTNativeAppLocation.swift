import Foundation
import AppKit

/// Shared, explicit native-app selection for the menu controller and the
/// full BIFROST app. Headless reads the same private record, never an API
/// caller-supplied path. This avoids LaunchServices choosing stale releases.
enum BIFROSTNativeAppLocation {
    static let nativeBundleID = "eden.private.bifrost"

    private struct Record: Codable {
        let schema: String
        let bundleIdentifier: String
        let path: String
    }

    private static var support: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BIFROST", isDirectory: true)
    }
    private static var record: URL {
        support.appendingPathComponent("native-app.json")
    }

    static func validated(_ url: URL) -> URL? {
        let fm = FileManager.default
        let standardized = url.standardizedFileURL
        guard standardized.pathExtension.lowercased() == "app",
              standardized.isFileURL,
              (try? standardized.resourceValues(forKeys: [.isSymbolicLinkKey]))?
                .isSymbolicLink != true else { return nil }
        let resolved = standardized.resolvingSymlinksInPath()
        guard fm.fileExists(atPath: resolved.path),
              let bundle = Bundle(url: resolved),
              bundle.bundleIdentifier == nativeBundleID else {
            return nil
        }
        return resolved
    }

    static func approved() -> URL? {
        guard let data = try? Data(contentsOf: record),
              let stored = try? JSONDecoder().decode(Record.self, from: data),
              stored.schema == "bifrost.native-app.v1",
              stored.bundleIdentifier == nativeBundleID else { return nil }
        return validated(URL(fileURLWithPath: stored.path))
    }

    /// User action only. Never invoked automatically when the app launches.
    static func approve(_ chosen: URL) throws -> URL {
        guard let bundle = validated(chosen) else {
            throw NSError(domain: "BIFROST", code: 20, userInfo: [
                NSLocalizedDescriptionKey: "Selected file is not a valid BIFROST native app."
            ])
        }
        let fm = FileManager.default
        try fm.createDirectory(at: support, withIntermediateDirectories: true)
        try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: support.path)
        let next = Record(schema: "bifrost.native-app.v1",
                          bundleIdentifier: nativeBundleID,
                          path: bundle.path)
        try JSONEncoder().encode(next).write(to: record, options: .atomic)
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: record.path)
        return bundle
    }
}
