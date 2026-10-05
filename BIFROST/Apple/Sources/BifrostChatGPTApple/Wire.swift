import Foundation

public enum ChatGPTIntegrationError: Error {
    case providerNotInstalled, providerStopped, invalidResponse, requestTooLarge
    case providerFailure(String), authorizedRouteUnavailable
}

public enum WireValue: Codable, Equatable, Sendable {
    case string(String), bool(Bool), number(Double), array([WireValue]), object([String: WireValue]), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode([WireValue].self) { self = .array(v) }
        else { self = .object(try c.decode([String: WireValue].self)) }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
    public subscript(key: String) -> WireValue? {
        guard case .object(let values) = self else { return nil }
        return values[key]
    }
    public var text: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }
}

public protocol ChatGPTCapabilityClient: Sendable {
    func send(_ operation: String, values: [String: WireValue],
              onDelta: @escaping @Sendable (String) -> Void) async throws -> WireValue
}
