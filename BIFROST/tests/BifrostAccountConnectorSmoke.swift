import Foundation

@main
struct BifrostAccountConnectorSmoke {
    static func main() throws {
        for invalid in [Data(), Data("{}\n".utf8), Data("{\"jsonrpc\":\"2.0\",\"id\":1,\"error\":{}}\n".utf8), Data(repeating: 32, count: 131073)] {
            do {
                _ = try BifrostAccountConnectorProbe.decode(invalid)
                fatalError("Invalid connector response accepted")
            } catch {}
        }
        let missing = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        do {
            _ = try BifrostAccountConnectorProbe.readExistingConnector(home: missing)
            fatalError("Missing connector accepted")
        } catch BifrostConnectorProbeError.unavailable {}
        let result = try BifrostAccountConnectorProbe.readExistingConnector(home: FileManager.default.homeDirectoryForCurrentUser)
        precondition(result.taskDispatch == "NOT_IMPLEMENTED_BY_THIS_TOOL")
        print("PASS: existing live BIFROST connector responded over MCP stdio; runtime identity verified=\(result.runtimeVerified); local RDC profile count=\(result.rdcProfileIDs.count); read-only dispatch limitation retained; invalid/missing responses rejected")
    }
}
