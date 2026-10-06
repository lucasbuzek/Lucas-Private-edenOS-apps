import SwiftUI
import AVFoundation
import UIKit

struct RootView: View {
    @EnvironmentObject var store:SwayStore
    @State private var booting = true
    @State private var showWelcome = false

    var body: some View {
        Group {
            if booting {
                SwayLaunchView()
            } else {
                TabView {
                    NavigationStack { HomeView() }.tabItem { Label("Home", systemImage:"house.fill") }
                    NavigationStack { MoveLibraryView() }.tabItem { Label("Moves", systemImage:"square.grid.2x2.fill") }
                    NavigationStack { SwayBeatsHubView() }.tabItem { Label("Beats", systemImage:"waveform") }
                    NavigationStack { SwayProfileHubView() }.tabItem { Label("Profile", systemImage:"person.crop.circle") }
                }
                .tint(SwayTheme.accent)
                .toolbarBackground(SwayTheme.background.opacity(0.96), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .fullScreenCover(isPresented:$showWelcome) { SwayWelcomeView() }
            }
        }
        .task {
            try? await Task.sleep(nanoseconds:900_000_000)
            booting = false
            showWelcome = !store.onboardingComplete
        }
    }
}

struct SwayInstructorPreset: Identifiable {
    let id: String
    let name: String
    let skin: Int
    let hair: Int
    let outfit: Int
    let move: String
    let phase: TimeInterval
    let assetPreset: Int
}

private let swayInstructorLineup: [SwayInstructorPreset] = [
    // Alpha intentionally exposes only the complete production instructor.
    .init(id:"lucia",name:"Lucia",skin:0,hair:0,outfit:0,move:"step-touch",phase:0.10,assetPreset:0)
]

/// The same functional SWAY rig used by COACH and Avatar creation, presented as a diverse ensemble.
/// These are not static placeholder glyphs: every instructor consumes canonical choreography poses.
struct SwayAvatarEnsemble: View {
    var backstage = false
    var body: some View {
        HStack(alignment:.bottom,spacing:-12) {
            ForEach(swayInstructorLineup) { instructor in
                SwayHumanFigureView(moveID:instructor.move,elapsed:instructor.phase,bpm:100,paused:true,mirrored:false,characterMode:!backstage,skinTone:instructor.skin,hairStyle:instructor.hair,outfitStyle:instructor.outfit,appearancePreset:instructor.assetPreset,instructorPreset:instructor.assetPreset)
                    .frame(width:76,height:154)
                    .accessibilityLabel("SWAY instructor \(instructor.name)")
            }
        }
    }
}

struct SwayLaunchView:View {
    @State private var arrived=false
    @State private var curtainOpen=false
    var body:some View {
        GeometryReader { proxy in
            ZStack {
                SwayTheme.stageGradient.ignoresSafeArea()
                RadialGradient(colors:[SwayTheme.violet.opacity(0.55),.clear],center:.center,startRadius:20,endRadius:320).ignoresSafeArea()
                VStack {
                    Spacer()
                    Text("THE STAGE IS YOURS").font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.7)).opacity(curtainOpen ? 1:0)
                    SwayAvatarEnsemble()
                    .frame(maxWidth:.infinity)
                    .scaleEffect(arrived ? 1:0.84).offset(y:arrived ? 0:110).opacity(arrived ? 0.98:0.15)
                    Spacer().frame(height:74)
                }
                HStack(spacing:0) {
                    Rectangle().fill(LinearGradient(colors:[Color(red:0.25,green:0.02,blue:0.31),Color(red:0.05,green:0.01,blue:0.09)],startPoint:.leading,endPoint:.trailing)).offset(x:curtainOpen ? -proxy.size.width*0.52:0)
                    Rectangle().fill(LinearGradient(colors:[Color(red:0.05,green:0.01,blue:0.09),Color(red:0.25,green:0.02,blue:0.31)],startPoint:.leading,endPoint:.trailing)).offset(x:curtainOpen ? proxy.size.width*0.52:0)
                }.ignoresSafeArea().allowsHitTesting(false)
                VStack(spacing:8) { Spacer(); Text("SWAY").font(.system(size:52,design:.rounded)).bold().tracking(3); Text("COME DANCE WITH US").font(.headline.bold()).tracking(2).foregroundStyle(SwayTheme.textSecondary); Spacer().frame(height:30) }.foregroundStyle(.white).opacity(curtainOpen ? 1:0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration:0.55)){ arrived=true }
            withAnimation(.easeInOut(duration:0.70).delay(0.30)){ curtainOpen=true }
        }
    }
}

