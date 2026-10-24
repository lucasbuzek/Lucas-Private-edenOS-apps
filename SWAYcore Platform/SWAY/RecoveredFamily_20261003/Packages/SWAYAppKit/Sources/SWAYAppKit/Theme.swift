import SwiftUI

/// SWAY visual language reconstructed from the Bible: dark stage, violet/magenta/cyan accents, restrained rounded controls.
public enum SwayTheme {
    public static let ink = Color(red: 0.04, green: 0.03, blue: 0.09)
    public static let stageTop = Color(red: 0.16, green: 0.07, blue: 0.30)
    public static let violet = Color(red: 0.55, green: 0.30, blue: 0.95)
    public static let magenta = Color(red: 0.95, green: 0.25, blue: 0.65)
    public static let cyan = Color(red: 0.20, green: 0.85, blue: 0.95)
    public static let text = Color.white
    public static let subtext = Color.white.opacity(0.68)
    public static let gradient = LinearGradient(colors: [violet, magenta], startPoint: .leading, endPoint: .trailing)
}

public struct StageBackground: View {
    public init() {}
    public var body: some View {
        ZStack {
            LinearGradient(colors: [SwayTheme.stageTop, SwayTheme.ink], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [SwayTheme.magenta.opacity(0.28), .clear], center: .init(x: 0.5, y: 0.82), startRadius: 10, endRadius: 420)
            RadialGradient(colors: [SwayTheme.cyan.opacity(0.16), .clear], center: .init(x: 0.12, y: 0.15), startRadius: 10, endRadius: 360)
        }.ignoresSafeArea()
    }
}

public struct SwayButtonStyle: ButtonStyle {
    public var prominent: Bool
    public init(prominent: Bool = true) { self.prominent = prominent }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.white)
            .padding(.horizontal, 22).frame(minHeight: 52)
            .background(Group { if prominent { Capsule().fill(SwayTheme.gradient) } else { Capsule().fill(Color.white.opacity(0.12)) } })
            .overlay(Capsule().stroke(Color.white.opacity(prominent ? 0 : 0.2)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1).opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(Capsule())
    }
}

public struct Pill: View {
    let text: String; var tint: Color
    public init(_ t: String, tint: Color = SwayTheme.violet) { text = t; self.tint = tint }
    public var body: some View { Text(text).font(.caption.weight(.semibold)).padding(.horizontal, 10).padding(.vertical, 5).background(tint.opacity(0.35), in: Capsule()) }
}
