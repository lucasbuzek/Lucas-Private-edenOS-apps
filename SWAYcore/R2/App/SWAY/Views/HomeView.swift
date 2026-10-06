import SwiftUI
import MediaPlayer
import AVFoundation

struct HomeView: View {
    @EnvironmentObject var store:SwayStore
    @StateObject private var music=SwayMusicEngine()
    @State private var minutes=15
    @State private var workout:[WorkoutStep]=[]
    @State private var play=false
    @State private var showMusicPicker=false
    @State private var showPlaylistPicker=false

    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack(alignment:.top) {
                    VStack(alignment:.leading,spacing:2) {
                        Text("SWAY").font(.system(size:34,weight:.heavy,design:.rounded)).tracking(-1)
                        Text("DANCE • MOVE • FEEL GOOD").font(.caption2.bold()).tracking(1.2).foregroundStyle(.white.opacity(0.58))
                    }
                    Spacer()
                    NavigationLink { SettingsView() } label:{ Image(systemName:"person.crop.circle.fill").font(.title).frame(width:44,height:44).foregroundStyle(.white) }
                }
                workoutHero
                HStack { Text("Your Progress").font(.headline); Spacer(); NavigationLink("Details") { ProgressViewScreen() }.font(.caption.bold()).foregroundStyle(SwayTheme.cyan) }
                HStack(spacing:9) {
                    metric("flame.fill","\(store.sessionsCompleted)","Workouts",.orange)
                    metric("star.fill","\(store.learned.count)","Moves",.green)
                    metric("clock.fill","\(store.totalMinutes)","Minutes",.cyan)
                }
                Text("Quick Start").font(.headline)
                HStack(spacing:9) {
                    NavigationLink { SwayFitnessSetupView() } label:{ quickLabel("Workout","play.circle.fill") }.buttonStyle(.plain)
                    NavigationLink { MoveLibraryView() } label:{ quickLabel("Learn","graduationcap.fill") }.buttonStyle(.plain)
                    NavigationLink { CreateMoveView() } label:{ quickLabel("Create","plus.circle.fill") }.buttonStyle(.plain)
                }
                musicChoices
                HStack { Text("Latest Moves").font(.headline); Spacer(); NavigationLink("See All") { MoveLibraryView() }.font(.caption.bold()).foregroundStyle(SwayTheme.cyan) }
                HStack(spacing:8) {
                    ForEach(Array(featuredMoves.enumerated()),id:\.element.id) { index,move in
                        NavigationLink { SwayMoveDetailView(move:move) } label:{
                            VStack(spacing:4) {
                                SWAYCoachAvatarView(moveID:move.id,musicalTime:previewTime(for:move.id,index:index),bpm:100,paused:true,mirrored:false)
                                    .frame(height:96)
                                Text(move.name).font(.caption2.bold()).lineLimit(1)
                            }.frame(maxWidth:.infinity).padding(6).background(Color.white.opacity(0.06),in:RoundedRectangle(cornerRadius:14))
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(.horizontal,16).padding(.top,10).padding(.bottom,18)
                .frame(maxWidth:1040).frame(maxWidth:.infinity,alignment:.top)
        }
        .background(SwayTheme.background.ignoresSafeArea()).toolbar(.hidden,for:.navigationBar).preferredColorScheme(.dark)
        .sheet(isPresented:$showMusicPicker){ SWAYMediaPicker(music:music) }
        .sheet(isPresented:$showPlaylistPicker){ SwayPlaylistPicker(music:music,playbackMode:.automatic) }
        .navigationDestination(isPresented:$play){ WorkoutPlayerView(steps:workout,minutes:minutes,music:music) }
    }

    private var workoutHero: some View {
        ZStack(alignment:.leading) {
            SwayTheme.stageGradient
            HStack { Spacer(); SWAYAvatarStageView(role:.coach,moveID:"step-touch",elapsed:0.6,bpm:100,paused:true,mirrored:false,cutout:AnyView(SWAYSkeletal2DAvatarView(role:.coach,moveID:"step-touch",musicalTime:0.6,bpm:100,paused:true,mirrored:false))).frame(width:190,height:230).padding(.trailing,8) }
            VStack(alignment:.leading,spacing:6) {
                Text("LET'S DANCE").font(.system(size:28,weight:.heavy,design:.rounded))
                Text("Foundation Flow • 15 min").font(.caption.bold()).foregroundStyle(.white.opacity(0.72))
                NavigationLink { SwayFitnessSetupView() } label:{ Label("START DANCING",systemImage:"play.fill").font(.headline.bold()).frame(minWidth:150,minHeight:48) }.buttonStyle(.borderedProminent).tint(SwayTheme.accent)
            }.padding(18)
        }.frame(height:230).clipShape(RoundedRectangle(cornerRadius:25,style:.continuous))
    }

    private var musicChoices: some View {
        VStack(alignment:.leading,spacing:9) {
            HStack { Text("Dance to").font(.headline); Spacer(); NavigationLink("Music Studio") { SwayMusicCoreView() }.font(.caption.bold()).foregroundStyle(SwayTheme.cyan) }
            HStack(spacing:8) {
                musicChoice("Playlist","music.note.list") { Task { if await music.requestLibraryAccess(){ showPlaylistPicker=true } } }
                musicChoice("Song","music.note") { Task { if await music.requestLibraryAccess(){ showMusicPicker=true } } }
                musicChoice("SWAY Beats","waveform") { music.useOfflineBeat(style:music.beatStyle) }
            }
        }
    }
    private func musicChoice(_ title:String,_ icon:String,action:@escaping()->Void)->some View { Button(action:action){ VStack(spacing:6){Image(systemName:icon).font(.title3);Text(title).font(.caption2.bold()).lineLimit(1)}.frame(maxWidth:.infinity).padding(.vertical,12).background(Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:14)) }.buttonStyle(.plain) }
    private var featuredMoves:[DanceMove] { Array(store.moves.prefix(3)) }
    private func previewTime(for moveID:String,index:Int)->Double {
        switch moveID.lowercased() {
        case "march": return 0.30
        case "step-touch", "double-step", "side-tap": return 0.62
        case "hip-sway": return 0.92
        case "heel-dig": return 0.34
        case "knee": return 0.32
        case "grapevine": return 1.15
        case "arm-reach": return 0.34
        case "v-step": return 1.10
        default: return 0.25 + Double(index) * 0.31
        }
    }
    private func metric(_ icon:String,_ value:String,_ label:String,_ color:Color)->some View { VStack(spacing:4){Image(systemName:icon).foregroundStyle(color);Text(value).font(.headline.bold());Text(label).font(.system(size:10)).foregroundStyle(.secondary).lineLimit(1)}.frame(maxWidth:.infinity).padding(.vertical,11).background(Color.white.opacity(0.06),in:RoundedRectangle(cornerRadius:14)) }
    private func quickLabel(_ title:String,_ icon:String)->some View { VStack(spacing:6){Image(systemName:icon).font(.title3);Text(title).font(.caption.bold())}.foregroundStyle(.white).frame(maxWidth:.infinity).padding(.vertical,13).background(Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:14)) }
    private func startDance(){ if !music.usingLibraryTrack { music.setOfflineTempo(100) }; workout=store.generate(minutes:minutes,difficulty:store.moveComplexity,lowImpact:store.lowImpact,smallSpace:store.smallSpace); play=true }
}

