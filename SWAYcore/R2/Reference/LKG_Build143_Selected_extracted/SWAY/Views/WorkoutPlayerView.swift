import SwiftUI
import Vision

enum SwayCameraOverlayMode: String, CaseIterable {
    case coach, mirror, focus
    var label:String { switch self { case .coach: return "Coach"; case .mirror: return "Mirror"; case .focus: return "Focus" } }
    var next:SwayCameraOverlayMode { switch self { case .coach:return .mirror; case .mirror:return .focus; case .focus:return .coach } }
}

struct SwayGraphicalCoachView: View {
    let moveID:String
    let count:Int
    let waiting:Bool
    var body: some View {
        SwayHumanFigureView(moveID:moveID,elapsed:waiting ? 0:Double(max(0,count-1))*0.6,bpm:100,paused:true,mirrored:false,characterMode:true,skinTone:0,hairStyle:0,outfitStyle:0,appearancePreset:0,instructorPreset:0)
            .accessibilityLabel("Coach demonstrating \(moveID)")
    }
}

struct SwayUserSilhouetteView: View {
    let pose:SwayBodyPose
    let visible:Bool
    private let bones:[(VNHumanBodyPoseObservation.JointName,VNHumanBodyPoseObservation.JointName)] = [
        (.neck,.nose),(.neck,.leftShoulder),(.leftShoulder,.leftElbow),(.leftElbow,.leftWrist),
        (.neck,.rightShoulder),(.rightShoulder,.rightElbow),(.rightElbow,.rightWrist),
        (.neck,.root),(.root,.leftHip),(.leftHip,.leftKnee),(.leftKnee,.leftAnkle),
        (.root,.rightHip),(.rightHip,.rightKnee),(.rightKnee,.rightAnkle)
    ]
    var body:some View {
        GeometryReader { geo in
            Canvas { context,size in
                guard visible else{return}
                let map=pose.joints
                let usable=map.values.filter{$0.confidence >= 0.35}
                guard usable.count >= 6 else{return}
                let xs=usable.map{$0.point.x}, ys=usable.map{$0.point.y}
                guard let minX=xs.min(),let maxX=xs.max(),let minY=ys.min(),let maxY=ys.max() else{return}
                let w=max(0.12,maxX-minX), h=max(0.35,maxY-minY)
                let scale=min(0.78/w,0.82/h)
                let cx=(minX+maxX)/2, cy=(minY+maxY)/2
                func q(_ j:PoseJoint)->CGPoint {
                    let x=0.5+(j.point.x-cx)*scale
                    let y=0.52+(j.point.y-cy)*scale
                    return CGPoint(x:x*size.width,y:y*size.height)
                }
                for (a,b) in bones {
                    guard let aa=map[a],let bb=map[b],aa.confidence>=0.35,bb.confidence>=0.35 else{continue}
                    var path=Path(); path.move(to:q(aa)); path.addLine(to:q(bb))
                    context.stroke(path,with:.color(.cyan.opacity(0.46)),style:StrokeStyle(lineWidth:max(9,size.width*0.024),lineCap:.round,lineJoin:.round))
                }
                if let head=map[.nose], head.confidence>=0.35 {
                    let hp=q(head), r=max(14,size.width*0.042)
                    context.fill(Path(ellipseIn:CGRect(x:hp.x-r,y:hp.y-r,width:r*2,height:r*2)),with:.color(.cyan.opacity(0.34)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct WorkoutPlayerView: View {
    @EnvironmentObject var store:SwayStore
    @EnvironmentObject var session:SwaySessionController
    @StateObject private var health=SwayHealthWorkoutManager()
    @StateObject private var scoring=SwayScoringEngine()
    @StateObject private var playbackCoordinator=SwayPlaybackCoordinator()
    @StateObject private var pose=CameraPoseService()
    @StateObject private var shazam=SwayShazamProvider()
    @StateObject private var cues=SwayCueEngine()
    let steps:[WorkoutStep]
    let minutes:Int
    @ObservedObject var music:SwayMusicEngine
    var startWithTracking:Bool = false
    @StateObject private var timeline=SwayTimelineEngine()
    @State private var index=0
    @State private var performedMoves=0
    @State private var combo=0
    @State private var paused=false
    @State private var countdown=3
    @State private var started=false
    @State private var lastHandledBeat = -1
    @State private var adaptationMessage="FOLLOW ALONG"
    @State private var runtimeSteps:[WorkoutStep]=[]
    @State private var activeSeconds:TimeInterval=0
    @State private var activeClock:Task<Void,Never>?
    @State private var showCameraSetup=false
    @State private var lastCoachMessage=""
    @State private var showDiagnostics=false
    @State private var showTransientControls=false
    @State private var transientTask:Task<Void,Never>?
    @State private var hasAcquiredYou=false
    @State private var trackingThisWorkout=false
    @State private var sessionBeginning=false
    @State private var showResults=false
    @State private var showEndConfirmation=false
    @State private var finalAverageScore:Double=0
    @State private var finalValidSamples:Int=0
    @State private var workoutOutcome:SwayWorkoutOutcome = .endedEarly
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var activeSteps:[WorkoutStep] { runtimeSteps.isEmpty ? steps:runtimeSteps }
    var current:WorkoutStep { activeSteps[min(index,max(0,activeSteps.count-1))] }
    var referenceReady:Bool { SwayCoachPoseEngine.supports(moveID:current.move.id) }
    private var isLandscape:Bool { horizontalSizeClass == .regular }
    // Alpha production contract: Lucia is the sole rendered COACH.
    // Beta profiles remain modelled but cannot select incomplete asset families here.
    private var coachPreset:Int { 0 }
    /// One eight-count is one authored move phrase. Counts, Lucia and tracking all consume this same local clock.
    private var movePhraseDuration:TimeInterval { 8.0 * 60.0 / max(40.0,timeline.bpm) }
    private var moveLocalElapsed:TimeInterval {
        let d=movePhraseDuration
        guard d > 0 else { return 0 }
        return timeline.elapsed.truncatingRemainder(dividingBy:d)
    }

    var body:some View {
        GeometryReader { proxy in
            ZStack {
                SwayTheme.stageGradient.ignoresSafeArea()
                if store.automaticStyleThemes { SwayTheme.styleAccent(current.move.style).opacity(0.07).ignoresSafeArea() }
                if started && store.visualCueStrength > 0 { rhythmPulse }
                performanceSurface(size:proxy.size)
                if paused && !showEndConfirmation { pausedSurface }
            }
            .contentShape(Rectangle())
            .onTapGesture { if started && !paused { revealTransientControls() } }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden,for:.tabBar)
        .toolbar(.hidden,for:.navigationBar)
        .task {
            runtimeSteps=steps
            trackingThisWorkout=startWithTracking
            _=await health.requestAuthorization(); health.prepare()
            playbackCoordinator.onPause={if started && !paused{togglePause()}}
            playbackCoordinator.onResume={if started && paused{togglePause()}}
            session.commandHandler={command in handle(command)}
            publishSession(); await prepareSession()
            if startWithTracking { timeline.pause(); music.pause(); showCameraSetup=true }
        }
        .onChange(of:timeline.beat){_,beat in handleBeat(beat)}
        .onChange(of:pose.frameSequence){_,_ in ingestPose()}
        .sheet(isPresented:$showCameraSetup,onDismiss:{if started && !paused && !trackingThisWorkout{music.play();timeline.resume()}}){NavigationStack{CameraTrackingSetupView(pose:pose,onCompleted:{trackingThisWorkout=true;hasAcquiredYou=false;adaptationMessage="TRACKING READY";music.play();timeline.resume()})}}
        .sheet(isPresented:$showDiagnostics){NavigationStack{workoutDiagnostics}}
        .confirmationDialog("End workout?",isPresented:$showEndConfirmation,titleVisibility:.visible){
            Button("Keep Dancing",role:.cancel){}
            Button("End Workout",role:.destructive){finish(outcome:.endedEarly)}
        }
        .fullScreenCover(isPresented:$showResults){SwayWorkoutResultsView(outcome:workoutOutcome,moves:max(1,performedMoves),accuracy:finalAverageScore,minutes:Int(activeSeconds/60),tracked:finalValidSamples>0,onContinue:{showResults=false;dismiss()},onRetry:{showResults=false;restartWorkout()})}
        .onChange(of:scenePhase){_,phase in UIApplication.shared.isIdleTimerDisabled=(phase == .active && (sessionBeginning || started || showCameraSetup))}
        .onDisappear{UIApplication.shared.isIdleTimerDisabled=false;transientTask?.cancel();activeClock?.cancel();music.stop();timeline.stop();pose.stop();shazam.stop()}
    }

    private func coachFigure(elapsed: TimeInterval, paused: Bool) -> some View {
        SwayHumanFigureView(
            moveID: current.move.id,
            elapsed: elapsed,
            bpm: timeline.bpm,
            paused: paused,
            mirrored: store.mirrored,
            characterMode: true,
            skinTone: store.character.skinTone,
            hairStyle: store.character.hairStyle,
            outfitStyle: store.character.outfitStyle,
            appearancePreset: coachPreset,
            instructorPreset: coachPreset,
            bodyStyle: store.character.bodyStyle,
            faceShape: store.character.faceShape,
            hairColor: store.character.hairColor,
            footwearStyle: store.character.footwearStyle,
            accessoryStyle: store.character.accessoryStyle
        )
    }

    @ViewBuilder private func performanceSurface(size:CGSize)->some View {
        let landscape=size.width>size.height
        VStack(spacing:landscape ? 6:10) {
            topCue
            ZStack {
                if started {
                    if trackingThisWorkout && store.showCameraFeed {
                        CameraPreview(session:pose.session)
                            .opacity(0.18)
                            .saturation(0.25)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    if referenceReady {
                        // The animated articulated character consumes the canonical choreography pose.
                        // Character mode is deliberately simple and distance-readable; no raster pose cross-fades.
                        coachFigure(elapsed: moveLocalElapsed, paused: paused)
                            .padding(.horizontal,landscape ? size.width*0.22:4)
                    }
                    if trackingThisWorkout && store.showYouOverlay {
                        SwayUserSilhouetteView(pose:pose.bodyPose,visible:pose.personTrackingState.isTracking && pose.scoringReady)
                            .padding(.horizontal,landscape ? size.width*0.22:4)
                            .transition(.opacity)
                    }
                    if trackingThisWorkout && !pose.personTrackingState.isTracking {
                        Text("STEP INTO VIEW").font(.headline.bold()).padding(.horizontal,18).padding(.vertical,9).background(.black.opacity(0.55),in:Capsule()).frame(maxHeight:.infinity,alignment:.bottom).padding(.bottom,74)
                    } else if trackingThisWorkout && store.showCoachMessages && adaptationMessage != "WITH YOU" {
                        Text(adaptationMessage).font(.headline.bold()).padding(.horizontal,18).padding(.vertical,9).background(.black.opacity(0.48),in:Capsule()).frame(maxHeight:.infinity,alignment:.bottom).padding(.bottom,74)
                    }
                } else {
                    coachFigure(elapsed: 0, paused: true)
                        .padding(.horizontal,landscape ? size.width*0.22:4).opacity(0.92)
                    VStack(spacing:5){Spacer();Text("Instructor Ready").font(.headline);Text("\(countdown)").font(.system(size:landscape ? 74:92,weight:.bold,design:.rounded));Text("FOLLOW ME").font(.title2.bold()).tracking(1.2)}.padding(.bottom,18)
                }
            }
            .frame(maxWidth:.infinity,maxHeight:.infinity)
            .clipped()

            if started { essentialControls }
        }
        .padding(.horizontal,landscape ? 24:14).padding(.top,landscape ? 10:18).padding(.bottom,landscape ? 10:14)
        .foregroundStyle(.white)
    }

    private var topCue:some View {
        VStack(spacing:7){
            HStack(alignment:.firstTextBaseline){
                VStack(alignment:.leading,spacing:1){Text(current.move.name.uppercased()).font(.system(size:22,weight:.bold,design:.rounded));Text("Move \(min(index+1,activeSteps.count)) of \(activeSteps.count)").font(.caption).foregroundStyle(.white.opacity(0.62))}
                Spacer()
                if started && store.showWorkoutCounts {Text("\(timeline.count)").font(.system(size:32,weight:.bold,design:.rounded)).foregroundStyle(SwayTheme.cyan).accessibilityLabel("Count \(timeline.count)")}
            }
            HStack(spacing:5){ForEach(activeSteps.indices,id:\.self){n in Capsule().fill(n<index ? SwayTheme.accent:(n==index ? SwayTheme.violet:Color.white.opacity(0.14))).frame(height:4)}}
            if started {
                HStack(spacing:10) {
                    Label(music.trackTitle.isEmpty ? "SWAY Beats" : music.trackTitle,systemImage:"music.note").lineLimit(1)
                    Spacer()
                    if index+1<activeSteps.count { Text("NEXT · \(activeSteps[index+1].move.name)").lineLimit(1) }
                    if trackingThisWorkout { Label("YOU",systemImage:"camera.viewfinder") }
                }.font(.caption.bold()).foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private var essentialControls:some View {
        ZStack {
            if showTransientControls {
                HStack {
                    VStack(alignment:.leading,spacing:2){
                        if index+1<activeSteps.count {Text("NEXT").font(.caption2.bold()).foregroundStyle(.secondary);Text(activeSteps[index+1].move.name).font(.subheadline.bold())}
                    }
                    Spacer()
                    Button { if trackingThisWorkout {trackingThisWorkout=false;pose.stop();adaptationMessage="FOLLOW ALONG"} else {timeline.pause();music.pause();showCameraSetup=true} } label:{Image(systemName:trackingThisWorkout ? "figure.dance.circle.fill":"figure.dance.circle").font(.title2)}.accessibilityLabel(trackingThisWorkout ? "Turn off movement tracking":"Enable movement tracking")
                }
                .transition(.opacity)
            }
            Button {togglePause()} label:{VStack(spacing:3){Image(systemName:"pause.fill").font(.system(size:28,weight:.bold));Text("PAUSE").font(.caption.bold()).tracking(1)}}
                .frame(minWidth:112,minHeight:72).background(.black.opacity(0.58),in:Capsule()).overlay(Capsule().stroke(.white.opacity(0.16),lineWidth:1))
                .accessibilityHint("Pauses the workout immediately")
        }
        .frame(maxWidth:.infinity,minHeight:76)
    }

    private var pausedSurface:some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing:18){
                Text("PAUSED").font(.system(size:34,weight:.bold,design:.rounded)).tracking(2)
                Button {togglePause()} label:{VStack(spacing:8){Image(systemName:"play.fill").font(.system(size:40));Text("RESUME").font(.title3.bold())}.foregroundStyle(.white).frame(maxWidth:300,minHeight:112).background(SwayTheme.accent,in:RoundedRectangle(cornerRadius:24))}.buttonStyle(.plain).accessibilityHint("Returns to the workout")
                Button("Restart Movement"){restartMovement()}.buttonStyle(.bordered).controlSize(.large)
                Button("Finish…",role:.destructive){showEndConfirmation=true}.buttonStyle(.bordered).controlSize(.large)
            }.padding(28)
        }
        .transition(.opacity)
    }

    private var rhythmPulse:some View {
        let strength=Double(store.visualCueStrength),downbeat=timeline.count==1,phase=max(0,min(1,timeline.beatPhase)),envelope=pow(1.0-phase,2.4),opacity=envelope*(downbeat ? 0.12:0.055)*strength
        return ZStack{SwayTheme.styleAccent(current.move.style).opacity(opacity).ignoresSafeArea();Circle().stroke(SwayTheme.styleAccent(current.move.style).opacity(opacity*2.2),lineWidth:downbeat ? 5:2).scaleEffect(CGFloat(0.55+phase*1.15)).frame(width:260,height:260)}.allowsHitTesting(false).accessibilityHidden(true)
    }

    private var workoutDiagnostics:some View {
        List{Section("Music"){LabeledContent("Track",value:music.trackTitle);LabeledContent("Provider",value:music.providerName);LabeledContent("Tempo",value:"\(Int(music.bpm)) BPM")};Section("You / Vision"){Text(pose.readiness.message);LabeledContent("State",value:pose.personTrackingState.rawValue);LabeledContent("Vision",value:String(format:"%.1f fps",pose.framesPerSecond));LabeledContent("Confidence",value:"\(Int(pose.averageConfidence*100))%")};if let score=scoring.latest{Section("Matcher"){LabeledContent("Match",value:"\(Int(score.total*100))%");Text(score.state.rawValue)}}}.navigationTitle("Diagnostics").navigationBarTitleDisplayMode(.inline)
    }

    @MainActor func prepareSession() async {guard !sessionBeginning else{return};await beginWorkout()}
    @MainActor func beginWorkout() async {
        guard !sessionBeginning else{return};sessionBeginning=true;showCameraSetup=false
        for n in stride(from:3,through:1,by:-1){countdown=n;try? await Task.sleep(nanoseconds:700_000_000);if Task.isCancelled{return}}
        started=true;health.start();music.play();timeline.start(bpm:music.bpm,beatGrid:music.analyzedBeatGrid,songPosition:music.playbackPosition);adaptationMessage="FOLLOW ALONG"
        activeClock=Task{@MainActor in while !Task.isCancelled{try? await Task.sleep(nanoseconds:1_000_000_000);if started && !paused{activeSeconds+=1}}}
        if !music.usingLibraryTrack{store.unlock(.firstSwayBeats)};publishSession()
    }

    func handleBeat(_ beat:Int){
        guard started,!paused,beat != lastHandledBeat else{return}
        lastHandledBeat=beat;store.haptic();cues.beat(count:timeline.count,phraseStart:timeline.count==1 && timeline.bar%8==0)
        if beat>0 && beat%8==0 {
            performedMoves += 1
            if activeSeconds >= Double(minutes*60) { finish(outcome:.completed); return }
            if !activeSteps.isEmpty { index=(index+1)%activeSteps.count }
        }
        if !trackingThisWorkout{adaptationMessage="FOLLOW ALONG"};publishSession()
    }

    func ingestPose(){
        guard started,!paused,trackingThisWorkout else{return}
        guard pose.scoringReady,!pose.bodyPose.isEmpty else{combo=0;adaptationMessage=pose.personTrackingState.isTracking ? "HOLD THERE":"STEP INTO VIEW";return}
        if !hasAcquiredYou{hasAcquiredYou=true;adaptationMessage="WITH YOU";announceCoach("WITH YOU")}
        let sampleAge=max(0,ProcessInfo.processInfo.systemUptime-pose.bodyPose.timestamp);guard sampleAge<=0.35 else{combo=0;adaptationMessage="STEP INTO VIEW";return}
        let joints=pose.bodyPose.joints
        func point(_ name:VNHumanBodyPoseObservation.JointName)->SwayJointPoint?{guard let j=joints[name] else{return nil};return .init(x:Double(j.point.x),y:Double(j.point.y),confidence:Double(j.confidence))}
        var points:[String:SwayJointPoint]=[:]
        let canonical:[(String,VNHumanBodyPoseObservation.JointName)]=[("leftShoulder",.leftShoulder),("rightShoulder",.rightShoulder),("leftElbow",.leftElbow),("rightElbow",.rightElbow),("leftWrist",.leftWrist),("rightWrist",.rightWrist),("leftHip",.leftHip),("rightHip",.rightHip),("leftKnee",.leftKnee),("rightKnee",.rightKnee),("leftAnkle",.leftAnkle),("rightAnkle",.rightAnkle)]
        for(key,name) in canonical{if let p=point(name){points[key]=p}}
        let observed=SwayPoseNormalizer.jointAngles(points);guard observed.count>=2 else{combo=0;adaptationMessage="HOLD THERE";return}
        guard let reference=SwayReferencePoseCatalog.referenceIfAvailable(moveID:current.move.id,musicalTime:moveLocalElapsed,bpm:timeline.bpm) else{return}
        let referenceTime=max(0,moveLocalElapsed-sampleAge),aligned=SwayReferencePoseCatalog.referenceIfAvailable(moveID:current.move.id,musicalTime:referenceTime,bpm:timeline.bpm) ?? reference
        scoring.ingest(reference:aligned,observed:observed,timingError:0,confidence:Double(pose.averageConfidence));combo=scoring.combo
        let decision=SwayPositiveCoachEngine().decision(sample:pose.engagement,match:scoring.latest,activeSeconds:activeSeconds)
        if decision.message != lastCoachMessage && Int(activeSeconds)%8==0{lastCoachMessage=decision.message;announceCoach(decision.message.uppercased())}
    }

    func announceCoach(_ message:String){ let profile=SwayCoachProfileID.lucia; let spoken=profile.phrase(message); adaptationMessage=spoken; guard store.showCoachMessages else{return}; cues.coach(spoken) }
    func togglePause(){paused.toggle();if paused{timeline.pause();music.pause();health.pause()}else{music.play();timeline.resume();health.resume()};publishSession()}
    func revealTransientControls(){transientTask?.cancel();withAnimation(.easeOut(duration:0.18)){showTransientControls=true};transientTask=Task{@MainActor in try? await Task.sleep(nanoseconds:3_000_000_000);if !Task.isCancelled{withAnimation(.easeIn(duration:0.25)){showTransientControls=false}}}}
    func restartMovement(){lastHandledBeat = -1;timeline.stop();timeline.start(bpm:music.bpm,beatGrid:music.analyzedBeatGrid,songPosition:music.playbackPosition);if paused{timeline.pause();music.pause()};adaptationMessage="FROM THE TOP"}
    func adapt(easier:Bool,automatic:Bool){let id=easier ? current.move.easierID:current.move.harderID;guard let id,let replacement=store.moves.first(where:{$0.id==id}) else{return};if runtimeSteps.isEmpty{runtimeSteps=steps};if runtimeSteps.indices.contains(index){runtimeSteps[index].move=replacement};store.learned.insert(replacement.id)}
    func handle(_ command:SwaySessionCommand){switch command{case .start:break;case .pause:if started && !paused{togglePause()};case .resume:if started && paused{togglePause()};case .end:showEndConfirmation=true;case .easier:adapt(easier:true,automatic:false);case .harder:adapt(easier:false,automatic:false);case .setIntensity(let value):store.intensity=min(4,max(1,value));case .setBeatsEnabled:break;case .setBeatsVolume:break};publishSession()}
    func publishSession(){let next=index+1<activeSteps.count ? activeSteps[index+1].move.name:"";session.publish(.init(phase:started ? (paused ? .paused:.dancing):.countdown,moveName:activeSteps.isEmpty ? "":current.move.name,nextMoveName:next,count:timeline.count,bar:timeline.bar,phrase:timeline.phrase,combo:combo,flow:combo>=16,intensity:store.intensity,cameraMessage:trackingThisWorkout ? pose.personTrackingState.rawValue:"Follow-Along Mode",musicTitle:music.trackTitle,bpm:music.bpm))}
    func finish(outcome:SwayWorkoutOutcome){activeClock?.cancel();music.stop();timeline.stop();pose.stop();shazam.stop();let valid=scoring.recent.filter{$0.state != .unknown};let avg=valid.isEmpty ? 0:valid.map(\.total).reduce(0,+)/Double(valid.count);if outcome == .completed{_=store.complete(minutes:minutes,activeSeconds:activeSeconds,steps:activeSteps,averageScore:avg,maxCombo:combo)};let summary=SwayWorkoutSummary(endedAt:Date(),activeSeconds:activeSeconds,averageScore:avg,validSamples:valid.count,unknownSamples:scoring.recent.count-valid.count);Task{await health.finish(summary:summary)};session.publish(SwaySessionSnapshot(phase:outcome == .completed ? .completed:.endedEarly));workoutOutcome=outcome;finalAverageScore=avg;finalValidSamples=valid.count;showResults=true}
    private func restartWorkout(){index=0;performedMoves=0;combo=0;activeSeconds=0;started=false;paused=false;lastHandledBeat = -1;sessionBeginning=false;Task{await beginWorkout()}}
}

enum SwayWorkoutOutcome { case completed, endedEarly }

struct SwayWorkoutResultsView:View {
    let outcome:SwayWorkoutOutcome; let moves:Int; let accuracy:Double; let minutes:Int; let tracked:Bool; let onContinue:()->Void; let onRetry:()->Void
    var body:some View {
        ZStack { SwayTheme.stageGradient.ignoresSafeArea(); VStack(spacing:22) {
            Spacer(); Image(systemName:outcome == .completed ? "star.fill":"stop.circle.fill").font(.system(size:68)).foregroundStyle(outcome == .completed ? .yellow:.secondary)
            Text(outcome == .completed ? "Great Job!":"Workout Ended").font(.largeTitle.bold())
            if outcome == .endedEarly { Text("Your completed activity is shown below. This workout was not marked complete.").multilineTextAlignment(.center).foregroundStyle(.secondary) }
            HStack(spacing:10) {
                result("checkmark.circle.fill","\(moves)","Moves",.green)
                result("chart.bar.fill",tracked ? "\(Int(accuracy*100))%":"—","Accuracy",.cyan)
                result("flame.fill","\(minutes)","Minutes",.orange)
            }
            Button("Continue",action:onContinue).buttonStyle(SwayPinkButtonStyle())
            Button("Try Again",action:onRetry).buttonStyle(.bordered)
            if !tracked { Text("Accuracy appears when you choose movement tracking.").font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }.padding(24) }
    }
    private func result(_ icon:String,_ value:String,_ title:String,_ color:Color)->some View { VStack(spacing:6){Image(systemName:icon).foregroundStyle(color);Text(value).font(.title.bold());Text(title).font(.caption).foregroundStyle(.secondary)}.frame(maxWidth:.infinity).padding(.vertical,18).background(Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:18)) }
}

