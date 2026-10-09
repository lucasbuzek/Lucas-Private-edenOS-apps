import SwiftUI

/// Feature colors identify the domain. Health is always a separate live state.
enum BifrostFeature {
    case overview, devices, apps, connections, capabilities, janitor, tasks
    case backup, ai, settings, representation, remote

    var color: Color {
        switch self {
        case .overview: return Color(red: 0.38, green: 0.25, blue: 0.85)
        case .devices, .connections, .remote: return Color(red: 0.12, green: 0.55, blue: 0.98)
        case .apps, .representation: return Color(red: 0.52, green: 0.32, blue: 0.92)
        case .capabilities: return Color(red: 0.68, green: 0.37, blue: 0.95)
        case .janitor, .backup: return Color(red: 0.94, green: 0.65, blue: 0.17)
        case .tasks: return Color(red: 0.31, green: 0.67, blue: 0.96)
        case .ai: return Color(red: 0.24, green: 0.73, blue: 0.84)
        case .settings: return Color(red: 0.61, green: 0.65, blue: 0.73)
        }
    }
}

enum BifrostAppearance {
    static let healthy = Color(red: 0.19, green: 0.76, blue: 0.44)
    static let warning = Color(red: 0.98, green: 0.69, blue: 0.18)
    static let failed = Color(red: 0.93, green: 0.31, blue: 0.35)
    static let unknown = Color.secondary
}

struct BifrostSpectrum: View {
    var body: some View {
        LinearGradient(
            colors: [.cyan, .blue, .indigo, .purple, .pink, .orange, .yellow],
            startPoint: .leading, endPoint: .trailing
        )
        .mask(RoundedRectangle(cornerRadius: 3))
        .frame(height: 3)
        .accessibilityHidden(true)
    }
}

private struct BridgeArc: Shape {
    let inset: CGFloat
    func path(in rect: CGRect) -> Path {
        let left = rect.minX + 3 + inset
        let right = rect.maxX - 3 - inset
        let bottom = rect.maxY - 2
        let controlY = -6 + inset * 1.6
        var path = Path()
        path.move(to: CGPoint(x: left, y: bottom))
        path.addCurve(to: CGPoint(x: right, y: bottom),
                      control1: CGPoint(x: left, y: controlY),
                      control2: CGPoint(x: right, y: controlY))
        return path
    }
}

/// Native vector bridge symbol, preserving the recovered rainbow-arch identity.
struct BifrostBridgeSymbol: View {
    var body: some View {
        ZStack {
            BridgeArc(inset: 0)
                .stroke(LinearGradient(colors: [.cyan, .blue, .purple, .pink, .orange],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            BridgeArc(inset: 5)
                .stroke(LinearGradient(colors: [.blue, .indigo, .purple, .orange],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
            BridgeArc(inset: 10)
                .stroke(LinearGradient(colors: [.cyan, .purple, .pink],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
        }
        .frame(width: 35, height: 28)
        .accessibilityHidden(true)
    }
}

struct BifrostBrand: View {
    var body: some View {
        HStack(spacing: 9) {
            BifrostBridgeSymbol()
            VStack(alignment: .leading, spacing: 1) {
                Text("BIFROST").font(.headline.weight(.bold))
                Text("CONNECT · KEEP · RESOLVE")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.8).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct BifrostFeatureIcon: View {
    let symbol: String
    let feature: BifrostFeature
    var size: CGFloat = 15
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(feature.color)
            .frame(width: size + 19, height: size + 17)
            .background(feature.color.opacity(0.13),
                        in: RoundedRectangle(cornerRadius: 9))
            .accessibilityHidden(true)
    }
}

struct BifrostHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BifrostSpectrum()
            Text(title).font(.system(size: 25, weight: .semibold, design: .rounded))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