struct SwayMark:View {
    var size:CGFloat=64
    var body:some View {
        ZStack {
            Circle().stroke(LinearGradient(colors:[SwayTheme.cyan,SwayTheme.violet,SwayTheme.lime],startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:size*0.11)
            Image(systemName:"waveform.path").font(.system(size:size*0.42,weight:.bold)).foregroundStyle(.white)
        }.frame(width:size,height:size)
    }
}

struct SwayWelcomeView:View {
    @EnvironmentObject var store:SwayStore
    @Environment(\.dismiss) private var dismiss
    @State private var step=0
    var body:some View {
        NavigationStack {
            ZStack {
                SwayTheme.stageGradient.ignoresSafeArea()
                VStack(spacing:24) {
                    Spacer()
                    SwayMark(size:104)
                    if step == 0 {
                        Text("Welcome to SWAY").font(.largeTitle.bold())
                        Text("Dance. Move. Feel good.").font(.title2.bold()).foregroundStyle(SwayTheme.cyan)
                        Text("A few quick choices, then you dance.").foregroundStyle(.secondary)
                    } else {
                        Text("Make it yours").font(.largeTitle.bold())
                        VStack(alignment:.leading,spacing:16) {
                            Text("MOVE COMPLEXITY").font(.caption.bold()).foregroundStyle(.secondary)
                            Picker("Move complexity",selection:$store.moveComplexity) {
                                Text("Simple").tag(1); Text("Easy").tag(2); Text("Moderate").tag(3); Text("Complex").tag(4); Text("Expert").tag(5)
                            }.pickerStyle(.segmented)
                            Toggle("Low impact",isOn:$store.lowImpact)
                            Toggle("Small space",isOn:$store.smallSpace)
                            Text("These describe the dance, not you. You can change them any time.").font(.footnote).foregroundStyle(.secondary)
                        }.padding(18).background(.thinMaterial,in:RoundedRectangle(cornerRadius:24))
                    }
                    Spacer()
                    if step == 0 {
                        Button("GET STARTED") { withAnimation{step=1} }.buttonStyle(SwayPrimaryButtonStyle())
                    } else {
                        Button("START WITH FOLLOW-ALONG") { store.cameraTrackingEnabled=false; finish() }.buttonStyle(SwayPrimaryButtonStyle())
                        Text("Movement tracking is optional and can be chosen when you start a dance.").font(.footnote).foregroundStyle(.secondary)
                    }
                }.padding(24).foregroundStyle(.white)
            }.toolbar(.hidden,for:.navigationBar)
        }
    }
    private func finish(){ store.onboardingComplete=true; store.save(); dismiss() }
}

struct CameraSetupView: View {
    var body:some View { CameraTrackingSetupLauncher() }
}

// MARK: - SWAY Visual Language 0.4
enum SwayTheme {
    static let background = Color(red: 0.018, green: 0.020, blue: 0.026)
    static let surface = Color.white.opacity(0.065)
    static let surfaceStrong = Color.white.opacity(0.105)
    static let accent = Color(red: 1.0, green: 0.10, blue: 0.48)
    static let violet = Color(red: 0.55, green: 0.28, blue: 1.0)
    static let coral = Color(red: 1.0, green: 0.40, blue: 0.28)
    static let stageGradient = LinearGradient(colors:[Color(red:0.045,green:0.025,blue:0.085),Color(red:0.13,green:0.025,blue:0.10),Color(red:0.025,green:0.035,blue:0.055)],startPoint:.topLeading,endPoint:.bottomTrailing)
    static let cyan = Color(red: 0.20, green: 0.88, blue: 1.0)
    static let lime = Color(red: 0.72, green: 1.0, blue: 0.34)
    static let textSecondary = Color.white.opacity(0.66)
    static let radius: CGFloat = 22
    static func styleAccent(_ style:String)->Color {
        let key=style.lowercased()
        if key.contains("house") { return cyan }
        if key.contains("disco") { return Color(red:1.0,green:0.66,blue:0.18) }
        if key.contains("hip") { return Color(red:0.25,green:0.72,blue:1.0) }
        if key.contains("afro") || key.contains("amapiano") { return Color(red:1.0,green:0.48,blue:0.18) }
        if key.contains("latin") { return Color(red:1.0,green:0.22,blue:0.42) }
        if key.contains("contemporary") { return Color(red:0.55,green:0.68,blue:1.0) }
        if key.contains("groove") { return violet }
        return cyan
    }
}

struct SwayPill: View {
    let text: String
    let selected: Bool

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.black : Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? SwayTheme.cyan : SwayTheme.surfaceStrong, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(selected ? 0 : 0.10), lineWidth: 1))
            .contentShape(Capsule())
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct SwayCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth:.infinity, alignment:.leading)
            .background(SwayTheme.surface, in: RoundedRectangle(cornerRadius:SwayTheme.radius, style:.continuous))
            .overlay(RoundedRectangle(cornerRadius:SwayTheme.radius, style:.continuous)
                .stroke(Color.white.opacity(0.08), lineWidth:1))
    }
}