struct SwayBeatsQuickView: View {
    @ObservedObject var music:SwayMusicEngine
    @Environment(\.dismiss) private var dismiss
    let start:()->Void
    var body: some View {
        NavigationStack {
            VStack(spacing:22) {
                Image(systemName:"waveform.circle.fill").font(.system(size:72)).foregroundStyle(SwayTheme.accent)
                Text("SWAY Beats").font(.largeTitle.bold())
                Text("Built-in rhythm. No music library, camera, or network required.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                Picker("Beat style",selection:$music.beatStyle) { ForEach(SwayMusicEngine.BeatStyle.allCases){ Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                HStack { Text("Tempo"); Spacer(); Text("\(Int(music.bpm)) BPM").foregroundStyle(SwayTheme.cyan) }
                Slider(value:$music.bpm,in:70...150,step:1)
                Button { music.useOfflineBeat(style:music.beatStyle); start() } label:{ Label("Dance with SWAY Beats",systemImage:"figure.dance").font(.headline).frame(maxWidth:.infinity,minHeight:54) }.buttonStyle(.borderedProminent).tint(SwayTheme.accent)
                NavigationLink("Open Beat Studio") { SwayMusicCoreView() }.foregroundStyle(SwayTheme.cyan)
                Spacer()
            }.padding(24).background(SwayTheme.background.ignoresSafeArea()).navigationTitle("SWAY Beats").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.topBarTrailing){Button("Done"){dismiss()}} }
        }.preferredColorScheme(.dark)
    }
}


