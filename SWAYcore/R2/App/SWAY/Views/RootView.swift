import SwiftUI

/// Consumer navigation is deliberately limited to the four product destinations.
/// Engineering tools are available only from Settings > Diagnostics.
struct RootView: View {
    @EnvironmentObject private var store: SwayStore
    @State private var selection: SWAYTab = .home
    @State private var showingOnboarding = false

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { SWAYHomeScreen(selection: $selection) }
                .tag(SWAYTab.home).tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { SWAYMovesScreen() }
                .tag(SWAYTab.moves).tabItem { Label("Moves", systemImage: "square.grid.2x2.fill") }
            NavigationStack { SWAYBeatsScreen() }
                .tag(SWAYTab.beats).tabItem { Label("Beats", systemImage: "waveform") }
            NavigationStack { SWAYProfileScreen() }
                .tag(SWAYTab.profile).tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(SWAYUI.pink)
        .toolbarBackground(SWAYUI.ink.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingOnboarding) { SWAYOnboardingScreen() }
        .task { showingOnboarding = !store.onboardingComplete }
    }
}

enum SWAYTab: Hashable { case home, moves, beats, profile }
