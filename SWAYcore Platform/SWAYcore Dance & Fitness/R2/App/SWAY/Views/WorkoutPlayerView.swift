import SwiftUI
import Vision
import ReplayKit
import SWAYcoreEngine

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
        SWAYAvatarStageView(role:.coach,moveID:moveID,elapsed:waiting ? 0:Double(max(0,count-1))*0.6,bpm:100,paused:true,mirrored:false,cutout:AnyView(SWAYSkeletal2DAvatarView(role:.coach,moveID:moveID,musicalTime:waiting ? 0:Double(max(0,count-1))*0.6,bpm:100,paused:true,mirrored:false)))
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
        GeometryReader { _ in
            Canvas { context,size in
                guard visible else{return}
                let map=pose.joints
                let usable=map.values.filter{$0.confidence >= 0.28}
                guard usable.count >= 5 else{return}
                let xs=usable.map{$0.point.x}, ys=usable.map{$0.point.y}
                guard let minX=xs.min(),let maxX=xs.max(),let minY=ys.min(),let maxY=ys.max() else{return}
                let w=max(0.12,maxX-minX),h=max(0.30,maxY-minY)
                // Same normalized stage envelope as COACH: full-body fills the movement
                // space while preserving extremities. Tracking position is intentionally
                // normalized so YOU overlays the target rather than a camera coordinate.
                let scale=min(0.82/w,0.88/h)
                let cx=(minX+maxX)/2,cy=(minY+maxY)/2
                func q(_ j:PoseJoint)->CGPoint {
                    CGPoint(x:(0.5+(j.point.x-cx)*scale)*size.width,
                            y:(0.50+(j.point.y-cy)*scale)*size.height)
                }
                let bodyColor=Color.cyan.opacity(0.22)
                let edgeColor=Color.cyan.opacity(0.72)
                let limbWidth=max(18,min(size.width,size.height)*0.055)
                for (a,b) in bones {
                    guard let aa=map[a],let bb=map[b],aa.confidence>=0.28,bb.confidence>=0.28 else{continue}
                    var path=Path();path.move(to:q(aa));path.addLine(to:q(bb))
                    context.stroke(path,with:.color(bodyColor),style:StrokeStyle(lineWidth:limbWidth,lineCap:.round,lineJoin:.round))
                    context.stroke(path,with:.color(edgeColor),style:StrokeStyle(lineWidth:max(2,limbWidth*0.10),lineCap:.round,lineJoin:.round))
                }
                if let ls=map[.leftShoulder],let rs=map[.rightShoulder],let lh=map[.leftHip],let rh=map[.rightHip] {
                    let pts=[q(ls),q(rs),q(rh),q(lh)]
                    var torso=Path();torso.move(to:pts[0]);pts.dropFirst().forEach{torso.addLine(to:$0)};torso.closeSubpath()
                    context.fill(torso,with:.color(bodyColor));context.stroke(torso,with:.color(edgeColor),lineWidth:max(2,limbWidth*0.10))
                }
                if let head=map[.nose],head.confidence>=0.28 {
                    let hp=q(head),r=max(18,limbWidth*0.82)
                    let circle=Path(ellipseIn:CGRect(x:hp.x-r,y:hp.y-r,width:r*2,height:r*2))
                    context.fill(circle,with:.color(bodyColor));context.stroke(circle,with:.color(edgeColor),lineWidth:max(2,limbWidth*0.10))
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
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
    @StateObject private var recorder=SwayPerformanceRecorder.shared
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
    private var movePhraseDuration:TimeInterval { 8.0 * 60.0 / max(SwayTimelineMath.minimumBPM,timeline.bpm) }
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
                // Calibration owns the stage. Never render the workout COACH or
                // pre-workout countdown behind the live COACH + tracked YOU overlay.
                if !showCameraSetup {
                    performanceSurface(size:proxy.size)
                        .frame(maxWidth:1100,maxHeight:.infinity)
                        .frame(maxWidth:.infinity,maxHeight:.infinity)
                }
                if showCameraSetup {
                    cameraSetupOverlay
                        .transition(.opacity)
                        .zIndex(20)
                }
                if paused && !showEndConfirmation && !showCameraSetup { pausedSurface }
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
        }
        .onChange(of:timeline.beat){_,beat in handleBeat(beat)}
        .onChange(of:pose.frameSequence){_,_ in ingestPose()}
                .sheet(isPresented:$showDiagnostics){NavigationStack{workoutDiagnostics}}
        .sheet(isPresented: Binding(get:{recorder.preview != nil}, set:{if !$0 { recorder.discardPreview() }})) {
            if let preview=recorder.preview { SwayReplayPreview(controller:preview) }
        }
        .alert("Recording",isPresented:Binding(get:{recorder.lastError != nil},set:{if !$0{recorder.lastError=nil}})) {
            Button("OK",role:.cancel){recorder.lastError=nil}
        } message: { Text(recorder.lastError ?? "") }
        .confirmationDialog("End workout?",isPresented:$showEndConfirmation,titleVisibility:.visible){
            Button("Keep Dancing",role:.cancel){}
            Button("End Workout",role:.destructive){finish(outcome:.endedEarly)}
        }
        .fullScreenCover(isPresented:$showResults){SwayWorkoutResultsView(outcome:workoutOutcome,moves:max(1,performedMoves),accuracy:finalAverageScore,minutes:Int(activeSeconds/60),tracked:finalValidSamples>0,onContinue:{showResults=false;dismiss()},onRetry:{showResults=false;restartWorkout()})}
        .onChange(of:scenePhase){_,phase in UIApplication.shared.isIdleTimerDisabled=(phase == .active && (sessionBeginning || started || showCameraSetup))}
        .onDisappear{
            UIApplication.shared.isIdleTimerDisabled=false
            transientTask?.cancel(); activeClock?.cancel(); music.stop(); timeline.stop(); pose.stop(); shazam.stop()
            if recorder.isRecording { Task { await recorder.stop() } }
        }
    }

    private func coachFigure(elapsed: TimeInterval, paused: Bool) -> some View {
        SWAYCoachAvatarView(moveID:current.move.id,musicalTime:elapsed,bpm:timeline.bpm,paused:paused,mirrored:store.mirrored)
    }

    @ViewBuilder private func performanceSurface(size:CGSize)->some View {
        let landscape=size.width>size.height
        let stageHorizontal:CGFloat = landscape ? max(8,size.width*0.06) : 4
        VStack(spacing:landscape ? 4:8) {
            topCue(size:size)
            ZStack {
                if started {
                    if trackingThisWorkout && store.showCameraFeed {
                        CameraPreview(session:pose.session).opacity(0.12).saturation(0.2)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                    if referenceReady {
                        coachFigure(elapsed:moveLocalElapsed,paused:paused)
                            .padding(.horizontal,stageHorizontal)
                            .padding(.vertical,2)
                    }
                    if trackingThisWorkout && store.showYouOverlay {
                        // Use the frozen camera-tracked graphical YOUR DANCER route,
                        // not the raw engineering skeleton overlay.
                        SWAYCharacterStage(
                            character:.yourDancer,
                            source:.tracked(pose.bodyPose,visible:pose.personTrackingState.isTracking),
                            profile:store.character,
                            mirrored:store.mirrored
                        )
                        .padding(.horizontal,stageHorizontal)
                        .padding(.vertical,2)
                        .transition(.opacity)
                    }
                    if trackingThisWorkout && !pose.personTrackingState.isTracking {
                        Text("STEP INTO VIEW")
                            .font(.system(size:landscape ? 30:26,weight:.heavy,design:.rounded))
                            .padding(.horizontal,22).padding(.vertical,12)
                            .background(.black.opacity(0.68),in:Capsule())
                            .frame(maxHeight:.infinity,alignment:.bottom).padding(.bottom,22)
                    }
                } else {
                    coachFigure(elapsed:0,paused:true)
                        .padding(.horizontal,stageHorizontal).padding(.vertical,2).opacity(0.92)
                    VStack(spacing:5){Spacer();Text("GET READY").font(.title2.bold());Text("\(countdown)").font(.system(size:landscape ? 82:96,weight:.bold,design:.rounded));Text("FOLLOW ME").font(.title.bold()).tracking(1.2)}.padding(.bottom,18)
                }
            }
            .frame(maxWidth:.infinity,maxHeight:.infinity).clipped()
            if started { essentialControls }
        }
        .padding(.horizontal,landscape ? 16:12).padding(.top,landscape ? 6:12).padding(.bottom,landscape ? 6:10)
        .foregroundStyle(.white)
    }

    private func topCue(size:CGSize)->some View {
        let landscape=size.width>size.height
        let moveSize:CGFloat = landscape ? 34:30
        let countSize:CGFloat = landscape ? 58:52
        return VStack(spacing:landscape ? 3:5){
            HStack(alignment:.center,spacing:12){
                VStack(alignment:.leading,spacing:0){
                    Text(current.move.name.uppercased())
                        .font(.system(size:moveSize,weight:.heavy,design:.rounded))
                        .minimumScaleFactor(0.62).lineLimit(1)
                    Text("MOVE \(min(index+1,activeSteps.count)) OF \(activeSteps.count)")
                        .font(.system(size:landscape ? 17:15,weight:.bold,design:.rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer(minLength:10)
                if started && store.showWorkoutCounts {
                    Text("\(timeline.count)")
                        .font(.system(size:countSize,weight:.black,design:.rounded))
                        .foregroundStyle(SwayTheme.cyan)
                        .monospacedDigit().accessibilityLabel("Count \(timeline.count)")
                }
            }
            HStack(spacing:5){ForEach(activeSteps.indices,id:\.self){n in Capsule().fill(n<index ? SwayTheme.accent:(n==index ? SwayTheme.violet:Color.white.opacity(0.14))).frame(height:5)}}
            if started {
                HStack(spacing:12) {
                    if index+1<activeSteps.count && store.showNextMove {
                        Text("NEXT  \(activeSteps[index+1].move.name.uppercased())")
                            .font(.system(size:landscape ? 20:17,weight:.bold,design:.rounded))
                            .lineLimit(1)
                    }
                    Spacer()
                    if trackingThisWorkout {
                        Text(pose.personTrackingState.isTracking ? "YOU" : "FINDING YOU")
                            .font(.system(size:landscape ? 18:16,weight:.bold,design:.rounded))
                            .foregroundStyle(pose.personTrackingState.isTracking ? SwayTheme.cyan:.white.opacity(0.75))
                    }
                }
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
                    HStack(spacing:16) {
                        Button {
                            Task { if recorder.isRecording { await recorder.stop() } else { await recorder.start(microphone:true) } }
                        } label: {
                            Image(systemName:recorder.isRecording ? "record.circle.fill":"record.circle").font(.title2)
                        }
                        .accessibilityLabel(recorder.isRecording ? "Stop recording SWAY":"Record SWAY")
                        Button { if trackingThisWorkout {trackingThisWorkout=false;pose.stop();adaptationMessage="FOLLOW ALONG"} else {timeline.pause();music.pause();showCameraSetup=true} } label:{Image(systemName:trackingThisWorkout ? "figure.dance.circle.fill":"figure.dance.circle").font(.title2)}.accessibilityLabel(trackingThisWorkout ? "Turn off movement tracking":"Enable movement tracking")
                    }
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

    private var cameraSetupOverlay: some View {
        CameraTrackingSetupView(
                pose: pose,
                onCompleted: {
                    // Calibration owns the session until READY TO SWAY. Only then may
                    // countdown, music, choreography, scoring and workout cues start.
                    trackingThisWorkout = true
                    hasAcquiredYou = false
                    adaptationMessage = "READY TO SWAY"
                    showCameraSetup = false
                    Task { await beginWorkout() }
                },
                onCancel: {
                    // Cancelling tracking explicitly chooses Follow-Along. It starts a
                    // fresh countdown; no hidden workout clock has been running.
                    trackingThisWorkout = false
                    showCameraSetup = false
                    pose.stop()
                    adaptationMessage = "FOLLOW ALONG"
                    Task { await beginWorkout() }
                }
            )
            .environmentObject(store)
            .accessibilityIdentifier("sway.workout.tracking.overlay")
    }

    private var rhythmPulse:some View {
        let strength=Double(store.visualCueStrength),downbeat=timeline.count==1,phase=max(0,min(1,timeline.beatPhase)),envelope=pow(1.0-phase,2.4),opacity=envelope*(downbeat ? 0.12:0.055)*strength
        return ZStack{SwayTheme.styleAccent(current.move.style).opacity(opacity).ignoresSafeArea();Circle().stroke(SwayTheme.styleAccent(current.move.style).opacity(opacity*2.2),lineWidth:downbeat ? 5:2).scaleEffect(CGFloat(0.55+phase*1.15)).frame(width:260,height:260)}.allowsHitTesting(false).accessibilityHidden(true)
    }

    private var workoutDiagnostics:some View {
        List{Section("Music"){LabeledContent("Track",value:music.trackTitle);LabeledContent("Provider",value:music.providerName);LabeledContent("Tempo",value:"\(Int(music.bpm)) BPM")};Section("You / Vision"){Text(pose.readiness.message);LabeledContent("State",value:pose.personTrackingState.rawValue);LabeledContent("Vision",value:String(format:"%.1f fps",pose.framesPerSecond));LabeledContent("Confidence",value:"\(Int(pose.averageConfidence*100))%")};if let score=scoring.latest{Section("Matcher"){LabeledContent("Match",value:"\(Int(score.total*100))%");Text(score.state.rawValue)}}}.navigationTitle("Diagnostics").navigationBarTitleDisplayMode(.inline)
    }

    @MainActor func prepareSession() async {
        guard !sessionBeginning else{return}
        if startWithTracking {
            trackingThisWorkout=true
            showCameraSetup=true
            adaptationMessage="STEP INTO VIEW"
            // Hard invariant: the workout timeline does not exist during calibration.
            music.pause(); timeline.stop()
            return
        }
        // Do not let preview audio run through the follow-along countdown.
        music.pause()
        await beginWorkout()
    }
    @MainActor func beginWorkout() async {
        guard !sessionBeginning else{return};sessionBeginning=true;showCameraSetup=false
        for n in stride(from:3,through:1,by:-1){countdown=n;try? await Task.sleep(nanoseconds:700_000_000);if Task.isCancelled{return}}
        started=true;health.start();music.play();timeline.start(bpm:music.bpm,beatGrid:music.analyzedBeatGrid,songPosition:music.authoritativePlaybackPosition);adaptationMessage="FOLLOW ALONG"
        activeClock=Task{@MainActor in while !Task.isCancelled{try? await Task.sleep(nanoseconds:1_000_000_000);if started && !paused{activeSeconds+=1}}}
        if !music.usingLibraryTrack{store.unlock(.firstSwayBeats)};publishSession()
    }

    func handleBeat(_ beat:Int){
        guard started,!paused,beat != lastHandledBeat else{return}
        let previous = lastHandledBeat
        lastHandledBeat=beat;store.haptic();cues.beat(count:timeline.count,phraseStart:timeline.count==1 && timeline.bar%8==0)
        // Credit each eight-count that actually completed since the previous
        // observed beat. A first observation (including a mid-song seek) is a
        // cursor anchor, never an already-performed movement.
        if previous >= 0 && beat > previous {
            let completed = max(0, (max(0,beat)-1)/8 - (max(0,previous)-1)/8)
            for _ in 0..<completed {
                performedMoves += 1
                if activeSeconds >= Double(minutes*60) { finish(outcome:.completed); return }
                if !activeSteps.isEmpty { index=(index+1)%activeSteps.count }
            }
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
    func restartMovement(){
        lastHandledBeat = -1
        let anchor = timeline.currentMovePhraseStartTransportTime
        timeline.stop()
        music.seek(to:anchor)
        timeline.start(bpm:music.bpm,beatGrid:music.analyzedBeatGrid,songPosition:anchor)
        if paused { timeline.pause();music.pause() }
        adaptationMessage="FROM THE TOP"
    }
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


private struct SwayReplayPreview: UIViewControllerRepresentable {
    let controller: RPPreviewViewController
    func makeUIViewController(context: Context) -> RPPreviewViewController { controller }
    func updateUIViewController(_ uiViewController: RPPreviewViewController, context: Context) {}
}