struct SWAYMediaPicker: UIViewControllerRepresentable {
    @ObservedObject var music: SwayMusicEngine
    var allowsMultipleItems: Bool = false
    var prompt: String = "Choose music for SWAY"
    var playbackMode: SwayMusicPlaybackMode = .inOrder
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent:self) }

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes:.music)
        picker.allowsPickingMultipleItems = allowsMultipleItems
        picker.showsCloudItems = true
        picker.showsItemsWithProtectedAssets = true
        picker.prompt = prompt
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let parent: SWAYMediaPicker
        init(parent: SWAYMediaPicker) { self.parent = parent }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            Task { @MainActor in
                parent.music.useLibraryItems(mediaItemCollection)
                if parent.allowsMultipleItems { parent.music.setPlaybackMode(parent.playbackMode) }
                parent.dismiss()
            }
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            Task { @MainActor in
                parent.dismiss()
            }
        }
    }
}


struct SwayMusicCoreView: View {
    @StateObject private var data=SwayMusicDataStore()
    @StateObject private var apple=SwayMusicKitProvider()
    @StateObject private var local=SwayLocalAudioPlayer()
    @StateObject private var drummer=SwayDrummerEngine()
    @State private var importingFile=false
    @State private var query=""
    @State private var status=""
    @State private var analysis:SwayBeatGrid?
    @StateObject private var beatPreview=SwayMusicEngine()

