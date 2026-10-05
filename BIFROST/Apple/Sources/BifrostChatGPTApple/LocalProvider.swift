#if os(macOS)
import Foundation
import Darwin

/// One instance belongs to BIFROST Core. No TCP listener or remote authorization.
public final class ChatGPTLocalProvider: ChatGPTCapabilityClient, @unchecked Sendable {
    private var process: Process
    private var input: FileHandle
    private var output: FileHandle
    private let executable: URL
    private let requestTimeout: TimeInterval
    private var invalidated = false
    private let queue = DispatchQueue(label: "app.eden.bifrost.chatgpt.ipc")
    private var buffered = Data()

    public init(executable: URL, requestTimeout: TimeInterval = 360) throws {
        guard requestTimeout.isFinite, requestTimeout > 0, requestTimeout <= 3600 else {
            throw ChatGPTIntegrationError.invalidResponse
        }
        self.executable = executable
        self.requestTimeout = requestTimeout
        let worker = try Self.launch(executable)
        process = worker.0; input = worker.1; output = worker.2
    }

    private static func launch(_ executable: URL) throws -> (Process, FileHandle, FileHandle) {
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw ChatGPTIntegrationError.providerNotInstalled
        }
        let process = Process(), stdin = Pipe(), stdout = Pipe()
        process.executableURL = executable
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice
        let descriptor = stdin.fileHandleForWriting.fileDescriptor
        let flags = Darwin.fcntl(descriptor, F_GETFL)
        guard flags >= 0, Darwin.fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) >= 0,
              Darwin.fcntl(descriptor, F_SETNOSIGPIPE, 1) >= 0 else {
            throw ChatGPTIntegrationError.providerStopped
        }
        try process.run()
        return (process, stdin.fileHandleForWriting, stdout.fileHandleForReading)
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

    private func invalidate() {
        invalidated = true
        // Kill only this owned helper, including a suspended child. Do not replay
        // the interrupted request: tool operations may already have had effects.
        if process.isRunning { _ = Darwin.kill(process.processIdentifier, SIGKILL) }
    }

    private func transact(_ operation: String, values: [String: WireValue],
                          onDelta: @escaping @Sendable (String) -> Void) throws -> WireValue {
        if invalidated || !process.isRunning {
            try? input.close(); try? output.close()
            let worker = try Self.launch(executable)
            process = worker.0; input = worker.1; output = worker.2
            invalidated = false; buffered.removeAll()
        }
        let deadline = DispatchTime.now().uptimeNanoseconds + UInt64(requestTimeout * 1_000_000_000)
        let id = UUID().uuidString
        var payload = values
        payload["op"] = .string(operation)
        payload["id"] = .string(id)
        var data = try JSONEncoder().encode(WireValue.object(payload))
        guard data.count < 1024 * 1024 else { throw ChatGPTIntegrationError.requestTooLarge }
        data.append(10)
        var offset = 0
        while offset < data.count {
            try waitFor(input.fileDescriptor, events: Int16(POLLOUT), deadline: deadline)
            let count = data.withUnsafeBytes { bytes in
                Darwin.write(input.fileDescriptor, bytes.baseAddress!.advanced(by: offset),
                             min(data.count - offset, 4096))
            }
            if count < 0 && (errno == EINTR || errno == EAGAIN) { continue }
            guard count > 0 else { invalidate(); throw ChatGPTIntegrationError.providerStopped }
            offset += count
        }
        while true {
            let line = try readLine(deadline: deadline)
            let event = try JSONDecoder().decode(WireValue.self, from: line)
            if let error = event["error"]?.text { throw ChatGPTIntegrationError.providerFailure(error) }
            guard event["id"]?.text == id else { invalidate(); throw ChatGPTIntegrationError.invalidResponse }
            if let delta = event["delta"]?.text { onDelta(delta); continue }
            if let result = event["result"] { return result }
            invalidate(); throw ChatGPTIntegrationError.invalidResponse
        }
    }

    private func waitFor(_ fd: Int32, events: Int16, deadline: UInt64) throws {
        while true {
            let now = DispatchTime.now().uptimeNanoseconds
            guard now < deadline else { invalidate(); throw ChatGPTIntegrationError.providerTimedOut }
            var descriptor = pollfd(fd: fd, events: events, revents: 0)
            let timeout = Int32(min((deadline - now) / 1_000_000 + 1, UInt64(Int32.max)))
            let ready = Darwin.poll(&descriptor, 1, timeout)
            if ready < 0 && errno == EINTR { continue }
            if ready == 0 { invalidate(); throw ChatGPTIntegrationError.providerTimedOut }
            guard ready > 0 else { invalidate(); throw ChatGPTIntegrationError.providerStopped }
            return
        }
    }

    private func readLine(deadline: UInt64) throws -> Data {
        while true {
            let now = DispatchTime.now().uptimeNanoseconds
            guard now < deadline else { invalidate(); throw ChatGPTIntegrationError.providerTimedOut }
            if let end = buffered.firstIndex(of: 10) {
                guard end <= 16 * 1024 * 1024 else { invalidate(); throw ChatGPTIntegrationError.invalidResponse }
                let line = buffered.prefix(upTo: end)
                buffered.removeSubrange(...end)
                return Data(line)
            }
            guard buffered.count <= 16 * 1024 * 1024 else {
                invalidate(); throw ChatGPTIntegrationError.invalidResponse
            }
            try waitFor(output.fileDescriptor, events: Int16(POLLIN), deadline: deadline)
            // Single bounded pipe read returns available bytes, without waiting
            // for a full buffer while the child waits for our next request.
            var bytes = [UInt8](repeating: 0, count: 4096)
            let count = Darwin.read(output.fileDescriptor, &bytes, bytes.count)
            if count < 0 && errno == EINTR { continue }
            guard count > 0 else { invalidate(); throw ChatGPTIntegrationError.providerStopped }
            buffered.append(contentsOf: bytes.prefix(count))
        }
    }
}
#endif
