import Foundation
import XCTest
@testable import BifrostChatGPTApple
final class WireTests: XCTestCase {
    func testRequestRoundTrip() throws {
        let value = WireValue.object(["op": .string("connect"), "confirmed": .bool(true),
                                      "files": .array([]), "unused": .null])
        XCTAssertEqual(try JSONDecoder().decode(WireValue.self, from: JSONEncoder().encode(value)), value)
    }
    func testDeltaEnvelope() throws {
        let data = Data(#"{"id":"request","delta":"Hello"}"#.utf8)
        let event = try JSONDecoder().decode(WireValue.self, from: data)
        XCTAssertEqual(event["delta"]?.text, "Hello")
    }
    func testFailureEnvelope() throws {
        let data = Data(#"{"id":"request","error":"sign_in_required"}"#.utf8)
        let event = try JSONDecoder().decode(WireValue.self, from: data)
        XCTAssertEqual(event["error"]?.text, "sign_in_required")
    }
}
