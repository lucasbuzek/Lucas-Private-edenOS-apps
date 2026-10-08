import SwiftUI
import UIKit

struct SWAYAvatarCreatorScreen: View {
    @EnvironmentObject private var store: SwayStore
    @Environment(\.dismiss) private var dismiss
    @State private var profile = SwayCharacterProfile()
    @State private var tab = "Style"
    private let tabs = ["Style", "Hair", "Face", "Outfit", "Body", "Shoes"]
    private var categories: [SWAYAvatarCategory] {
        switch tab { case "Style": return [.skin, .hairColor, .accessory]; case "Hair": return [.hair, .hairColor]; case "Face": return [.face, .skin]; case "Outfit": return [.top, .bottom, .accessory]; case "Body": return [.body]; default: return [.shoes] }
    }
    var body: some View { NavigationStack { ZStack { SWAYUI.ink.ignoresSafeArea(); VStack(spacing: 12) { SWAYCharacterStage(character: .yourDancer, source: .idle, profile: profile).frame(maxWidth: 360, maxHeight: 330).accessibilityLabel("Live Your Dancer preview"); ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(tabs, id: \.self) { item in Button { tab = item } label: { SWAYChip(title: item, selected: tab == item) }.buttonStyle(.plain) } }.padding(.horizontal) }; ScrollView { ForEach(categories, id: \.rawValue) { category in VStack(alignment: .leading) { Text(category.displayName.uppercased()).font(.caption.bold()).foregroundStyle(SWAYUI.secondary); LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))]) { ForEach(SWAYAvatarCatalog.options(category).filter(\.available)) { option in Button { SWAYAvatarCatalog.apply(option, to: &profile) } label: { VStack { Image(systemName: "sparkles").font(.title2); Text(option.displayName).font(.caption).lineLimit(2) }.frame(maxWidth: .infinity, minHeight: 88).background(SWAYAvatarCatalog.selectedIndex(category, in: profile) == option.index ? SWAYUI.violet : SWAYUI.card, in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain).accessibilityAddTraits(SWAYAvatarCatalog.selectedIndex(category, in: profile) == option.index ? .isSelected : []) } } }.padding(.horizontal) } }; Button("Save Your Dancer") { SWAYServiceAdapter.saveAvatar(store: store, profile: profile); dismiss() }.buttonStyle(SWAYPrimaryButtonStyle()).padding() } }.navigationTitle("Your Dancer").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }.onAppear { profile = store.character } } }
}

struct SWAYSettingsScreen: View {
    @EnvironmentObject private var store: SwayStore
    @State private var diagnosticsUnlocked = false
    @State private var taps = 0
    var body: some View { List { Section { Toggle("Camera Tracking", isOn: $store.cameraTrackingEnabled); Toggle("Low Impact", isOn: $store.lowImpact); Toggle("Small Space", isOn: $store.smallSpace) } header: { Text("Dance") }; Section("Connections") { permission("Camera", enabled: store.cameraTrackingEnabled); permission("Health", enabled: false); permission("Music", enabled: false) }; Section("Accessibility") { Toggle("Show Next Move", isOn: $store.showNextMove); Toggle("Show Coach Messages", isOn: $store.showCoachMessages); Text("SWAY follows Dynamic Type, VoiceOver, Reduce Motion and system contrast settings.").font(.caption).foregroundStyle(SWAYUI.secondary) }; Section { Button("SWAY 0.9 • Build 153") { taps += 1; diagnosticsUnlocked = taps >= 7 }.foregroundStyle(SWAYUI.secondary) }; if diagnosticsUnlocked { Section("Diagnostics") { NavigationLink("Camera Lab") { CameraLabView() }; NavigationLink("Native Capabilities") { NativeLabView() }; NavigationLink("Skeleton Diagnostics") { StickFigureView(moveID: "march", elapsed: 0, bpm: 100, paused: true, mirrored: false, characterMode: false) } } } }.navigationTitle("Settings").scrollContentBackground(.hidden).background(SWAYUI.ink).tint(SWAYUI.pink).onDisappear { store.save() } }
    private func permission(_ name: String, enabled: Bool) -> some View { HStack { Text(name); Spacer(); Text(enabled ? "Allowed" : "Not Connected").foregroundStyle(enabled ? SWAYUI.neon : SWAYUI.secondary) } }
}

struct SWAYRecordPreviewScreen: View {
    @State private var sharing = false
    var body: some View { SWAYScreen { VStack(spacing: 18) { Text("Record SWAY").font(.largeTitle.bold()).frame(maxWidth: .infinity, alignment: .leading); ZStack { SWAYUI.stage; SWAYCharacterStage(character: .yourDancer, source: .idle).padding(); Image(systemName: "play.circle.fill").font(.system(size: 64)).foregroundStyle(.white) }.frame(height: 440).clipShape(RoundedRectangle(cornerRadius: 28)); Button("Save Recording") { }.buttonStyle(SWAYPrimaryButtonStyle()); Button("Share") { sharing = true }.buttonStyle(SWAYSecondaryButtonStyle()) }.sheet(isPresented: $sharing) { VStack(spacing: 20) { Capsule().fill(.secondary).frame(width: 42, height: 5); Text("Share Your SWAY").font(.title.bold()); ShareLink(item: "I danced with SWAY!") { Label("Share Recording", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }.buttonStyle(SWAYPrimaryButtonStyle()); Text("Only the preview you choose is shared. Camera tracking data stays on this device.").font(.caption).foregroundStyle(SWAYUI.secondary) }.padding(24).presentationDetents([.medium]) } } }
}

struct SWAYOnboardingScreen: View {
    @EnvironmentObject private var store: SwayStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    var body: some View { ZStack { SWAYUI.stage.ignoresSafeArea(); VStack(spacing: 22) { Spacer(); SWAYCharacterStage(character: page == 2 ? .yourDancer : .lucia, source: .idle).frame(height: 340); Text(["WELCOME TO SWAY", "MOVE YOUR WAY", "READY TO DANCE?"][page]).font(.largeTitle.bold()).multilineTextAlignment(.center); Text(["Dance workouts that meet you where you are.", "Camera tracking is optional. Follow Along works anywhere.", "Choose a coach, make Your Dancer, and feel the music."][page]).multilineTextAlignment(.center).foregroundStyle(SWAYUI.secondary); Spacer(); Button(page == 2 ? "LET'S DANCE" : "CONTINUE") { if page < 2 { if reduceMotion { page += 1 } else { withAnimation { page += 1 } } } else { store.onboardingComplete = true; store.save(); dismiss() } }.buttonStyle(SWAYPrimaryButtonStyle()) }.padding(24) }.interactiveDismissDisabled() }
}

struct SWAYPermissionDeniedView: View {
    let capability: String
    var body: some View { VStack(spacing: 14) { Image(systemName: "lock.shield.fill").font(.system(size: 50)).foregroundStyle(SWAYUI.pink); Text("\(capability) Access Is Off").font(.title2.bold()); Text("You can keep using Follow Along, or allow access in Settings.").multilineTextAlignment(.center).foregroundStyle(SWAYUI.secondary); Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }.buttonStyle(SWAYPrimaryButtonStyle()) }.padding(24) }
}

struct SWAYEmptyStateView: View { let title: String; let message: String; var body: some View { VStack(spacing: 12) { Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(SWAYUI.pink); Text(title).font(.title2.bold()); Text(message).foregroundStyle(SWAYUI.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity, minHeight: 240) } }
