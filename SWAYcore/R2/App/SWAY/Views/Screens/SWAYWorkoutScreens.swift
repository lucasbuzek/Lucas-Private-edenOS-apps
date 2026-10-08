import SwiftUI

struct SWAYWorkoutScreen: View {
    @StateObject private var model = SWAYWorkoutViewModel()
    @State private var showEnded = false
    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width > 700
            ZStack {
                SWAYUI.ink.ignoresSafeArea()
                VStack(spacing: 12) {
                    HStack { VStack(alignment: .leading) { Text("FOUNDATION FLOW").font(.headline); Text("\(model.index + 1) of 8 • \(model.moves[model.index])").foregroundStyle(SWAYUI.secondary) }; Spacer(); Button { } label: { Image(systemName: "music.note").frame(width: 44, height: 44).background(SWAYUI.card, in: Circle()) }.accessibilityLabel("Music controls") }
                    if wide { HStack(spacing: 14) { coachStage; youCard.frame(width: proxy.size.width * 0.3); stats.frame(width: 150) } } else { coachStage; HStack(spacing: 10) { youCard; stats } }
                    HStack(spacing: 12) { VStack(alignment: .leading) { Text("GOOD ENERGY").font(.caption.bold()); Text("SWAY Beats").foregroundStyle(SWAYUI.secondary) }; Spacer(); Button { model.paused = true } label: { Image(systemName: "pause.fill").frame(width: 52, height: 52).background(.white, in: Circle()).foregroundStyle(.black) }.accessibilityLabel("Pause workout"); Button { model.next() } label: { Label("Next", systemImage: "arrow.right") }.frame(minHeight: 44) }
                }.padding(18)
                if model.paused { SWAYPauseOverlay(model: model, showEnded: $showEnded) }
            }
        }.toolbar(.hidden, for: .navigationBar).navigationDestination(isPresented: $showEnded) { SWAYWorkoutEndedScreen() }
    }
    private var coachStage: some View {
        ZStack(alignment: .bottomTrailing) { SWAYUI.stage; SWAYCharacterStage(character: .lucia, source: .move(id: model.moveID, musicalTime: 0.7, bpm: 108, paused: model.paused)).padding(12); HStack { SWAYCharacterStage(character: .lucia, source: .move(id: model.index < 7 ? "step-touch" : "march", musicalTime: 0.2, bpm: 108, paused: true)).frame(width: 58, height: 76); VStack(alignment: .leading) { Text("NEXT").font(.caption.bold()).foregroundStyle(SWAYUI.pink); Text(model.moves[min(model.index + 1, 7)]).font(.headline) } }.padding(8).background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 16)).padding(10) }.frame(maxWidth: .infinity, maxHeight: .infinity).clipShape(RoundedRectangle(cornerRadius: 28)).accessibilityLabel("Coach demonstrating \(model.moves[model.index])")
    }
    private var youCard: some View { VStack { HStack { Text("YOU").font(.caption.bold()); Spacer(); Text("FOLLOW ALONG").font(.caption2).foregroundStyle(SWAYUI.secondary) }; SWAYCharacterStage(character: .yourDancer, source: .idle).frame(height: 130) }.padding(12).background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 20)) }
    private var stats: some View { VStack(spacing: 8) { SWAYStatTile(value: "01:24", label: "Move Time"); SWAYStatTile(value: "\(model.index + 1)/8", label: "Moves"); SWAYStatTile(value: "06:42", label: "Total Time") } }
}

private struct SWAYPauseOverlay: View {
    @ObservedObject var model: SWAYWorkoutViewModel
    @Binding var showEnded: Bool
    var body: some View { ZStack { Rectangle().fill(.ultraThinMaterial).ignoresSafeArea(); VStack(spacing: 14) { Text("Workout Paused").font(.largeTitle.bold()); Button("Resume") { model.paused = false }.buttonStyle(SWAYPrimaryButtonStyle()); Button("Restart") { model.restart() }.buttonStyle(SWAYSecondaryButtonStyle()); Button("End Workout") { model.ending = true }.buttonStyle(SWAYSecondaryButtonStyle()) }.padding(28).frame(maxWidth: 480) }.confirmationDialog("End Workout?", isPresented: $model.ending, titleVisibility: .visible) { Button("End Workout", role: .destructive) { showEnded = true }; Button("Cancel", role: .cancel) {} } message: { Text("Your progress so far will be saved, but this will not count as a completed workout.") } }
}

struct SWAYWorkoutEndedScreen: View {
    var completed = false
    @Environment(\.dismiss) private var dismiss
    var body: some View { SWAYScreen { VStack(spacing: 20) { Text(completed ? "GREAT JOB" : "WORKOUT ENDED").font(.largeTitle.bold()); SWAYCharacterStage(character: .lucia, source: .idle).frame(height: 300); if completed { Text("You completed Foundation Flow").font(.title2.bold()) }; HStack { SWAYStatTile(value: completed ? "15:00" : "06:42", label: "Time"); SWAYStatTile(value: completed ? "8" : "4", label: "Moves"); SWAYStatTile(value: completed ? "124" : "52", label: "Active Cal") }; if !completed { Label("Ended early", systemImage: "info.circle.fill").padding().frame(maxWidth: .infinity, alignment: .leading).background(SWAYUI.card, in: RoundedRectangle(cornerRadius: 18)) }; Button(completed ? "Continue" : "Back to Home") { dismiss() }.buttonStyle(SWAYPrimaryButtonStyle()); Button(completed ? "Share" : "Try Again") { }.buttonStyle(SWAYSecondaryButtonStyle()) } }.navigationBarBackButtonHidden() }
}

struct SWAYCalibrationScreen: View {
    private let steps = ["STEP INTO VIEW", "WAVE LEFT", "WAVE RIGHT", "LIFT LEFT FOOT", "LIFT RIGHT FOOT", "JUMP", "READY TO SWAY"]
    @State private var step = 0
    var body: some View { ZStack { SWAYUI.stage.ignoresSafeArea(); SWAYCharacterStage(character: .yourDancer, source: .idle).padding(.bottom, 90); VStack { Text("CALIBRATION").font(.caption.bold()).tracking(2); Spacer(); Text(steps[step]).font(.system(size: 30, weight: .black, design: .rounded)).multilineTextAlignment(.center); ProgressView(value: Double(step + 1), total: Double(steps.count)).tint(SWAYUI.pink); if step < steps.count - 1 { Button("I'M READY") { step += 1 }.buttonStyle(SWAYPrimaryButtonStyle()) } else { NavigationLink("START DANCING") { SWAYWorkoutScreen() }.buttonStyle(SWAYPrimaryButtonStyle()) } }.padding(24) }.toolbar(.hidden, for: .navigationBar) }
}

struct SWAYTrackingLostOverlay: View {
    var body: some View { VStack(spacing: 10) { Image(systemName: "person.crop.rectangle.badge.exclamationmark").font(.largeTitle); Text("STEP BACK INTO VIEW").font(.title2.bold()); Text("Make sure your whole body is visible. Your workout is paused.").multilineTextAlignment(.center).foregroundStyle(SWAYUI.secondary) }.padding(24).background(.black.opacity(0.86), in: RoundedRectangle(cornerRadius: 24)).accessibilityAddTraits(.isModal) }
}
