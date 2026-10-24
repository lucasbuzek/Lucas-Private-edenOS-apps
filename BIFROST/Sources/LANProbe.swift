import Foundation
import Darwin

struct LANInterface: Identifiable, Hashable, Sendable {
    let name: String
    let address: String
    let netmask: String
    let prefix: Int
    let addresses: [String]
    var id: String { "\(name)|\(address)" }
    var rangeLabel: String { "\(address)/\(prefix) · \(name)" }
}

struct LANHostObservation: Identifiable, Hashable, Sendable {
    let address: String
    let evidence: String
    let message: String
    var id: String { address }
}

/// Read-only interface and ARP queries, plus one ICMP echo per explicitly
/// selected host. Only one private IPv4 /24 maximum; no WAN, VPN or shell.
enum LANProbe {
    static func uint32(_ ip: String) -> UInt32? {
        let parts = ip.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }
        var result: UInt32 = 0
        for item in parts {
            guard !item.isEmpty, item.count <= 3,
                  item.allSatisfy({ $0 >= "0" && $0 <= "9" }),
                  let n = UInt32(item), n <= 255 else { return nil }
            result = (result << 8) | n
        }
        return result
    }

    static func dotted(_ a: UInt32) -> String {
        "\((a >> 24) & 255).\((a >> 16) & 255).\((a >> 8) & 255).\(a & 255)"
    }

    static func privateIPv4(_ a: UInt32) -> Bool {
        let one = a >> 24, two = (a >> 16) & 255
        return one == 10 || (one == 172 && (16...31).contains(two)) ||
            (one == 192 && two == 168) || (one == 169 && two == 254)
    }

    static func candidates(address: String, mask: String) -> [String] {
        guard let ip = uint32(address), let subnet = uint32(mask),
              subnet != 0, privateIPv4(ip) else { return [] }
        let invert = ~subnet
        guard (invert &+ 1) & invert == 0 else { return [] }
        let effective = max(subnet, 0xFFFFFF00)
        let low = ip & effective, high = low | ~effective
        guard high > low + 1 else { return [] }
        return ((low + 1)..<high).filter { $0 != ip }.prefix(254).map(dotted)
    }

    static func interfaces() -> [LANInterface] {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return [] }
        defer { freeifaddrs(first) }
        var found: [LANInterface] = []
        var next: UnsafeMutablePointer<ifaddrs>? = first
        while let pointer = next {
            let item = pointer.pointee
            defer { next = item.ifa_next }
            guard let ip = item.ifa_addr, let mask = item.ifa_netmask,
                  Int32(ip.pointee.sa_family) == AF_INET,
                  Int32(mask.pointee.sa_family) == AF_INET,
                  (item.ifa_flags & UInt32(IFF_UP)) != 0,
                  (item.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 else { continue }
            let name = String(cString: item.ifa_name)
            guard !["utun", "awdl", "llw", "lo"].contains(where: name.hasPrefix) else { continue }
            let ip4 = UnsafeRawPointer(ip).assumingMemoryBound(to: sockaddr_in.self).pointee
            let mask4 = UnsafeRawPointer(mask).assumingMemoryBound(to: sockaddr_in.self).pointee
            let address = dotted(UInt32(bigEndian: ip4.sin_addr.s_addr))
            let netmask = dotted(UInt32(bigEndian: mask4.sin_addr.s_addr))
            let targets = candidates(address: address, mask: netmask)
            guard !targets.isEmpty else { continue }
            found.append(.init(name: name, address: address, netmask: netmask,
                               prefix: UInt32(bigEndian: mask4.sin_addr.s_addr).nonzeroBitCount,
                               addresses: targets))
        }
        return found.sorted { $0.name < $1.name }
    }

    static func ping(_ address: String) -> Bool {
        guard let a = uint32(address), privateIPv4(a) else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-n", "-c", "1", "-W", "850", "-t", "2", address]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        do { try process.run(); process.waitUntilExit(); return process.terminationStatus == 0 }
        catch { return false }
    }

    static func arpCached(on adapter: LANInterface) -> [String] {
        let p = Process(), output = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
        p.arguments = ["-an"]
        p.standardOutput = output
        p.standardError = FileHandle.nullDevice
        do {
            try p.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            guard p.terminationStatus == 0,
                  let text = String(data: data, encoding: .utf8) else { return [] }
            let allowed = Set(adapter.addresses)
            return Array(Set(text.split(separator: "\n").compactMap { line -> String? in
                let row = String(line)
                guard row.contains(" at "), !row.contains("(incomplete)"),
                      let begin = row.firstIndex(of: "("),
                      let end = row[begin...].firstIndex(of: ")") else { return nil }
                let ip = String(row[row.index(after: begin)..<end])
                return allowed.contains(ip) ? ip : nil
            })).sorted()
        } catch { return [] }
    }
}
