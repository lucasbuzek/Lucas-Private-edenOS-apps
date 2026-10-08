import SwiftUI

enum SWAYUI {
    static let ink = Color(red: 0.025, green: 0.024, blue: 0.033)
    static let card = Color(red: 0.095, green: 0.09, blue: 0.12)
    static let raised = Color(red: 0.15, green: 0.14, blue: 0.18)
    static let pink = Color(red: 1, green: 0.12, blue: 0.48)
    static let violet = Color(red: 0.55, green: 0.29, blue: 1)
    static let neon = Color(red: 0.72, green: 1, blue: 0.35)
    static let cyan = Color(red: 0.22, green: 0.86, blue: 1)
    static let secondary = Color.white.opacity(0.66)
    static let radius: CGFloat = 24
    static let stage = LinearGradient(colors: [Color(red: 0.19, green: 0.04, blue: 0.2), ink], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct SWAYScreen<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView { content.padding(.horizontal, 18).padding(.vertical, 12).frame(maxWidth: 980) }
            .frame(maxWidth: .infinity).background(SWAYUI.ink.ignoresSafeArea())
    }
}

struct SWAYCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(SWAYUI.card, in: RoundedRectangle(cornerRadius: SWAYUI.radius, style: .continuous))
    }
}

struct SWAYPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.bold()).foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(SWAYUI.pink.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SWAYSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.bold()).foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(SWAYUI.raised.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
    }
}

struct SWAYChip: View {
    let title: String
    let selected: Bool
    var body: some View {
        Text(title).font(.subheadline.bold()).padding(.horizontal, 16).frame(minHeight: 44)
            .foregroundStyle(selected ? .white : SWAYUI.secondary)
            .background(selected ? SWAYUI.pink : SWAYUI.raised, in: Capsule())
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct SWAYStatTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) { Text(value).font(.title2.bold().monospacedDigit()); Text(label).font(.caption).foregroundStyle(SWAYUI.secondary) }
            .frame(maxWidth: .infinity, minHeight: 82).background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .combine)
    }
}

// Compatibility for feature views retained behind the new release UI.
enum SwayTheme {
    static let background = SWAYUI.ink, surface = SWAYUI.card, surfaceStrong = SWAYUI.raised
    static let accent = SWAYUI.pink, violet = SWAYUI.violet, cyan = SWAYUI.cyan, lime = SWAYUI.neon
    static let coral = Color.orange, textSecondary = SWAYUI.secondary, stageGradient = SWAYUI.stage
    static let radius: CGFloat = SWAYUI.radius
    static func styleAccent(_ style: String) -> Color { style.lowercased().contains("latin") ? .orange : SWAYUI.pink }
}
struct SwayPill: View { let text: String; let selected: Bool; var body: some View { SWAYChip(title: text, selected: selected) } }
struct SwayCard<Content: View>: View { @ViewBuilder let content: Content; var body: some View { SWAYCard(content: content) } }
struct SwayPrimaryButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.font(.headline.bold()).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 52).background(SWAYUI.pink, in: Capsule()).opacity(configuration.isPressed ? 0.7 : 1) } }
struct SwayPinkButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.font(.headline.bold()).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 52).background(SWAYUI.pink, in: Capsule()).opacity(configuration.isPressed ? 0.7 : 1) } }
