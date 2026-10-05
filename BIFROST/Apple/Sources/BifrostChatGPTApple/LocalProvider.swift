#if os(macOS)
import Foundation
import Darwin

/// One instance belongs to BIFROST Core. No TCP listener or remote authorization.
public final class ChatGPTLocalProvider: ChatGPTCapabilityClient, @unchecked Sendable {
    private let process: Process
    private let input: FileHandle
    private let output: FileHandle
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "app.eden.bifrost.chatgpt.ipc")
    private var buffered = Data()

    public init(executable: URL) throws {
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw ChatGPTIntegrationError.providerNotInstalled
        }
        process = Process()
        let stdin = Pipe(), stdout = Pipe()
        process.executableURL = executable
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice
        input = stdin.fileHandleForWriting
        output = stdout.fileHandleForReading
        try process.run()
    }

    deinit {
        try? input.close()
        if process.isRunning { process.terminate() }
        try? output.close()
    }

    public func send(_ operation: String, values: [String: WireValue],
                     onDelta: @escaping @Sendable (String) -> Void = { _ in }) async throws -> WireValue {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                do { continuation.resume(returning: try transact(operation, values: values, onDelta: onDelta)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func transact(_ operation: String, values: [String: WireValue],
                          onDelta: @escaping @Sendable (String) -> Void) throws -> WireValue {
        lock.lock()
        defer { lock.unlock() }
        guard process.isRunning else { throw ChatGPTIntegrationError.providerStopped }
        let id = UUID().uuidString
        var payload = values
        payload["op"] = .string(operation)
        payload["id"] = .string(id)
        var data = try JSONEncoder().encode(WireValue.object(payload))
        guard data.count < 1024 * 1024 else { throw ChatGPTIntegrationError.requestTooLarge }
        data.append(10)
        try input.write(contentsOf: data)
        while true {
            let line = try readLine()
            let event = try JSONDecoder().decode(WireValue.self, from: line)
            if let error = event["error"]?.text { throw ChatGPTIntegrationError.providerFailure(error) }
            guard event["id"]?.text == id else { throw ChatGPTIntegrationError.invalidResponse }
            if let delta = event["delta"]?.text { onDelta(delta); continue }
            if let result = event["result"] { return result }
            throw ChatGPTIntegrationError.invalidResponse
        }
    }

    private func readLine() throws -> Data {
        while true {
            if let end = buffered.firstIndex(of: 10) {
                let line = buffered.prefix(upTo: end)
                buffered.removeSubrange(...end)
                return Data(line)
            }
            guard buffered.count <= 16 * 1024 * 1024 else {
                throw ChatGPTIntegrationError.invalidResponse
            }
            // A single POSIX pipe read returns available bytes. FileHandle's
            // count-based read may wait to fill its count while the child waits
            // for our next request, deadlocking short JSON-line responses.
            var bytes = [UInt8](repeating: 0, count: 4096)
            let count = Darwin.read(output.fileDescriptor, &bytes, bytes.count)
            if count < 0 && errno == EINTR { continue }
            guard count > 0 else { throw ChatGPTIntegrationError.providerStopped }
            buffered.append(contentsOf: bytes.prefix(count))
        }
    }
}
#endif
