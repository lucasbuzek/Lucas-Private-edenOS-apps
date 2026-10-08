import SwiftUI

struct MoveLibraryView: View {
    @EnvironmentObject var store:SwayStore
    @State private var query=""
    @State private var filter="All"
    private let filters=["All","Beginner","Intermediate","Advanced"]
    private var visible: [DanceMove] { store.moves.filter { matchesQuery($0) && matchesFilter($0) } }
    private func matchesQuery(_ move: DanceMove) -> Bool { query.isEmpty || move.name.localizedCaseInsensitiveContains(query) || move.style.localizedCaseInsensitiveContains(query) }
    private func matchesFilter(_ move: DanceMove) -> Bool {
        switch filter { case "Beginner": return move.difficulty <= 2; case "Intermediate": return move.difficulty == 3; case "Advanced": return move.difficulty >= 4; default: return true }
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack(alignment:.center) {
                    VStack(alignment:.leading,spacing:3) {
                        Text("Moves").font(.largeTitle.bold())
                        Text("\(visible.count) moves · tap one to learn it").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Menu {
                        ForEach(filters,id:\.self) { f in Button(f){filter=f} }
                    } label: {
                        Label(filter,systemImage:"line.3.horizontal.decrease.circle.fill")
                            .font(.subheadline.bold()).padding(.horizontal,12).frame(minHeight:44)
                            .background(SwayTheme.surfaceStrong,in:Capsule())
                    }
                }
                HStack(spacing:8) {
                    Image(systemName:"magnifyingglass").foregroundStyle(.secondary)
                    TextField("Find a move",text:$query)
                }.padding(.horizontal,12).frame(minHeight:46).background(SwayTheme.surfaceStrong,in:RoundedRectangle(cornerRadius:14))
                LazyVGrid(columns:[GridItem(.adaptive(minimum:145),spacing:12)],spacing:12) {
                    ForEach(visible) { move in
                        NavigationLink { SwayMoveDetailView(move:move) } label: {
                            VStack(alignment:.leading,spacing:8) {
                                ZStack { SwayTheme.stageGradient; SWAYCoachAvatarView(moveID:move.id,musicalTime:0,bpm:Double(max(move.bpmMin,100)),paused:true,mirrored:false).padding(8) }
                                    .frame(height:145).clipShape(RoundedRectangle(cornerRadius:20))
                                Text(move.name).font(.headline).lineLimit(1)
                                HStack { Text(move.style).font(.caption).foregroundStyle(.secondary); Spacer(); Label("\(move.counts)",systemImage:"metronome").font(.caption.bold()).foregroundStyle(SwayTheme.cyan) }
                            }.padding(10).background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:22)).foregroundStyle(.white)
                        }.buttonStyle(.plain)
                    }
                }
            }.padding().frame(maxWidth:1120).frame(maxWidth:.infinity,alignment:.top)
        }.background(SwayTheme.background.ignoresSafeArea()).navigationTitle("Moves").navigationBarTitleDisplayMode(.inline).preferredColorScheme(.dark)
    }
}

