import SwiftUI

/// BIFROST UIX palette. Feature accents identify domains; runtime status colors
/// are separate and must only reflect observed state.
enum BifrostUI {
    static let canvas = Color(red: 0.060, green: 0.075, blue: 0.115)
    static let sidebar = Color(red: 0.085, green: 0.100, blue: 0.153)
    static let panel = Color(red: 0.100, green: 0.123, blue: 0.183)
    static let elevated = Color(red: 0.137, green: 0.164, blue: 0.231)
    static let line = Color.white.opacity(0.09)
    static let muted = Color(red: 0.64, green: 0.69, blue: 0.80)

    static let bridge = Color(red: 0.32, green: 0.77, blue: 0.98)
    static let devices = Color(red: 0.15, green: 0.55, blue: 0.99)
    static let apps = Color(red: 0.59, green: 0.37, blue: 0.98)
    static let janitor = Color(red: 0.99, green: 0.69, blue: 0.26)
    static let tasks = Color(red: 0.40, green: 0.62, blue: 1.00)
    static let ai = Color(red: 0.28, green: 0.84, blue: 0.80)
    static let backup = Color(red: 0.98, green: 0.74, blue: 0.35)
    static let healthy = Color(red: 0.27, green: 0.85, blue: 0.51)
    static let warning = Color(red: 1.00, green: 0.71, blue: 0.28)
    static let problem = Color(red: 0.99, green: 0.36, blue: 0.39)
    static let raven = Color(red: 0.78, green: 0.43, blue: 0.96)

    static func featureColor(_ section: String) -> Color {
        switch section {
        case "Overview", "Connections", "Representations", "Index & Identity": bridge
        case "Devices": devices
        case "JANITOR": janitor
        case "App Management", "Install & Setup", "Capabilities": apps
        case "Development & Releases": tasks
        case "Settings": Color(red: 0.65, green: 0.72, blue: 0.90)
        default: bridge
        }
    }

    static func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "running", "available", "active", "online", "observed": healthy
        case "offline", "stopped", "failed", "error", "unavailable": problem
        default: warning
        }
    }
}

/// Spectral bridge symbol; compact enough for sidebars, status tiles and menu UI.
struct BifrostMark: View {
    var size: CGFloat = 32

    private let stripes: [Color] = [
        .cyan, .blue, .indigo, .purple, .pink, .orange
    ]

    var body: some View {
        Canvas { context, canvas in
            let scale = min(canvas.width / 36, canvas.height / 28)
            let center = CGPoint(x: canvas.width / 2, y: canvas.height * 0.82)
            for (index, color) in stripes.enumerated() {
                let radius = (CGFloat(17.0) - CGFloat(index) * 2.6) * scale
                var arch = Path()
                arch.addArc(center: center,
                            radius: radius,
                            startAngle: .degrees(180),
                            endAngle: .degrees(0),
                            clockwise: false)
                context.stroke(arch, with: .color(color),
                               style: StrokeStyle(lineWidth: max(1.4, 2.1 * scale),
                                                  lineCap: .round))
            }
        }
        .frame(width: size, height: size * 0.78)
        .accessibilityLabel("BIFROST spectral bridge")
    }
}

struct BifrostColorIcon: View {
    let name: String
    let symbol: String
    let accent: Color

    init(_ name: String, symbol: String, accent: Color? = nil) {
        self.name = name
        self.symbol = symbol
        self.accent = accent ?? BifrostUI.featureColor(name)
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(accent)
            .frame(width: 32, height: 32)
            .background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
            .accessibilityHidden(true)
    }
}

struct BifrostStatusDot: View {
    let status: String

    var body: some View {
        Circle()
            .fill(BifrostUI.statusColor(status))
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }
}

struct BifrostPanel<Content: View>: View {
    var title: String
    var symbol: String
    var accent: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(accent)
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BifrostUI.panel, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(BifrostUI.line))
    }
}
