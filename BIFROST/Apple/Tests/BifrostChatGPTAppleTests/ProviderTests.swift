#if os(macOS)
import Foundation
import XCTest
@testable import BifrostChatGPTApple

private final class Deltas: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String] = []
    func add(_ value: String) { lock.lock(); defer { lock.unlock() }; values.append(value) }
    func read() -> [String] { lock.lock(); defer { lock.unlock() }; return values }
}
final class ProviderTests: XCTestCase {
    func testMissingInstallationIsExplicit() {
        XCTAssertThrowsError(try ChatGPTLocalProvider(executable: URL(fileURLWithPath: "/missing/bifrost-provider")))
    }
    func testActualPrivateIPCStreamingAndMultipleRequests() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let script = directory.appendingPathComponent("provider")
        let source = """
        #!/usr/bin/env python3
        import json, sys
        for line in sys.stdin:
            request = json.loads(line)
            print(json.dumps({"id": request["id"], "delta": "stream"}), flush=True)
            print(json.dumps({"id": request["id"], "result": {"text": "complete"}}), flush=True)
        """
        try source.write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: script.path)
        let provider = try ChatGPTLocalProvider(executable: script)
        let chunks = Deltas()
        for _ in 0..<2 {
            let result = try await provider.send("chat", values: ["prompt": .string("hello")],
                                                 onDelta: { chunks.add($0) })
            XCTAssertEqual(result["text"]?.text, "complete")
        }
        XCTAssertEqual(chunks.read(), ["stream", "stream"])
    }
}
#endif
