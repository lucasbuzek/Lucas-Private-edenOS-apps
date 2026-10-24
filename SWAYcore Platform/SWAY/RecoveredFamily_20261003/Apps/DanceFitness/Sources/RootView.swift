import SwiftUI
import SWAYcoreKit
import SWAYAppKit

struct RootView: View {
    @EnvironmentObject var model: AppModel
    enum Tab: Hashable { case home, moves, beats, profile }
    @State private var tab: Tab = .home
    @State private var workout: WorkoutPlan?
    var body: some View {
        ZStack {
            StageBackground()
            if !model.state.settings.onboarded { OnboardingView() } else {
                TabView(selection: $tab) {
                    HomeView(start: { workout = $0 }, goMoves: { tab = .moves }).tabItem { Label("HOME", systemImage: "house.fill") }.tag(Tab.home)
                    MovesView(start: { workout = $0 }).tabItem { Label("MOVES", systemImage: "figure.dance") }.tag(Tab.moves)
                    BeatsView().tabItem { Label("BEATS", systemImage: "music.note") }.tag(Tab.beats)
                    ProfileView().tabItem { Label("PROFILE", systemImage: "person.crop.circle") }.tag(Tab.profile)
                }
            }
        }
        .fullScreenCover(item: $workout) { plan in WorkoutFlowView(plan: plan) { workout = nil } }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            CharacterStageView(characterID: model.state.settings.coach.rawValue, pose: MoveLibrary.all[0].pose(atBeat: 0)).frame(maxHeight: 460)
            Text("WATCH · COPY · MATCH · DANCE").font(.caption.weight(.bold)).tracking(2).foregroundStyle(SwayTheme.cyan)
            Text("Meet your coach").font(.largeTitle.bold())
            Picker("Coach", selection: $model.state.settings.coach) { ForEach(CoachID.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.segmented).padding(.horizontal)
            Button("Let's dance") { model.state.settings.onboarded = true }.buttonStyle(SwayButtonStyle())
            Text("Camera is optional and stays on your device.").font(.footnote).foregroundStyle(SwayTheme.subtext)
            Spacer()
        }.padding()
    }
}

struct HomeView: View {
    @EnvironmentObject var model: AppModel
    var start: (WorkoutPlan) -> Void; var goMoves: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            let stage = CharacterStageView(characterID: model.state.settings.coach.rawValue, pose: MoveLibrary.byID["sway_idle_v1"]!.pose(atBeat: 0))
            let panel = VStack(alignment: .leading, spacing: 14) {
                Text("Hi, let's SWAY").font(.largeTitle.bold())
                if model.state.progress.streakDays > 0 { Pill("\(model.state.progress.streakDays)-day streak", tint: SwayTheme.magenta) }
                Button { start(.quick(model: model)) } label: { Label("Start", systemImage: "play.fill").frame(maxWidth: .infinity) }.buttonStyle(SwayButtonStyle())
                Button { goMoves() } label: { Label("Learn a move", systemImage: "graduationcap").frame(maxWidth: .infinity) }.buttonStyle(SwayButtonStyle(prominent: false))
                let learned = model.state.progress.mastery.values.filter { $0 != .discovered }.count
                Text("\(learned) of \(model.library.count) moves started").font(.subheadline).foregroundStyle(SwayTheme.subtext)
                ProgressView(value: Double(learned), total: Double(max(model.library.count, 1))).tint(SwayTheme.cyan)
            }.frame(maxWidth: wide ? 420 : .infinity, alignment: .leading)
            if wide { HStack(spacing: 24) { stage; panel }.padding(32) } else { VStack(spacing: 8) { stage.frame(height: geo.size.height * 0.58); panel }.padding() }
        }
    }
}

