import XCTest
import Foundation
@testable import DropboxLiteCore

final class PlacesReadOnlyTests: XCTestCase {
    func testReadOnlyNonRecursiveCommandUsesSelectedRemote() throws {
        XCTAssertEqual(try PlacesReadOnly.invocation(remote: "dropboxlite", path: "Research/Books").arguments,
                       ["lsjson", "dropboxlite:Research/Books", "--max-depth", "1"])
        XCTAssertEqual(try PlacesReadOnly.invocation(remote: "drive", path: "").arguments,
                       ["lsjson", "drive:", "--max-depth", "1"])
    }
    func testMalformedRemoteAndTraversalAreRejectedBeforeExecute() {
        var invoked = false
        for (remote, path) in [("../other", ""), ("remote", "../secret"),
                               ("remote", "/absolute"), ("remote", "a//b"),
                               ("remote", "x\\secret"), ("remote:foo", "ok")] {
            XCTAssertThrowsError(try PlacesReadOnly.inspect(source: .managed, remote: remote, path: path) { _ in
                invoked = true; return Data("[]".utf8)
            })
        }
        XCTAssertFalse(invoked)
    }
    func testProviderScopedMetadataDoesNotDownloadAnything() throws {
        var arguments: [[String]] = []
        let fixture = #"[{"Name":"papers","IsDir":true,"Size":0},{"Name":"CV.pdf","IsDir":false,"Size":2342}]"#
        let result = try PlacesReadOnly.inspect(source: .managed, remote: "dbx", path: "Private") { request in
            arguments.append(request.arguments)
            return Data(fixture.utf8)
        }
        XCTAssertEqual(result.accountKey, "managed|dbx")
        XCTAssertEqual(result.entries.map(\.name), ["papers", "CV.pdf"])
        XCTAssertEqual(result.entries[0].path, "Private/papers")
        XCTAssertNil(result.entries[0].size)
        XCTAssertEqual(result.entries[1].size, 2342)
        XCTAssertEqual(arguments.count, 1)
        XCTAssertEqual(arguments[0], ["lsjson", "dbx:Private", "--max-depth", "1"])
        XCTAssertFalse(arguments[0].contains(where: { ["copyto", "sync", "move", "--recursive", "--files-only"].contains($0) }))
    }
    func testSeparateSourceRemoteKeysCannotCollide() throws {
        let output = Data("[]".utf8)
        let a = try PlacesReadOnly.inspect(source: .system, remote: "same", path: "") { _ in output }
        let b = try PlacesReadOnly.inspect(source: .managed, remote: "same", path: "") { _ in output }
        XCTAssertNotEqual(a.accountKey, b.accountKey)
    }
    func testUnsafeEntriesFailClosed() {
        for name in ["..", "../outside", "dir/file", "bad:colon", ".dropboxlite-secret"] {
            let json = "[{\"Name\":\"\(name)\",\"IsDir\":false}]"
            XCTAssertThrowsError(try PlacesReadOnly.inspect(source: .managed, remote: "x", path: "") { _ in Data(json.utf8) })
        }
        let link = #"[{"Name":"symlink","IsDir":false,"IsLink":true}]"#
        XCTAssertThrowsError(try PlacesReadOnly.inspect(source: .managed, remote: "x", path: "") { _ in Data(link.utf8) })
        let bad = #"[{"Name":"negative","IsDir":false,"Size":-1}]"#
        XCTAssertThrowsError(try PlacesReadOnly.inspect(source: .managed, remote: "x", path: "") { _ in Data(bad.utf8) })
    }
    func testOversizedPreviewFailsClosed() {
        let huge = Data(repeating: 0x20, count: 2_000_001)
        XCTAssertThrowsError(try PlacesReadOnly.inspect(source: .managed, remote: "x", path: "") { _ in huge })
        let tooMany = "[" + Array(repeating: #"{"Name":"x","IsDir":false}"#, count: 1001).joined(separator: ",") + "]"
        XCTAssertThrowsError(try PlacesReadOnly.inspect(source: .managed, remote: "x", path: "") { _ in Data(tooMany.utf8) })
    }
}