struct SwayPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.black)
            .frame(maxWidth:.infinity)
            .padding(.vertical,14)
            .background(
                LinearGradient(colors:[SwayTheme.cyan,SwayTheme.lime],
                               startPoint:.leading,endPoint:.trailing),
                in: Capsule()
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SwayPinkButtonStyle: ButtonStyle {
    func makeBody(configuration:Configuration)->some View { configuration.label.font(.headline.bold()).foregroundStyle(.white).frame(maxWidth:.infinity).padding(.vertical,14).background(LinearGradient(colors:[SwayTheme.violet,SwayTheme.accent],startPoint:.leading,endPoint:.trailing),in:Capsule()).opacity(configuration.isPressed ? 0.75:1) }
}


struct SwayProfileHubView: View {
    @EnvironmentObject var store:SwayStore
    @State private var avatar=false
    var body: some View {
        ScrollView { VStack(alignment:.leading,spacing:18) {
            Text("Profile").font(.largeTitle.bold())
            HStack(spacing:16) { SwayAvatarPreview(character:store.character).frame(width:110,height:150); VStack(alignment:.leading){Text("Your SWAY dancer").font(.title3.bold()); Button("Customize Avatar"){avatar=true}.buttonStyle(.borderedProminent).tint(SwayTheme.accent)} }
                .padding().background(SwayTheme.stageGradient,in:RoundedRectangle(cornerRadius:24))
            NavigationLink { ProgressViewScreen() } label:{ hubRow("Progress","chart.line.uptrend.xyaxis","Workouts, learned moves and achievements") }
            NavigationLink { CreateMoveView() } label:{ hubRow("Create","plus.circle.fill","Build and save your own movement") }
            NavigationLink { SettingsView() } label:{ hubRow("Settings","gearshape.fill","Music, accessibility and app preferences") }
        }.padding(18).frame(maxWidth:1000).frame(maxWidth:.infinity,alignment:.top) }.background(SwayTheme.background.ignoresSafeArea()).preferredColorScheme(.dark).sheet(isPresented:$avatar){SwayAvatarCreatorView().environmentObject(store)}
    }
    private func hubRow(_ title:String,_ icon:String,_ detail:String)->some View { HStack(spacing:14){Image(systemName:icon).font(.title2).frame(width:38).foregroundStyle(SwayTheme.cyan);VStack(alignment:.leading){Text(title).font(.headline);Text(detail).font(.caption).foregroundStyle(.secondary)};Spacer();Image(systemName:"chevron.right").foregroundStyle(.secondary)}.foregroundStyle(.white).padding(16).background(Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:18)) }
}