struct SwayMoveDetailView:View {
    let move:DanceMove
    @StateObject private var music = SwayMusicEngine()
    @State private var practice=false
    @State private var selectedCount=1
    @State private var previewPlaying=false
    @State private var previewStart=Date()
    @State private var learningBPM:Double = 60
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var bpm:Double { max(20,min(180,learningBPM)) }
    private var countTotal:Int { max(1,move.counts) }
    private var secondsPerBeat:Double { 60.0 / bpm }
    private func difficultyName(_ level:Int)->String { level <= 1 ? "Starter" : (level <= 3 ? "Flow" : "Challenge") }
    private func elapsed(at date:Date)->TimeInterval {
        if previewPlaying && !reduceMotion { return max(0,date.timeIntervalSince(previewStart)) }
        return Double(selectedCount-1)*secondsPerBeat
    }
    private func select(_ value:Int) { selectedCount=min(countTotal,max(1,value)); previewPlaying=false }
    private func displayCount(at date:Date)->Int {
        guard previewPlaying && !reduceMotion else { return selectedCount }
        return (Int(floor(elapsed(at:date)/secondsPerBeat)) % countTotal) + 1
    }
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                VStack(alignment:.leading,spacing:6) { Text(move.name).font(.largeTitle.bold()); HStack { Text(move.style).font(.caption.bold()).padding(.horizontal,10).padding(.vertical,6).background(SwayTheme.violet.opacity(0.8),in:Capsule()); Text(difficultyName(move.difficulty)).font(.caption.bold()).padding(.horizontal,10).padding(.vertical,6).background(SwayTheme.surfaceStrong,in:Capsule()); Text("\(countTotal) counts").font(.caption.bold()).foregroundStyle(SwayTheme.cyan) } }
                TimelineView(.animation(minimumInterval:1.0/30.0,paused:!previewPlaying || reduceMotion)) { timeline in
                    ZStack(alignment:.topTrailing) {
                        SwayTheme.stageGradient
                        SWAYCoachAvatarView(moveID:move.id,musicalTime:elapsed(at:timeline.date),bpm:bpm,paused:!previewPlaying || reduceMotion,mirrored:false).padding(.horizontal,42).padding(.vertical,12)
                        Text("COUNT \(displayCount(at:timeline.date))")
                            .font(.caption.bold()).foregroundStyle(SwayTheme.cyan)
                            .padding(.horizontal,10).padding(.vertical,6)
                            .background(.black.opacity(0.55),in:Capsule()).padding(14)
                        HStack {
                            Button { select(selectedCount-1) } label:{ Image(systemName:"chevron.left").font(.title2.bold()).frame(width:52,height:52).background(.ultraThinMaterial,in:Circle()) }.disabled(selectedCount<=1)
                            Spacer()
                            Button { select(selectedCount+1) } label:{ Image(systemName:"chevron.right").font(.title2.bold()).frame(width:52,height:52).background(.ultraThinMaterial,in:Circle()) }.disabled(selectedCount>=countTotal)
                        }.padding(16).frame(maxHeight:.infinity,alignment:.center)
                    }.frame(height:390).clipShape(RoundedRectangle(cornerRadius:28))
                }
                HStack { Text("COUNT \(selectedCount) OF \(countTotal)").font(.caption.bold()).foregroundStyle(SwayTheme.cyan); Spacer(); Button { previewPlaying.toggle(); if previewPlaying { previewStart=Date().addingTimeInterval(-Double(selectedCount-1)*secondsPerBeat) } } label:{ Label(previewPlaying ? "Pause preview":"Play preview",systemImage:previewPlaying ? "pause.fill":"play.fill").frame(minHeight:44) }.buttonStyle(.bordered).disabled(reduceMotion) }
                SwayCard {
                    VStack(alignment:.leading,spacing:10) {
                        HStack {
                            VStack(alignment:.leading,spacing:2) {
                                Text("LEARNING TEMPO").font(.caption.bold()).foregroundStyle(.secondary)
                                Text("\(Int(bpm)) BPM").font(.title2.bold()).foregroundStyle(SwayTheme.cyan)
                            }
                            Spacer()
                            Button("Slow") { learningBPM = 40 }.buttonStyle(.bordered)
                            Button("Move tempo") { learningBPM = Double(max(20,move.bpmMin)) }.buttonStyle(.bordered)
                        }
                        Slider(value:$learningBPM,in:20...180,step:1)
                            .tint(SwayTheme.accent)
                            .accessibilityLabel("Learning tempo")
                            .accessibilityValue("\(Int(bpm)) beats per minute")
                        Text("Set the pace that is comfortable for you. Lucia, counts and practice use this same tempo.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                VStack(alignment:.leading,spacing:8) {
                    Text("COUNT BY COUNT").font(.caption.bold()).foregroundStyle(.secondary)
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack(spacing:10) {
                            ForEach(1...countTotal,id:\.self) { n in
                                Button { select(n) } label: {
                                    VStack(spacing:4) {
                                        ZStack {
                                            SwayTheme.stageGradient
                                            SWAYCoachAvatarView(moveID:move.id,musicalTime:Double(n-1)*secondsPerBeat,bpm:bpm,paused:true,mirrored:false).padding(4)
                                        }.frame(width:66,height:92).clipShape(RoundedRectangle(cornerRadius:12))
                                            .overlay(RoundedRectangle(cornerRadius:12).stroke(n == selectedCount ? SwayTheme.accent : Color.white.opacity(0.12),lineWidth:n == selectedCount ? 3:1))
                                        Text("\(n)").font(.caption.bold()).foregroundStyle(n == selectedCount ? SwayTheme.cyan : .white)
                                    }
                                }.buttonStyle(.plain).accessibilityLabel("Inspect count \(n)")
                            }
                        }
                    }
                }
                SwayCard { VStack(alignment:.leading,spacing:10) { Text("How to learn it").font(.headline); Label("Use the arrows or count buttons to inspect each beat.",systemImage:"hand.tap.fill"); Label("Play preview to see the complete movement on the beat.",systemImage:"play.circle.fill"); Label("Keep the movement comfortable; use low-impact options when needed.",systemImage:"figure.walk") }.font(.subheadline) }
                Button("Practice This Move") { music.setOfflineTempo(bpm); practice=true }.buttonStyle(SwayPinkButtonStyle())
            }.padding().frame(maxWidth:1000).frame(maxWidth:.infinity,alignment:.top)
        }.background(SwayTheme.background.ignoresSafeArea()).preferredColorScheme(.dark).navigationTitle("Learn").navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented:$practice) { WorkoutPlayerView(steps:[WorkoutStep(move:move,counts:move.counts)],minutes:3,music:music) }
        .onAppear { if learningBPM == 60 { learningBPM = Double(max(20,min(60,move.bpmMin))) } }
    }
}
