import SwiftUI

#if DEBUG
/// A single preview navigator covers the complete inventory. Select any screen from
/// the menu, then run each of the three device canvases below.
struct SWAYReleasePreviewGallery: View {
    enum Screen: String, CaseIterable, Identifiable {
        case home, setup, workout, paused, ended, complete, moves, learn, create, beats, progress, calibration, profile, creator, record, permission, onboarding
        var id: String { rawValue }
    }
    @State private var screen: Screen = .home
    @State private var tab: SWAYTab = .home
    private let move = DanceMove(id: "step-touch", name: "Step Touch", difficulty: 1, impact: 1, bpmMin: 80, bpmMax: 140, space: 1, style: "Foundation")
    var body: some View {
        VStack(spacing: 0) {
            Picker("Preview screen", selection: $screen) { ForEach(Screen.allCases) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.menu).padding(6).background(.black)
            NavigationStack { preview }.environmentObject(SwayStore())
        }.preferredColorScheme(.dark)
    }
    @ViewBuilder private var preview: some View {
        switch screen {
        case .home: SWAYHomeScreen(selection: $tab)
        case .setup: SWAYWorkoutSetupScreen()
        case .workout, .paused: SWAYWorkoutScreen()
        case .ended: SWAYWorkoutEndedScreen()
        case .complete: SWAYWorkoutEndedScreen(completed: true)
        case .moves: SWAYMovesScreen()
        case .learn: SWAYLearnMoveScreen(move: move)
        case .create: SWAYCreateMoveScreen()
        case .beats: SWAYBeatsScreen()
        case .progress: SWAYProgressScreen()
        case .calibration: SWAYCalibrationScreen()
        case .profile: SWAYProfileScreen()
        case .creator: SWAYAvatarCreatorScreen()
        case .record: SWAYRecordPreviewScreen()
        case .permission: SWAYPermissionDeniedView(capability: "Camera")
        case .onboarding: SWAYOnboardingScreen()
        }
    }
}

#Preview("All Screens • iPhone 15 Pro Max") { SWAYReleasePreviewGallery().frame(width: 430, height: 932) }
#Preview("All Screens • iPad Portrait") { SWAYReleasePreviewGallery().frame(width: 820, height: 1180) }
#Preview("All Screens • iPad Landscape") { SWAYReleasePreviewGallery().frame(width: 1180, height: 820) }
#endif
