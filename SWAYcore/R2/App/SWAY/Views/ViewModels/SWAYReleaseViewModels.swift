import SwiftUI

@MainActor final class SWAYWorkoutSetupViewModel: ObservableObject {
    enum TrackingMode: String, CaseIterable { case camera = "Camera Tracking", follow = "Follow Along" }
    @Published var mode: TrackingMode = .follow
    @Published var filter = "All"
    @Published var selectedMinutes = 15
    let filters = ["All", "Beginner", "Dance Fit", "Cardio", "Strength"]
}

@MainActor final class SWAYWorkoutViewModel: ObservableObject {
    @Published var paused = false
    @Published var ending = false
    @Published var index = 0
    let moves = ["March", "Step Touch", "Hip Sway", "Arm Reach", "Heel Dig", "V-Step", "Side Tap", "March"]
    var moveID: String { ["march", "step-touch", "hip-sway", "arm-reach", "heel-dig", "v-step", "side-tap", "march"][index] }
    func next() { index = min(index + 1, moves.count - 1) }
    func restart() { index = 0; paused = false }
}

@MainActor final class SWAYMoveLibraryViewModel: ObservableObject {
    @Published var filter = "All"
    @Published var favourites: Set<String> = []
    let filters = ["All", "Beginner", "Intermediate", "Advanced"]
    func toggle(_ id: String) { if !favourites.insert(id).inserted { favourites.remove(id) } }
}

@MainActor final class SWAYBeatViewModel: ObservableObject {
    @Published var source = "SWAY Beats"
    @Published var style = "Pop"
    @Published var tempo = 108.0
    @Published var intensity = 0.55
    @Published var generation = 1
    func generate() { generation += 1 }
}

/// Adapter boundary for Task 2. UI state is translated to existing store calls only;
/// workout generation and persistence remain service responsibilities.
@MainActor enum SWAYServiceAdapter {
    static func workout(store: SwayStore, minutes: Int) -> [WorkoutStep] {
        store.generate(minutes: minutes, difficulty: store.moveComplexity, lowImpact: store.lowImpact, smallSpace: store.smallSpace)
    }
    static func saveAvatar(store: SwayStore, profile: SwayCharacterProfile) {
        store.character = profile
        store.save()
    }
}
