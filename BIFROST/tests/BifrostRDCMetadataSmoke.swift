import Foundation

/// Exercised against synthetic RDC metadata under a temporary test home.
@main
struct RDCMetadataSmoke {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let fm = FileManager.default
        let provider = root.appendingPathComponent(
            "edenOS/Software Development/Online Plugins & Connectors/RDC5/rdc5.py")
        let index = root.appendingPathComponent(".config/rdc5/identities.json")
        try fm.createDirectory(at: provider.deletingLastPathComponent(),
                               withIntermediateDirectories: true)
        try fm.createDirectory(at: index.deletingLastPathComponent(),
                               withIntermediateDirectories: true)
        try Data("existing".utf8).write(to: provider)
        let fixture: [String: Any] = [
            "schema": 2, "active": "RDC6",
            "profiles": [
                "RDC5": ["home": "/do-not-expose", "token": "test-secret"],
                "RDC6": ["home": "/another-private-path", "session": "hidden"]
            ]
        ]
        try JSONSerialization.data(withJSONObject: fixture).write(to: index)
        let observed = BifrostRDCManagerSnapshot.read(home: root)
        precondition(observed.available)
        precondition(observed.profiles.map(\.id) == ["RDC5", "RDC6"])
        precondition(observed.profiles.first(where: { $0.id == "RDC6" })?.selected == true)
        precondition(!observed.status.contains("secret"))
        precondition(!observed.profiles.map(\.id).joined().contains("private"))

        try Data("{\"schema\":1}".utf8).write(to: index, options: .atomic)
        let invalid = BifrostRDCManagerSnapshot.read(home: root)
        precondition(invalid.profiles.isEmpty)
        try fm.removeItem(at: index)
        try fm.createSymbolicLink(at: index, withDestinationURL: provider)
        let unsafe = BifrostRDCManagerSnapshot.read(home: root)
        precondition(unsafe.profiles.isEmpty)
        try fm.removeItem(at: provider)
        precondition(!BifrostRDCManagerSnapshot.read(home: root).available)
        print("PASS: RDC read-only identity labels; malformed/symlink refused; credentials not returned")
    }
}
