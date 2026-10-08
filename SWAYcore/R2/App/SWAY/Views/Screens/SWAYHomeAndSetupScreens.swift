import SwiftUI

struct SWAYHomeScreen: View {
    @EnvironmentObject private var store: SwayStore
    @Binding var selection: SWAYTab
    var body: some View {
        SWAYScreen {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("SWAY").font(.system(.largeTitle, design: .rounded, weight: .black)); Spacer(); NavigationLink { SWAYSettingsScreen() } label: { Image(systemName: "gearshape.fill").frame(width: 44, height: 44) }.accessibilityLabel("Settings") }
                ZStack(alignment: .bottomLeading) {
                    SWAYUI.stage
                    HStack { Spacer(); SWAYCharacterStage(character: .lucia, source: .idle).frame(width: 210, height: 280) }
                    VStack(alignment: .leading, spacing: 6) {
                        Spacer(); Text("Let's Dance").font(.system(size: 34, weight: .black, design: .rounded))
                        Text("Move • Feel • Progress").foregroundStyle(SWAYUI.secondary)
                        NavigationLink { SWAYWorkoutSetupScreen() } label: { Label("DANCE", systemImage: "play.fill").frame(width: 150).frame(minHeight: 52) }.buttonStyle(SWAYPrimaryButtonStyle())
                        Text("Set Up & Start").font(.caption.bold()).foregroundStyle(SWAYUI.secondary).padding(.leading, 28)
                    }.padding(22)
                }.frame(height: 330).clipShape(RoundedRectangle(cornerRadius: 30))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    shortcut("Moves", "figure.dance") { selection = .moves }
                    shortcut("Beats", "waveform") { selection = .beats }
                    NavigationLink { SWAYProgressScreen() } label: { shortcutLabel("Progress", "chart.bar.fill") }.buttonStyle(.plain)
                    shortcut("Profile", "person.crop.circle.fill") { selection = .profile }
                }
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
    private func shortcut(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View { Button(action: action) { shortcutLabel(title, icon) }.buttonStyle(.plain) }
    private func shortcutLabel(_ title: String, _ icon: String) -> some View { HStack { Image(systemName: icon).foregroundStyle(SWAYUI.pink); Text(title).font(.headline); Spacer(); Image(systemName: "chevron.right").foregroundStyle(SWAYUI.secondary) }.padding(16).frame(minHeight: 72).background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 20)) }
}

struct SWAYWorkoutSetupScreen: View {
    @StateObject private var model = SWAYWorkoutSetupViewModel()
    var body: some View {
        SWAYScreen { VStack(alignment: .leading, spacing: 20) {
            Text("How do you want to dance?").font(.largeTitle.bold())
            HStack(spacing: 12) {
                modeCard(.camera, "Get real-time feedback", "camera.fill")
                modeCard(.follow, "No camera needed", "play.rectangle.fill")
            }
            Text("Choose a Workout").font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(model.filters, id: \.self) { item in Button { model.filter = item } label: { SWAYChip(title: item, selected: model.filter == item) }.buttonStyle(.plain) } } }
            ForEach([("Foundation Flow", "15 min • Beginner", "figure.cooldown"), ("Good Energy", "20 min • Dance Fit", "bolt.heart.fill"), ("Cardio Groove", "25 min • Intermediate", "flame.fill")], id: \.0) { workout in
                HStack(spacing: 14) { RoundedRectangle(cornerRadius: 16).fill(SWAYUI.stage).frame(width: 88, height: 76).overlay(Image(systemName: workout.2).font(.title)); VStack(alignment: .leading) { Text(workout.0).font(.headline); Text(workout.1).font(.subheadline).foregroundStyle(SWAYUI.secondary) }; Spacer(); Image(systemName: "chevron.right") }.padding(10).background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 20))
            }
            NavigationLink { model.mode == .camera ? AnyView(SWAYCalibrationScreen()) : AnyView(SWAYWorkoutScreen()) } label: { Text("Start Workout") }.buttonStyle(SWAYPrimaryButtonStyle())
        } }.navigationBarTitleDisplayMode(.inline)
    }
    private func modeCard(_ mode: SWAYWorkoutSetupViewModel.TrackingMode, _ detail: String, _ icon: String) -> some View {
        Button { model.mode = mode } label: { VStack(alignment: .leading, spacing: 10) { Image(systemName: icon).font(.title).foregroundStyle(SWAYUI.pink); Text(mode.rawValue).font(.headline); Text(detail).font(.caption).foregroundStyle(SWAYUI.secondary) }.padding(16).frame(maxWidth: .infinity, minHeight: 145, alignment: .leading).background(model.mode == mode ? SWAYUI.violet.opacity(0.4) : SWAYUI.card, in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(model.mode == mode ? SWAYUI.pink : .clear, lineWidth: 2)) }.buttonStyle(.plain)
    }
}
