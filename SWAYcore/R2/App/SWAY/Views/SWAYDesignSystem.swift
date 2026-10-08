import SwiftUI

/// The single visual vocabulary for the consumer app, derived from the Build 122 final board.
enum SwayTheme {
    static let background = Color(red: 0.018, green: 0.020, blue: 0.026)
    static let elevatedBackground = Color(red: 0.035, green: 0.040, blue: 0.052)
    static let surface = Color.white.opacity(0.075)
    static let surfaceStrong = Color.white.opacity(0.12)
    static let accent = Color(red: 1.0, green: 0.08, blue: 0.46)
    static let violet = Color(red: 0.63, green: 0.33, blue: 1.0)
    static let cyan = Color(red: 0.32, green: 0.72, blue: 1.0)
    static let lime = Color(red: 0.35, green: 0.91, blue: 0.55)
    static let coral = Color(red: 1.0, green: 0.40, blue: 0.28)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let divider = Color.white.opacity(0.12)
    static let radius: CGFloat = 20
    static let compactRadius: CGFloat = 14
    static let pageInset: CGFloat = 18
    static let minimumTarget: CGFloat = 44
    static let stageGradient = LinearGradient(colors: [Color(red: 0.18, green: 0.02, blue: 0.22), Color(red: 0.025, green: 0.035, blue: 0.07), Color(red: 0.10, green: 0.01, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let accentGradient = LinearGradient(colors: [accent, Color(red: 0.92, green: 0.10, blue: 0.72)], startPoint: .leading, endPoint: .trailing)

    static func styleAccent(_ style: String) -> Color {
        let key = style.lowercased()
        if key.contains("house") { return cyan }
        if key.contains("disco") { return .orange }
        if key.contains("hip") { return Color(red: 0.25, green: 0.72, blue: 1.0) }
        if key.contains("afro") || key.contains("amapiano") { return coral }
        if key.contains("latin") { return accent }
        return violet
    }
}

struct SwayScreenBackground: View {
    var body: some View { SwayTheme.background.ignoresSafeArea().accessibilityHidden(true) }
}

struct SwayPill: View {
    let text: String
    let selected: Bool
    var body: some View {
        Text(text).font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.white : SwayTheme.textSecondary)
            .padding(.horizontal, 14).frame(minHeight: SwayTheme.minimumTarget)
            .background(selected ? SwayTheme.accentGradient : LinearGradient(colors: [SwayTheme.surfaceStrong], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .overlay(Capsule().stroke(SwayTheme.divider, lineWidth: selected ? 0 : 1))
            .contentShape(Capsule()).accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct SwayCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(SwayTheme.surface, in: RoundedRectangle(cornerRadius: SwayTheme.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: SwayTheme.radius, style: .continuous).stroke(SwayTheme.divider, lineWidth: 1))
    }
}

struct SwaySectionTitle: View {
    let title: String
    var detail: String? = nil
    var body: some View { HStack { Text(title).font(.title3.bold()); Spacer(); if let detail { Text(detail).font(.caption.weight(.semibold)).foregroundStyle(SwayTheme.textSecondary) } } }
}

struct SwayStatTile: View {
    let value: String
    let label: String
    var symbol: String? = nil
    var body: some View {
        VStack(spacing: 5) { if let symbol { Image(systemName: symbol).foregroundStyle(SwayTheme.accent) }; Text(value).font(.title2.bold()).monospacedDigit(); Text(label).font(.caption).foregroundStyle(SwayTheme.textSecondary) }
            .frame(maxWidth: .infinity, minHeight: 76).background(SwayTheme.surface, in: RoundedRectangle(cornerRadius: SwayTheme.compactRadius))
    }
}

struct SwayPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.bold()).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 52)
            .background(SwayTheme.accentGradient, in: Capsule()).scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