    var body: some View {
        List {
            Section("Apple Music") {
                HStack {
                    TextField("Search Apple Music",text:$query)
                    Button("Search"){ Task { await searchApple() } }
                }
                if apple.authorization == .notDetermined {
                    Button("Allow Apple Music"){ Task { await apple.requestAuthorization() } }
                } else if apple.authorization == .denied || apple.authorization == .restricted {
                    Text("Apple Music access is off for SWAYcore on this device.").font(.caption).foregroundStyle(.secondary)
                    Button("Open Settings to Allow Apple Music") {
                        if let url=URL(string:UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
                ForEach(apple.results,id:\.id) { song in
                    Button {
                        Task { try? await apple.play(song) }
                    } label: {
                        VStack(alignment:.leading){ Text(song.title); Text(song.artistName).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            Section("Files / Local Audio") {
                Button { importingFile=true } label:{ Label("Choose Audio File",systemImage:"folder") }
                if !local.title.isEmpty {
                    LabeledContent("Track",value:local.title)
                    HStack {
                        Button(local.isPlaying ? "Pause":"Play") {
                            if local.isPlaying { local.pause() } else { try? local.play() }
                        }
                        Button("Analyze") { analyzeLocalFile() }
                    }
                }
            }
            Section("SWAY Beats") {
                Picker("Style",selection:$data.beatConfiguration.style) {
                    ForEach(SwayBeatStyle.allCases){Text($0.rawValue).tag($0)}
                }
                Slider(value:$data.beatConfiguration.bpm,in:60...180,step:1)
                LabeledContent("Tempo",value:"\(Int(data.beatConfiguration.bpm)) BPM")
                Button(beatPreview.isPlaying ? "Stop Beat Preview":"Preview SWAY Beat") {
                    if beatPreview.isPlaying { beatPreview.pause() } else {
                        beatPreview.beatStyle = beatStyle(for:data.beatConfiguration.style)
                        beatPreview.bpm = data.beatConfiguration.bpm
                        beatPreview.useOfflineBeat(style:beatPreview.beatStyle)
                        beatPreview.bpm = data.beatConfiguration.bpm
                        beatPreview.play()
                    }
                }
                Text("SWAY generates distinct kick, snare, hat and percussion transients locally; no external sound bank is required.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Rhythm") {
                if let analysis {
                    LabeledContent("Tempo",value:"\(Int(analysis.bpm.rounded())) BPM")
                    LabeledContent("Confidence",value:"\(Int(analysis.confidence * 100))%")
                    LabeledContent("Detected beats",value:"\(analysis.beats.count)")
                } else {
                    Text("Choose a local track and analyze it to build a SWAY rhythm map.").font(.caption).foregroundStyle(.secondary)
                }
                DisclosureGroup("Advanced mixer") {
                    mixer("Master",value:$data.mix.master); mixer("Music",value:$data.mix.music)
                    mixer("SWAY Beats",value:$data.mix.beats); mixer("Count",value:$data.mix.count); mixer("Coach",value:$data.mix.coach)
                }
            }
            Section("Dance Playlists") {
                Button("New Workout Playlist"){ _=data.createPlaylist(name:"My SWAY Playlist") }
                ForEach(data.playlists){p in LabeledContent(p.name,value:"\(p.entries.count) tracks")}
            }
            if !status.isEmpty { Section("Status"){Text(status).font(.footnote)} }
        }
        .navigationTitle("Music")
        .scrollContentBackground(.hidden).background(SwayTheme.background)
        .tint(SwayTheme.cyan).preferredColorScheme(.dark)
        .onAppear{ apple.refreshAuthorization() }
        .onDisappear{data.save()}
        .fileImporter(isPresented:$importingFile,allowedContentTypes:[.audio],allowsMultipleSelection:false) { result in
            do {
                let urls = try result.get()
                guard let url = urls.first else {
                    status = "No audio file selected"
                    return
                }
                try local.load(url)
                status="Loaded \(local.title)"
            } catch { status=error.localizedDescription }
        }
    }

    private func analyzeLocalFile() {
        guard let url=local.loadedURL else { status="Choose a local audio file first"; return }
        status="Analyzing…"
        Task.detached(priority:.userInitiated) {
            do {
                let (samples,rate)=try SwayAudioAnalyzer.readMonoSamples(url:url)
                let grid=SwayAudioAnalyzer.analyze(samples:samples,sampleRate:rate)
                await MainActor.run {
                    analysis=grid
                    status = grid == nil ? "No reliable beat grid detected" : "Beat analysis complete"
                }
            } catch {
                await MainActor.run { status="Analysis failed: \(error.localizedDescription)" }
            }
        }
    }

    private func beatStyle(for style:SwayBeatStyle)->SwayMusicEngine.BeatStyle {
        switch style {
        case .simple, .pop: return .basic
        case .house: return .house
        case .hipHop: return .hipHop
        case .disco: return .disco
        case .latin: return .latin
        case .afro, .percussion: return .afro
        case .rock: return .hipHop
        case .minimal: return .minimal
        }
    }

    private func searchApple() async {
        if apple.authorization != .authorized { await apple.requestAuthorization() }
        do { try await apple.search(query); status="" } catch {
            let detail=error.localizedDescription
            status = "Apple Music: \(detail)"
        }
    }
    @ViewBuilder private func mixer(_ name:String,value:Binding<Double>)->some View {
        VStack(alignment:.leading){Text(name);Slider(value:value,in:0...1)}
    }
}


struct SwayPacksView:View {
    @StateObject private var packs=SwayPackStore()
    @State private var importing=false
    @State private var shareURL:URL?
    @State private var message=""

    var body:some View {
        List {
            Section {
                Picker("Dance mode",selection:$packs.state.selectedMode) {
                    ForEach(SwayDanceMode.allCases){Text($0.rawValue).tag($0)}
                }
            }
            Section("Installed Test Packs") {
                ForEach(packs.available) { pack in
                    VStack(alignment:.leading,spacing:8) {
                        HStack {
                            VStack(alignment:.leading) {
                                Text(pack.manifest.name).font(.headline)
                                Text(pack.manifest.primaryStyle.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(pack.manifest.entitlement.rawValue)
                                .font(.caption2.bold()).padding(.horizontal,8).padding(.vertical,4)
                                .background(SwayTheme.surfaceStrong,in:Capsule())
                        }
                        if !pack.manifest.equipment.isEmpty {
                            ForEach(pack.manifest.equipment,id:\.id) { req in
                                Label(req.name,systemImage:"exclamationmark.shield")
                                    .font(.caption)
                                if let note=req.safetyNote {Text(note).font(.caption2).foregroundStyle(.secondary)}
                            }
                        }
                        HStack {
                            Button("Use"){packs.state.selectedStyle=pack.manifest.primaryStyle;packs.save();message="Selected \(pack.manifest.name)"}
                            if pack.manifest.redistributable {
                                Button("Share") {
                                    do{shareURL=try packs.exportURL(for:pack)}catch{message=error.localizedDescription}
                                }
                            }
                        }.buttonStyle(.bordered)
                    }.padding(.vertical,4)
                }
            }
            Section("Friends / Files") {
                Button { importing=true } label:{Label("Import .swaypack",systemImage:"square.and.arrow.down")}
                if let shareURL { ShareLink(item:shareURL){Label("Share selected pack",systemImage:"square.and.arrow.up")} }
                Text("Test packs share choreography/content metadata only. Referenced music remains with its music provider.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !message.isEmpty {Section{Text(message).font(.footnote)}}
        }
        .navigationTitle("Dance Packs")
        .tint(SwayTheme.cyan).preferredColorScheme(.dark)
        .fileImporter(isPresented:$importing,allowedContentTypes:[.data,.json]) { result in
            do {
                let u=try result.get(); try packs.importPack(from:u); message="Pack imported"
            } catch {message=error.localizedDescription}
        }
    }
}


// MARK: - Shared Sessions
struct SwaySharedSessionsView: View {
    @EnvironmentObject private var shared:SwaySharedSessionCoordinator
    @State private var requestedCapacity = 2
    @State private var guestName = "Guest"

    var body: some View {
        List {
            Section {
                VStack(alignment:.leading,spacing:8) {
                    Label("Dance Together",systemImage:"person.2.fill")
                        .font(.title2.bold())
                    Text("One SWAY profile per device. Dance Together supports 2 people; Household supports up to 6 independent devices.")
                        .foregroundStyle(.secondary)
                    Text("Camera video and continuous pose data stay on each participant's own device.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical,6)
            }

            if let session=shared.activeSession {
                Section("Session") {
                    LabeledContent("Tier",value:session.tier.rawValue)
                    LabeledContent("Transport",value:session.transport.rawValue)
                    LabeledContent("Participants",value:"\\(session.participantCount)")
                    ForEach(session.participants) { participant in
                        HStack {
                            Image(systemName:participant.role == .host ? "crown.fill":"person.fill")
                            VStack(alignment:.leading) {
                                Text(participant.displayName)
                                Text(participant.presence.rawValue.capitalized)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(participant.role.rawValue.capitalized)
                                .font(.caption)
                        }
                    }
                    if let limit=session.tier.includedParticipantLimit, session.participantCount < limit {
                        Button("Add participant") { _=shared.addParticipant(displayName:guestName) }
                    }
                    Button("End Session",role:.destructive) { shared.endSession() }
                }
            } else {
                Section("Dance Together / Household") {
                    Text("2 participants for Dance Together; up to 6 independent devices for a household session.")
                    HStack {
                        Button("2 People") { shared.createSession(hostName:"Me",requestedCapacity:2) }
                        Button("Household 6") { shared.createSession(hostName:"Me",requestedCapacity:6) }
                    }.buttonStyle(.borderedProminent)
                }

                Section("SWAY Master") {
                    Text("For instructors, studios and classes. The host holds the Master subscription; ordinary SWAY participants can join.")
                        .foregroundStyle(.secondary)
                    Stepper("Class capacity: \(requestedCapacity)",value:$requestedCapacity,in:3...100)
                    Button("Create Master Test Session") {
                        shared.createSession(hostName:"Instructor",requestedCapacity:requestedCapacity)
                    }
                    .disabled(!shared.masterUnlockedForTesting)
                    Text("Private build: Master entitlement is unlocked for testing. Public builds will verify the host subscription through StoreKit.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Transport") {
                Picker("Preferred transport",selection:$shared.preferredTransport) {
                    ForEach(SwaySharedSessionTransport.allCases,id:\.self) { transport in
                        Text(transport.rawValue).tag(transport)
                    }
                }
                Text("This build implements the scalable session contract, capacity/entitlement rules and local coordinator. Nearby/SharePlay/hosted networking adapters are separate transport implementations and are not falsely reported as connected here.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Status") { Text(shared.statusMessage) }
        }
        .navigationTitle("Shared Sessions")
        .preferredColorScheme(.dark)
    }
}


// MARK: - Fitness-first music selection
enum SwayMusicPlaybackMode: String, CaseIterable, Identifiable {
    case automatic = "Automatic", inOrder = "In Order", shuffle = "Shuffle"
    var id:String { rawValue }
}

enum SwayMusicSelectionMode: String, CaseIterable, Identifiable {
    case playlist = "Playlist"
    case song = "Song"
    case swayBeats = "SWAY Beats"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .playlist: return "music.note.list"
        case .song: return "music.note"
        case .swayBeats: return "metronome"
        }
    }
}

struct SwayFitnessSetupView: View {
    @EnvironmentObject private var store: SwayStore
    @StateObject private var music = SwayMusicEngine()
    @State private var duration = 20
    @State private var intensity = 2
    @State private var musicMode: SwayMusicSelectionMode = .playlist
    @State private var lowImpact = false
    @State private var adaptive = true
    @State private var showMusicPicker = false
    @State private var showPlaylistPicker = false
    @State private var playbackMode: SwayMusicPlaybackMode = .automatic
    @State private var useTracking = false

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                VStack(alignment:.leading,spacing:5) {
                    Text("YOUR WORKOUT").font(.caption.bold()).foregroundStyle(SwayTheme.cyan)
                    Text("Ready to move?").font(.largeTitle.bold())
                    Text("Set the workout. SWAY handles the dance.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment:.leading,spacing:14) {
                    Text("Duration").font(.headline)
                    HStack {
                        ForEach([10,20,30,45],id:\.self) { value in
                            Button("\(value) min") { duration=value }
                                .buttonStyle(.borderedProminent)
                                .tint(duration == value ? SwayTheme.cyan : .secondary.opacity(0.35))
                        }
                    }
                }

                VStack(alignment:.leading,spacing:12) {
                    Text("Music").font(.headline)
                    Picker("Music",selection:$musicMode) {
                        ForEach(SwayMusicSelectionMode.allCases) { mode in
                            Label(mode.rawValue,systemImage:mode.icon).tag(mode)
                        }
                    }.pickerStyle(.segmented)
                    switch musicMode {
                    case .playlist:
                        Button {
                            Task { if await music.requestLibraryAccess() { showPlaylistPicker = true } }
                        } label: {
                            Label(music.usingLibraryTrack ? music.trackTitle : "Choose a playlist",systemImage:"music.note.list")
                        }
                        .buttonStyle(.bordered)
                        Picker("Playback",selection:$playbackMode) {
                            ForEach(SwayMusicPlaybackMode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                    case .song:
                        Button {
                            showMusicPicker = true
                        } label: {
                            Label(music.usingLibraryTrack ? music.trackTitle : "Choose a song",systemImage:"music.note")
                        }
                        .buttonStyle(.bordered)
                    case .swayBeats:
                        ScrollView(.horizontal,showsIndicators:false) {
                            HStack {
                                ForEach(SwayMusicEngine.BeatStyle.allCases) { style in
                                    Button(style.rawValue) { music.useOfflineBeat(style:style) }
                                        .buttonStyle(.bordered)
                                        .tint(style == music.beatStyle ? SwayTheme.cyan : .secondary)
                                }
                            }
                        }
                        Text("\(music.beatStyle.rawValue) · \(Int(music.bpm)) BPM · works offline")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment:.leading,spacing:12) {
                    Text("Intensity").font(.headline)
                    Picker("Intensity",selection:$intensity) {
                        Text("Easy").tag(1); Text("Active").tag(2); Text("Push").tag(3)
                    }.pickerStyle(.segmented)
                    Toggle("Adaptive workout",isOn:$adaptive)
                    Toggle("Low impact",isOn:$lowImpact)
                        .onChange(of:lowImpact) { _,v in store.lowImpact=v; store.save() }
                    VStack(alignment:.leading,spacing:10) {
                        Text("Movement tracking").font(.headline)
                        HStack(spacing:10) {
                            Button { useTracking=true } label:{ VStack(spacing:8){Image(systemName:"camera.viewfinder").font(.title2);Text("Camera Tracking").font(.subheadline.bold());Text("Real-time feedback").font(.caption2).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,minHeight:96).background(useTracking ? SwayTheme.accent.opacity(0.22):SwayTheme.surfaceStrong,in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(useTracking ? SwayTheme.accent:Color.white.opacity(0.08),lineWidth:1.5)) }.buttonStyle(.plain)
                            Button { useTracking=false } label:{ VStack(spacing:8){Image(systemName:"figure.dance").font(.title2);Text("Follow Along").font(.subheadline.bold());Text("No camera needed").font(.caption2).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,minHeight:96).background(!useTracking ? SwayTheme.accent.opacity(0.22):SwayTheme.surfaceStrong,in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(!useTracking ? SwayTheme.accent:Color.white.opacity(0.08),lineWidth:1.5)) }.buttonStyle(.plain)
                        }
                        if useTracking {
                            Text("Tracking starts inside your workout. COACH and YOU stay together on one stage.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                NavigationLink {
                    let workout = store.generate(minutes:duration,difficulty:intensity,lowImpact:lowImpact,smallSpace:store.smallSpace)
                    WorkoutPlayerView(steps:workout,minutes:duration,music:music,startWithTracking:useTracking)
                } label: {
                    Label("DANCE",systemImage:useTracking ? "camera.viewfinder":"figure.dance")
                        .font(.title3.bold())
                        .frame(maxWidth:.infinity).padding(.vertical,8)
                }
                .buttonStyle(.borderedProminent)
                .tint(SwayTheme.accent)

                Text("Follow-Along is the standard workout. Movement tracking is optional and can add YOU, matching, combo and score when you choose it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Dance")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear { lowImpact=store.lowImpact; intensity=store.intensity }
        .onChange(of:intensity) { _,v in store.intensity=v; store.save() }
        .onChange(of:musicMode) { _, mode in
            if mode == .swayBeats { music.useOfflineBeat(style:music.beatStyle) }
        }
        .onChange(of:playbackMode) { _, mode in
            music.setPlaybackMode(mode)
        }
        .sheet(isPresented:$showMusicPicker) {
            SWAYMediaPicker(music:music,
                            allowsMultipleItems:false,
                            prompt:"Choose one song for SWAY",
                            playbackMode:playbackMode)
        }
        .sheet(isPresented:$showPlaylistPicker) { SwayPlaylistPicker(music:music,playbackMode:playbackMode) }
    }
}

struct SwayPlaylistPicker: View {
    @ObservedObject var music:SwayMusicEngine
    var playbackMode:SwayMusicPlaybackMode = .automatic
    @Environment(\.dismiss) private var dismiss
    private var playlists:[MPMediaItemCollection] { MPMediaQuery.playlists().collections ?? [] }
    var body: some View {
        NavigationStack {
            List {
                if playlists.isEmpty {
                    ContentUnavailableView("No playlists found",systemImage:"music.note.list",description:Text("Create a playlist in Music, or choose Song instead."))
                } else {
                    ForEach(playlists.indices, id: \.self) { index in
                        let list = playlists[index]
                        Button {
                            music.useLibraryItems(list); music.setPlaybackMode(playbackMode); dismiss()
                        } label: {
                            VStack(alignment:.leading,spacing:3) {
                                Text((list as? MPMediaPlaylist)?.name ?? "Playlist")
                                Text("\(list.count) songs").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }.navigationTitle("Choose Playlist")
             .toolbar { ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}} }
        }
    }
}