struct SwayBeatsHubView: View {
    @StateObject private var music=SwayMusicEngine()
    @EnvironmentObject var store:SwayStore
    @State private var workout:[WorkoutStep]=[]
    @State private var play=false
    @State private var source="SWAY Beats"
    @State private var advanced=false
    var body: some View {
        ScrollView { VStack(alignment:.leading,spacing:18){
            Text("Beats").font(.largeTitle.bold())
            Picker("Music source",selection:$source){Text("SWAY Beats").tag("SWAY Beats");Text("Your Music").tag("Your Music")}.pickerStyle(.segmented)
            if source == "SWAY Beats" {
                ZStack(alignment:.bottomLeading) { SwayTheme.stageGradient; VStack(alignment:.leading,spacing:5){Image(systemName:"waveform.path").font(.system(size:42,weight:.bold)).foregroundStyle(SwayTheme.accent);Text(music.beatStyle.rawValue.uppercased()).font(.title.bold());Text("Automatic rhythm for dancing • offline").font(.caption).foregroundStyle(.white.opacity(0.7))}.padding(20) }.frame(height:145).clipShape(RoundedRectangle(cornerRadius:24))
                Text("Style").font(.headline)
                ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(SwayMusicEngine.BeatStyle.allCases){style in Button{music.useOfflineBeat(style:style)}label:{SwayPill(text:style.rawValue,selected:style==music.beatStyle)}.buttonStyle(.plain)}}}
                SwayCard { VStack(alignment:.leading,spacing:10){
                    HStack { Text("FEEL").font(.headline); Spacer(); Text("drag to shape the drummer").font(.caption).foregroundStyle(.secondary) }
                    SwayDrummerPad(complexity:$music.beatComplexity,intensity:$music.beatIntensity)
                    HStack { Text("SIMPLE").font(.caption2.bold()).foregroundStyle(.secondary); Spacer(); Text("COMPLEX").font(.caption2.bold()).foregroundStyle(.secondary) }
                    HStack{Text("Tempo").font(.headline);Spacer();Text("\(Int(music.bpm)) BPM").font(.headline).foregroundStyle(SwayTheme.accent)}
                    Slider(value:$music.bpm,in:70...160,step:1,onEditingChanged:{ editing in if !editing { music.setOfflineTempo(music.bpm) } }).tint(SwayTheme.accent)
                    HStack(spacing:10){
                        Button { if music.isPlaying { music.pause() } else { music.stop(); music.play() } } label:{Label(music.isPlaying ? "Pause":"Preview",systemImage:music.isPlaying ? "pause.fill":"play.fill").frame(maxWidth:.infinity,minHeight:44)}.buttonStyle(.bordered)
                        Button { music.stop(); music.play() } label:{Label("Restart Preview",systemImage:"shuffle").frame(maxWidth:.infinity,minHeight:44)}.buttonStyle(.bordered)
                    }
                    DisclosureGroup("Advanced",isExpanded:$advanced){NavigationLink { SwayMusicCoreView() } label:{Label("Music & Analysis Tools",systemImage:"slider.horizontal.3").frame(maxWidth:.infinity,minHeight:44)}.buttonStyle(.bordered).padding(.top,8)}
                }}
                Button { music.stop(); music.play(); workout=store.generate(minutes:15,difficulty:store.moveComplexity,lowImpact:store.lowImpact,smallSpace:store.smallSpace);play=true } label:{Label("DANCE WITH THIS BEAT",systemImage:"figure.dance").frame(maxWidth:.infinity,minHeight:52)}.buttonStyle(.borderedProminent).tint(SwayTheme.accent)
            } else {
                SwayCard { VStack(alignment:.leading,spacing:12){Image(systemName:"music.note.list").font(.largeTitle).foregroundStyle(SwayTheme.accent);Text("Dance to your music").font(.title2.bold());Text("Choose music, analyze its rhythm, then drive the same choreography timeline.").foregroundStyle(.secondary);NavigationLink { SwayMusicCoreView() } label:{Label("CHOOSE MUSIC",systemImage:"music.note").frame(maxWidth:.infinity,minHeight:48)}.buttonStyle(.borderedProminent).tint(SwayTheme.accent)} }
            }
        }.padding(18).frame(maxWidth:1000).frame(maxWidth:.infinity,alignment:.top)}
        .background(SwayTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onChange(of: music.beatComplexity) { music.refreshOfflineBeatIfPlaying() }
        .onChange(of: music.beatIntensity) { music.refreshOfflineBeatIfPlaying() }
        .navigationDestination(isPresented:$play){WorkoutPlayerView(steps:workout,minutes:15,music:music)}
    }
}

struct SwayDrummerPad: View {
    @Binding var complexity:Double
    @Binding var intensity:Double
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius:18).fill(SwayTheme.surfaceStrong)
                Path { p in let w=geo.size.width,h=geo.size.height; p.move(to:.init(x:w/2,y:0));p.addLine(to:.init(x:w/2,y:h));p.move(to:.init(x:0,y:h/2));p.addLine(to:.init(x:w,y:h/2)) }.stroke(Color.white.opacity(0.10),lineWidth:1)
                Text("ENERGETIC").font(.caption2.bold()).foregroundStyle(.secondary).position(x:geo.size.width/2,y:13)
                Text("GENTLE").font(.caption2.bold()).foregroundStyle(.secondary).position(x:geo.size.width/2,y:geo.size.height-13)
                Circle().fill(SwayTheme.accent).overlay(Circle().stroke(Color.white.opacity(0.8),lineWidth:2)).frame(width:30,height:30)
                    .position(x:CGFloat(complexity)*geo.size.width,y:CGFloat(1-intensity)*geo.size.height)
            }.contentShape(Rectangle()).gesture(DragGesture(minimumDistance:0).onChanged { v in complexity=max(0,min(1,Double(v.location.x/geo.size.width))); intensity=max(0,min(1,1-Double(v.location.y/geo.size.height))) })
        }.frame(height:190).accessibilityElement(children:.ignore).accessibilityLabel("Beat feel").accessibilityValue("Complexity \(Int(complexity*100)) percent, energy \(Int(intensity*100)) percent")
    }
}