struct MovesView: View {
    @EnvironmentObject var model: AppModel
    var start: (WorkoutPlan) -> Void
    @State private var selected = MoveLibrary.all[0]
    @State private var learn: MovementDefinition?
    @State private var creating = false
    @State private var importing = false
    private let cols = [GridItem(.adaptive(minimum: 160), spacing: 12)]
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let wide = geo.size.width > geo.size.height
                let preview = VStack(spacing: 10) {
                    TimelineView(.animation) { ctx in
                        CharacterStageView(characterID: model.state.settings.coach.rawValue,
                                           pose: selected.pose(atBeat: model.state.settings.reducedMotion ? 0 : ctx.date.timeIntervalSinceReferenceDate * 100.0 / 60.0))
                    }
                    Text(selected.name).font(.title2.bold())
                    HStack { Button("Learn") { learn = selected }.buttonStyle(SwayButtonStyle()); Button("Practice") { start(.practice(selected, model: model)) }.buttonStyle(SwayButtonStyle(prominent: false)) }
                }
                let list = ScrollView {
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(model.visibleLibrary) { m in
                            Button { selected = m } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(m.name).font(.headline)
                                    HStack { Pill(String(describing: m.complexity).capitalized); Pill(String(describing: model.mastery(m.id)).capitalized, tint: SwayTheme.cyan) }
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                .background(m.id == selected.id ? SwayTheme.violet.opacity(0.35) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain).accessibilityLabel("\(m.name), \(String(describing: model.mastery(m.id)))")
                        }
                    }.padding()
                }
                if wide { HStack { preview.frame(width: geo.size.width * 0.5); list } } else { VStack { preview.frame(height: geo.size.height * 0.5); list } }
            }
            .navigationTitle("MOVES")
            .toolbar { ToolbarItemGroup {
                Button { importing = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
                Button { creating = true } label: { Label("Create", systemImage: "plus.circle.fill") } } }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .data]) { if case .success(let u) = $0 { model.importPack(from: u) } }
            .alert("Import", isPresented: Binding(get: { model.importError != nil }, set: { _ in model.importError = nil })) { Button("OK") {} } message: { Text(model.importError ?? "") }
            .sheet(item: $learn) { m in LearnView(movement: m, practice: { learn = nil; start(.practice(m, model: model)) }) }
            .sheet(isPresented: $creating) { CreateMoveView() }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var model: AppModel
    @State private var showDancer = false
    var body: some View {
        NavigationStack {
            Form {
                Section("YOUR DANCER") { Button("Customize") { showDancer = true } }
                Section("Coach") { Picker("Coach", selection: $model.state.settings.coach) { ForEach(CoachID.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } } }
                Section("Training") {
                    Toggle("Low impact only", isOn: $model.state.settings.lowImpact)
                    Picker("Voice", selection: $model.state.settings.voice) { Text("Off").tag(VoiceLevel.off); Text("Minimal").tag(VoiceLevel.minimal); Text("Normal").tag(VoiceLevel.normal); Text("Detailed").tag(VoiceLevel.detailed) }
                    Toggle("Reduce motion", isOn: $model.state.settings.reducedMotion)
                }
                Section("Integrations") {
                    HStack { Text("Apple Health"); Spacer(); Text(healthText).foregroundStyle(.secondary) }
                    Button("Connect Health") { Task { await model.health.requestAccess() } }
                    HStack { Text("Apple Music"); Spacer(); Text(String(describing: model.music.status)).foregroundStyle(.secondary) }
                    Button("Connect Apple Music") { Task { await model.music.requestAccess() } }
                }
                Section("History") {
                    ForEach(model.library.filter { model.state.progress.attempts[$0.id] != nil }) { m in
                        HStack { Text(m.name); Spacer(); Text("\(model.state.progress.attempts[m.id] ?? 0)×  \(String(describing: model.mastery(m.id)).capitalized)").foregroundStyle(.secondary) }
                    }
                }
            }.scrollContentBackground(.hidden).navigationTitle("PROFILE")
            .sheet(isPresented: $showDancer) { DancerEditor() }
        }
    }
    var healthText: String { switch model.health.state { case .unavailable: "Unavailable"; case .notDetermined: "Not connected"; case .denied: "Denied"; case .authorized: "Connected"; case .error(let e): "Error: \(e)" } }
}

struct DancerEditor: View {
    @EnvironmentObject var model: AppModel; @Environment(\.dismiss) var dismiss
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 700
            let preview = CharacterStageView(characterID: "yourdancer", pose: MoveLibrary.byID["sway_body_roll_v1"]!.pose(atBeat: 0),
                                             hair: model.state.settings.dancer.hair, outfit: model.state.settings.dancer.outfit)
            let controls = Form {
                Picker("Hair", selection: $model.state.settings.dancer.hair) { ForEach(DancerLook.hairStyles, id: \.self) { Text($0.capitalized) } }
                Picker("Outfit", selection: $model.state.settings.dancer.outfit) { ForEach(DancerLook.outfits, id: \.self) { Text($0) } }
                Button("Done") { dismiss() }
            }.scrollContentBackground(.hidden)
            ZStack { StageBackground(); if wide { HStack { preview; controls.frame(width: 340) } } else { VStack { preview.frame(height: geo.size.height * 0.62); controls } } }
        }
    }
}
