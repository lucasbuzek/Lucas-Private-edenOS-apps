import SwiftUI

struct BifrostSpectrum: View {
    var body: some View {
        LinearGradient(
            colors: [.cyan, .blue, .indigo, .purple, .pink, .orange, .yellow],
            startPoint: .leading, endPoint: .trailing
        )
        .mask(RoundedRectangle(cornerRadius: 3))
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}

struct BifrostHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            BifrostSpectrum()
            Text(title).font(.system(size: 34, weight: .semibold, design: .rounded))
            Text(subtitle).font(.title3).foregroundStyle(.secondary)
        }
    }
}
