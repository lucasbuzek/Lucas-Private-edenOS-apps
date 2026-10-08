import SwiftUI

struct SWAYMovesScreen: View {
    @EnvironmentObject private var store: SwayStore
    @StateObject private var model = SWAYMoveLibraryViewModel()
    var body: some View { SWAYScreen { VStack(alignment: .leading, spacing: 18) {
        HStack { Text("Moves").font(.largeTitle.bold()); Spacer(); NavigationLink { SWAYCreateMoveScreen() } label: { Image(systemName: "plus").frame(width: 44, height: 44).background(SWAYUI.card, in: Circle()) }.accessibilityLabel("Create move") }
        ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(model.filters, id: \.self) { item in Button { model.filter = item } label: { SWAYChip(title: item, selected: model.filter == item) }.buttonStyle(.plain) } } }
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(store.moves.prefix(12)) { move in NavigationLink { SWAYLearnMoveScreen(move: move) } label: { moveCard(move) }.buttonStyle(.plain) } }
    } }.toolbar(.hidden, for: .navigationBar) }
    private func moveCard(_ move: DanceMove) -> some View { VStack(alignment: .leading, spacing: 8) { ZStack(alignment: .topTrailing) { SWAYUI.stage; SWAYCharacterStage(character: .lucia, source: .move(id: move.id, musicalTime: 0.5, bpm: 100, paused: true)).padding(6); Button { model.toggle(move.id) } label: { Image(systemName: model.favourites.contains(move.id) ? "heart.fill" : "heart").frame(width: 44, height: 44).foregroundStyle(SWAYUI.pink) }.accessibilityLabel(model.favourites.contains(move.id) ? "Remove from favourites" : "Add to favourites") }.frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 20)); Text(move.name).font(.headline); Text(move.difficulty == 1 ? "Beginner" : move.difficulty < 4 ? "Intermediate" : "Advanced").font(.caption).foregroundStyle(SWAYUI.secondary) }.padding(8).background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 24)) }
}

struct SWAYLearnMoveScreen: View {
    let move: DanceMove
    @State private var repetitions = 4
    @State private var step = 0
    var body: some View { SWAYScreen { VStack(alignment: .leading, spacing: 18) { Text("LEARN: \(move.name.uppercased())").font(.title.bold()); ZStack { SWAYUI.stage; SWAYCharacterStage(character: .lucia, source: .move(id: move.id, musicalTime: Double(step) * 0.25, bpm: 90, paused: true)).padding(); HStack { Button { step = max(0, step - 1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44).background(.black.opacity(0.5), in: Circle()) }; Spacer(); Button { step = min(3, step + 1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44).background(.black.opacity(0.5), in: Circle()) } }.padding() }.frame(height: 420).clipShape(RoundedRectangle(cornerRadius: 28)); HStack { ForEach(0..<4, id: \.self) { index in SWAYCharacterStage(character: .lucia, source: .move(id: move.id, musicalTime: Double(index) * 0.25, bpm: 90, paused: true)).padding(3).frame(maxWidth: .infinity, minHeight: 80).background(step == index ? SWAYUI.violet : SWAYUI.card, in: RoundedRectangle(cornerRadius: 14)).onTapGesture { step = index } } }; Stepper("Repetitions   \(repetitions)", value: $repetitions, in: 1...12).font(.headline).padding().background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 18)); NavigationLink("Start Practice") { SWAYWorkoutScreen() }.buttonStyle(SWAYPrimaryButtonStyle()) } } }
}

struct SWAYCreateMoveScreen: View {
    @EnvironmentObject private var store: SwayStore
    @State private var base = "step-touch"
    @State private var tempo = 108.0, range = 0.65, intensity = 0.55
    @State private var armStyle = "Flow"
    @State private var saved = false
    var body: some View { SWAYScreen { VStack(alignment: .leading, spacing: 18) { Text("Create Move").font(.largeTitle.bold()); Text("Base Movement").font(.title2.bold()); Picker("Base Movement", selection: $base) { ForEach(store.moves.prefix(8)) { Text($0.name).tag($0.id) } }.pickerStyle(.menu).tint(.white).padding().frame(maxWidth: .infinity, alignment: .leading).background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 18)); ZStack { SWAYUI.stage; SWAYCharacterStage(character: .lucia, source: .move(id: base, musicalTime: 0.7, bpm: tempo, paused: true)).padding() }.frame(height: 310).clipShape(RoundedRectangle(cornerRadius: 26)); Text("Customize").font(.title2.bold()); control("Tempo", value: $tempo, range: 70...150, valueText: "\(Int(tempo)) BPM"); control("Range", value: $range, range: 0...1, valueText: range < 0.4 ? "Small" : range < 0.75 ? "Medium" : "Wide"); Picker("Arm Style", selection: $armStyle) { ForEach(["Flow", "Reach", "Power"], id: \.self) { Text($0) } }.pickerStyle(.segmented); control("Intensity", value: $intensity, range: 0...1, valueText: intensity < 0.4 ? "Light" : intensity < 0.75 ? "Medium" : "High"); Button("Save Move") { store.addMove(name: "My \(store.moves.first(where: { $0.id == base })?.name ?? "Move")", style: armStyle, difficulty: Int(intensity * 2) + 1, basedOn: base); saved = true }.buttonStyle(SWAYPrimaryButtonStyle()) }.alert("Move Saved", isPresented: $saved) { Button("Done", role: .cancel) {} } } }
    private func control(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, valueText: String) -> some View { VStack { HStack { Text(title).font(.headline); Spacer(); Text(valueText).foregroundStyle(SWAYUI.secondary) }; Slider(value: value, in: range).tint(SWAYUI.pink) }.padding().background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 18)) }
}
