import SwiftUI

struct CreateMoveView: View {
    @EnvironmentObject var store:SwayStore
    enum Mode:String,CaseIterable,Identifiable { case move="Move", combination="Combination", routine="Routine"; var id:String{rawValue} }
    @State private var mode:Mode = .move
    @State private var name=""
    @State private var style="My Style"
    @State private var difficulty=1
    @State private var baseMoveID="step-touch"
    @State private var selected:[String]=[]
    @State private var saved=false
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                Text("Create").font(.largeTitle.bold())
                Text("Build a move, combination or routine you can practise, export and share.").foregroundStyle(.secondary)
                Picker("Creation type",selection:$mode){ForEach(Mode.allCases){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented)
                if mode == .move {
                    ZStack {
                        SwayTheme.stageGradient
                        SWAYCharacterStage(character: .lucia, source: .move(id: baseMoveID, musicalTime: 0.65, bpm: 105, paused: true), profile: nil, mirrored: false)
                            .padding(.vertical,12)
                    }.frame(height:270).clipShape(RoundedRectangle(cornerRadius:26))
                    Text("Preview uses the same articulated movement system as Learn and Workout.").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment:.leading,spacing:14) {
                    Text(mode.rawValue.uppercased()).font(.caption.bold()).foregroundStyle(SwayTheme.cyan)
                    TextField("Name",text:$name).textFieldStyle(.plain).padding(14).background(SwayTheme.surfaceStrong,in:RoundedRectangle(cornerRadius:14))
                    if mode == .move {
                        TextField("Dance style",text:$style).textFieldStyle(.plain).padding(14).background(SwayTheme.surfaceStrong,in:RoundedRectangle(cornerRadius:14))
                        Picker("Movement foundation",selection:$baseMoveID) {
                            ForEach(store.moves.filter { SwayCoachPoseEngine.supports(moveID:$0.id) }) { move in Text(move.name).tag(move.id) }
                        }
                        Text("Alpha Move creation remixes an authored movement foundation so every saved Move can be previewed, practised and shared.").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(18).background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:22))
                if mode == .move {
                    VStack(alignment:.leading,spacing:12) {
                        Text("DIFFICULTY").font(.caption.bold()).foregroundStyle(SwayTheme.cyan)
                        HStack(spacing:10){ForEach(1...3,id:\.self){level in Button {difficulty=level} label:{Text(["Easy","Medium","Hard"][level-1]).font(.subheadline.bold()).frame(maxWidth:.infinity,minHeight:44).background(difficulty==level ? SwayTheme.accent:SwayTheme.surfaceStrong,in:RoundedRectangle(cornerRadius:14))}.buttonStyle(.plain)}}
                    }.padding(18).background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:22))
                } else {
                    VStack(alignment:.leading,spacing:10){
                        Text("MOVES").font(.caption.bold()).foregroundStyle(SwayTheme.cyan)
                        Text("Tap moves in the order you want them performed.").font(.caption).foregroundStyle(.secondary)
                        ForEach(store.moves){ move in
                            Button { selected.append(move.id) } label:{ HStack{Text(move.name);Spacer();Text("\(selected.filter{$0==move.id}.count)×").foregroundStyle(SwayTheme.cyan)}.frame(minHeight:44) }.buttonStyle(.plain)
                        }
                        if !selected.isEmpty { Button("Remove last",role:.destructive){_ = selected.popLast()} }
                    }.padding(18).background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:22))
                }
                Button { save() } label:{Label("SAVE \(mode.rawValue.uppercased())",systemImage:"checkmark.circle.fill").frame(maxWidth:.infinity,minHeight:54)}.buttonStyle(SwayPrimaryButtonStyle()).disabled(name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || (mode != .move && selected.isEmpty))
                if !store.creations.isEmpty {
                    VStack(alignment:.leading,spacing:8){
                        Text("MY COMBINATIONS & ROUTINES").font(.caption.bold()).foregroundStyle(SwayTheme.cyan)
                        ForEach(store.creations){ item in
                            NavigationLink { SwayCreationPracticeView(creation:item) } label:{
                                HStack { VStack(alignment:.leading,spacing:3){Text(item.name).font(.headline);Text("\(item.kind.rawValue) · \(item.moveIDs.count) moves").font(.caption).foregroundStyle(.secondary)};Spacer();Image(systemName:"play.circle.fill").font(.title2).foregroundStyle(SwayTheme.accent) }.frame(minHeight:52)
                            }.buttonStyle(.plain)
                        }
                    }.padding(18).background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:22))
                }
            }.padding(18)
        }.background(SwayTheme.background.ignoresSafeArea()).navigationTitle("Create").navigationBarTitleDisplayMode(.inline).preferredColorScheme(.dark)
        .alert("Saved",isPresented:$saved){Button("OK",role:.cancel){}}
    }
    private func save(){ let clean=name.trimmingCharacters(in:.whitespacesAndNewlines); guard !clean.isEmpty else{return}; if mode == .move { store.addMove(name:clean,style:style,difficulty:difficulty,basedOn:baseMoveID) } else { store.addCreation(name:clean,kind:mode == .combination ? .combination:.routine,moveIDs:selected) }; name=""; selected=[]; saved=true }
}


struct SwayCreationPracticeView: View {
    @EnvironmentObject private var store:SwayStore
    @StateObject private var music=SwayMusicEngine()
    let creation:SwayCreation
    private var steps:[WorkoutStep] {
        creation.moveIDs.compactMap { id in store.moves.first(where:{$0.id==id}).map { WorkoutStep(move:$0,counts:$0.counts) } }
    }
    var body:some View {
        Group {
            if steps.isEmpty { ContentUnavailableView("Moves unavailable",systemImage:"exclamationmark.triangle",description:Text("This creation references moves that are not currently installed.")) }
            else {
                VStack(spacing:18) {
                    Text(creation.name).font(.largeTitle.bold())
                    Text("\(creation.kind.rawValue) · \(steps.count) moves").foregroundStyle(.secondary)
                    SWAYCharacterStage(character: .lucia, source: .move(id: steps[0].move.id, musicalTime: 0.6, bpm: 100, paused: true), profile: nil, mirrored: store.mirrored).frame(height:320)
                    NavigationLink { WorkoutPlayerView(steps:steps,minutes:max(3,Int(ceil(Double(steps.count)*8.0/100.0))),music:music) } label:{ Label("PRACTICE",systemImage:"play.fill").frame(maxWidth:.infinity,minHeight:52) }.buttonStyle(SwayPrimaryButtonStyle())
                    Text("Practice uses the same articulated choreography and workout timeline as the rest of SWAY.").font(.caption).foregroundStyle(.secondary)
                }.padding(18)
            }
        }.background(SwayTheme.background.ignoresSafeArea()).preferredColorScheme(.dark).navigationTitle("Practice").navigationBarTitleDisplayMode(.inline)
    }
}
