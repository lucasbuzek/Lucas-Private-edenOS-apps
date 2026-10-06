import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import MusicKit
import HealthKit

extension UTType {
    static let swayPack = UTType(exportedAs:"com.lucasbuzek.private.sway.swaypack",conformingTo:.json)
    static let swayBackup = UTType(exportedAs:"com.lucasbuzek.private.sway.swaybackup",conformingTo:.json)
}

struct SettingsView: View {
    @EnvironmentObject var store:SwayStore
    @State private var exportURL:URL?
    @State private var importing=false
    @State private var message=""
    @State private var portraitItem:PhotosPickerItem?
    @State private var backupURL:URL?
    @State private var restoringBackup=false
    @State private var confirmReset=false
    @State private var creatingAvatar=false
    @StateObject private var appleMusic=SwayMusicKitProvider()
    @StateObject private var health=SwayHealthWorkoutManager()
    @State private var permissionMessage=""

    private var characterImageLabel: String {
        store.character.portraitData == nil ? "Choose Profile Photo" : "Change Profile Photo"
    }

    private var musicAuthorizationLabel:String {
        switch appleMusic.authorization {
        case .authorized: return "Connected"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name / nickname",text:$store.profile.nickname)
                    .textInputAutocapitalization(.words)
                    .onSubmit { store.save() }
                Toggle("Show nickname on shared cards",isOn:$store.profile.share.showNickname)
                Picker("After a dance",selection:$store.profile.share.afterSession) {
                    ForEach(SwayAfterSessionAction.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField("Default share message",text:$store.profile.share.defaultMessage,axis:.vertical)
                Picker("Card format",selection:$store.profile.share.format) {
                    ForEach(SwayShareCardFormat.allCases) { Text($0.rawValue).tag($0) }
                }
                Button("Save profile settings") { store.save(); message="Profile saved" }
            }
            Section("SWAY Data") {
                Text("SWAY data is stored locally and is eligible for the device's normal backup unless the user disables app backup in system settings.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Prepare SWAY Backup") {
                    do { backupURL=try store.exportBackup(); message="Backup prepared" }
                    catch { message=error.localizedDescription }
                }
                if let backupURL { ShareLink(item:backupURL) { Label("Save / Share .swaybackup",systemImage:"externaldrive.badge.icloud") } }
                Button("Restore SWAY Backup") { restoringBackup=true }
            }
            Section("Your Dancer") {
                Button { creatingAvatar=true } label: { Label("Customize Dancer",systemImage:"person.crop.circle.badge.plus") }
                Text("Your dancer uses the same articulated choreography rig in Home, Learn and Workout.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Experience") {
                Toggle("Mirror instructor", isOn:$store.mirrored).onChange(of:store.mirrored){_,_ in store.save()}
                Toggle("Low impact default", isOn:$store.lowImpact).onChange(of:store.lowImpact){_,_ in store.save()}
                Toggle("Small-space default", isOn:$store.smallSpace).onChange(of:store.smallSpace){_,_ in store.save()}
                Stepper("Intensity \(store.intensity)", value:$store.intensity, in:1...4).onChange(of:store.intensity){_,_ in store.save()}
                Picker("Move complexity",selection:$store.moveComplexity) {
                    Text("Simple").tag(1); Text("Easy").tag(2); Text("Moderate").tag(3); Text("Complex").tag(4); Text("Expert").tag(5)
                }.onChange(of:store.moveComplexity){_,_ in store.save()}
                Picker("Visual rhythm cues",selection:$store.visualCueStrength) {
                    Text("Off").tag(0); Text("Minimal").tag(1); Text("Standard").tag(2); Text("Strong").tag(3)
                }.onChange(of:store.visualCueStrength){_,_ in store.save()}
                Toggle("Theme follows dance style",isOn:$store.automaticStyleThemes).onChange(of:store.automaticStyleThemes){_,_ in store.save()}
                Text("Movement tracking is chosen when you start a workout and calibrates on the same dance stage.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Music") {
                LabeledContent("Apple Music",value:musicAuthorizationLabel)
                Button(appleMusic.authorization == .authorized ? "Verify Music Access" : "Connect Apple Music") {
                    Task {
                        if appleMusic.authorization == .notDetermined { await appleMusic.requestAuthorization() } else { appleMusic.refreshAuthorization() }
                        permissionMessage="Apple Music: \(musicAuthorizationLabel)"
                    }
                }
                NavigationLink { SwayMusicCoreView() } label: { Label("Music & Library",systemImage:"music.note.list") }
                Text("SWAY Beats works offline. Apple Music is optional and only used when you choose it.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Health & Fitness") {
                LabeledContent("Workout data",value:health.authorizationSummary)
                Button(health.authorizationSummary == "Connected" ? "Verify Health Access" : "Connect Health") {
                    Task {
                        let requested=await health.requestAuthorization()
                        permissionMessage = health.errorMessage ?? (requested ? "Health request completed: \(health.authorizationSummary)" : "Health access was not changed.")
                    }
                }
                Text("Health is optional. SWAY can save completed workouts and use permitted fitness data; Health privacy prevents apps from exposing read-permission decisions as a simple granted/denied status.").font(.caption).foregroundStyle(.secondary)
                if !permissionMessage.isEmpty { Text(permissionMessage).font(.caption).foregroundStyle(.secondary) }
            }
            Section("Coach") {
                Picker("Coach personality",selection:$store.coachProfileID) {
                    Text(SwayCoachProfileID.lucia.displayName).tag(SwayCoachProfileID.lucia.rawValue)
                }.onChange(of:store.coachProfileID){_,_ in store.save()}
                Text("Lucia is the Alpha COACH. Additional COACH personalities arrive in Beta and share the same movement truth.").font(.caption).foregroundStyle(.secondary)
            }
            Section("During a Dance") {
                Toggle("Show YOU",isOn:$store.showYouOverlay)
                Toggle("Show count",isOn:$store.showWorkoutCounts)
                Toggle("Show next move",isOn:$store.showNextMove)
                Toggle("Coach cues",isOn:$store.showCoachMessages)
                Text("Camera video stays subtle. Tracking feedback appears in the same movement space as COACH.").font(.caption).foregroundStyle(.secondary)
            }.onChange(of:store.showYouOverlay){_,_ in store.save()}
             .onChange(of:store.showWorkoutCounts){_,_ in store.save()}
             .onChange(of:store.showNextMove){_,_ in store.save()}
             .onChange(of:store.showCoachMessages){_,_ in store.save()}
            Section("Progress") {
                Button("Reset workout progress",role:.destructive) { confirmReset=true }
                Text("Resets sessions, dance time, learned moves, awards and session results. Profile and preferences stay intact.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Content") {
                Button("Prepare My Moves .swaypack") { do { exportURL=try store.exportPackage(); message="Package prepared" } catch { message=error.localizedDescription } }
                if let exportURL { ShareLink(item:exportURL) { Label("Share / AirDrop package", systemImage:"square.and.arrow.up") } }
                Button("Import .swaypack") { importing=true }
            }
            if !message.isEmpty { Section { Text(message).font(.footnote) } }
        }
        .sheet(isPresented:$creatingAvatar) { SwayAvatarCreatorView().environmentObject(store) }
        .navigationTitle("Settings")
        .onAppear { appleMusic.refreshAuthorization() }
        .tint(SwayTheme.cyan)
        .preferredColorScheme(.dark)
        .confirmationDialog("Reset SWAY progress?",isPresented:$confirmReset,titleVisibility:.visible) {
            Button("Reset Progress",role:.destructive) { store.resetProgress(); message="Progress reset" }
            Button("Cancel",role:.cancel) {}
        }
        .onChange(of:store.profile.share.showNickname){_,_ in store.save()}
        .onChange(of:store.profile.share.afterSession){_,_ in store.save()}
        .onChange(of:store.profile.share.defaultMessage){_,_ in store.save()}
        .onChange(of:store.profile.share.format){_,_ in store.save()}
        .onChange(of:portraitItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type:Data.self) {
                    store.character.portraitData=data
                    store.save()
                }
            }
        }
        .fileImporter(isPresented:$importing, allowedContentTypes:[.swayPack,.json]) { result in
            do {
                let url=try result.get()
                let access=url.startAccessingSecurityScopedResource()
                defer{if access{url.stopAccessingSecurityScopedResource()}}
                try store.prepareImport(from:url); message="Ready to preview"
            } catch { message=error.localizedDescription }
        }
        .fileImporter(isPresented:$restoringBackup,allowedContentTypes:[.swayBackup,.json]) { result in
            do {
                let url=try result.get()
                let access=url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                try store.restoreBackup(from:url); message="SWAY backup restored"
            } catch { message=error.localizedDescription }
        }
    }
}


// MARK: - Product configuration hierarchy
struct SwayConfigurationGuideView: View {
    var body: some View {
        List {
            Section("Configuration depth") {
                LabeledContent("Simple",value:"Everyday SWAY")
                LabeledContent("Advanced",value:"Audio, cues, adaptation")
                LabeledContent("Expert",value:"Engine & creator controls")
            }
            Section("Privacy & Data") {
                Label("Camera — core movement sensor",systemImage:"camera.fill")
                Label("Health — optional workout recording",systemImage:"heart.fill")
                Label("Music — selected providers only",systemImage:"music.note")
                Label("SWAY progress — stored for app functionality",systemImage:"chart.line.uptrend.xyaxis")
                Text("Permissions can be revoked. Revoking access disables only functionality that depends on it; deleting previously stored SWAY progress is a separate action.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Developer & Diagnostics") {
                Text("Native Lab, pose confidence, provider diagnostics and transport diagnostics belong here rather than in the everyday dance interface.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Setup")
        .preferredColorScheme(.dark)
    }
}

struct SwayAvatarCreatorView: View {
    @EnvironmentObject var store:SwayStore
    @Environment(\.dismiss) private var dismiss
    @State private var category: Category = .skin
    @State private var previewMove = "step-touch"
    @State private var previewStart = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Category:String,CaseIterable,Identifiable {
        case body="Body", skin="Skin", hair="Hair Style", hairColor="Hair Colour", face="Face", outfit="Outfit", footwear="Shoes", accessory="Accessory"
        var id:String { rawValue }
        var symbol:String {
            switch self { case .body:return "figure.stand"; case .skin:return "face.smiling"; case .hair:return "person.crop.circle"; case .hairColor:return "paintpalette.fill"; case .face:return "face.smiling.inverse"; case .outfit:return "tshirt.fill"; case .footwear:return "shoe.fill"; case .accessory:return "sparkles" }
        }
    }

    private let bodyNames=["Neutral","Feminine","Masculine"]
    private let skinNames=["Light","Warm","Medium","Deep","Dark"]
    private let hairNames=["Short","Long","Braids","Afro","Bun"]
    private let faceNames=["Soft","Oval","Angular"]
    private let hairColorNames=["Espresso","Brown","Black","Auburn","Copper","Blonde"]
    private let outfitNames=["Studio","Power","Classic","Bright","Sport"]
    private let footwearNames=["Trainer","High-top","Dance","Barefoot"]
    private let accessoryNames=["None","Glasses","Headband","Wristband"]

    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:0) {
                    ZStack(alignment:.bottomLeading) {
                        SwayTheme.stageGradient
                        TimelineView(.animation(minimumInterval:1.0/30.0,paused:reduceMotion)) { timeline in
                            SwayAvatarPreview(character:store.character,moveID:previewMove,musicalTime:reduceMotion ? 0 : timeline.date.timeIntervalSince(previewStart),paused:reduceMotion)
                        }
                            .frame(maxWidth:.infinity,maxHeight:.infinity)
                            .padding(.horizontal,12).padding(.vertical,4)
                        Text("YOUR DANCER").font(.caption.bold()).tracking(1.4)
                            .foregroundStyle(.white.opacity(0.76)).padding(16)
                    }
                    .frame(maxWidth:.infinity,minHeight:300,idealHeight:360,maxHeight:420)
                    .clipShape(RoundedRectangle(cornerRadius:28))
                    .overlay(RoundedRectangle(cornerRadius:28).stroke(Color.white.opacity(0.10)))
                    .padding(.horizontal,16).padding(.top,8)
    
                    VStack(spacing:14) {
                        ScrollView(.horizontal,showsIndicators:false) {
                        HStack(spacing:8) {
                            ForEach(Category.allCases) { item in
                                Button {
                                    withAnimation(.easeInOut(duration:0.16)) { category=item }
                                } label: {
                                    Label(item.rawValue,systemImage:item.symbol)
                                        .font(.caption.bold())
                                        .padding(.horizontal,12)
                                        .frame(minHeight:44)
                                        .background(category == item ? SwayTheme.accent:SwayTheme.surfaceStrong,in:Capsule())
                                }.buttonStyle(.plain)
                            }
                        }
                        }
                        VStack(alignment:.leading,spacing:8) {
                            Text("PREVIEW MOVEMENT").font(.caption.bold()).foregroundStyle(.secondary)
                            HStack(spacing:8) {
                                ForEach([("Idle","idle"),("March","march"),("Groove","step-touch")],id:\.1) { item in
                                    Button(item.0) { previewMove=item.1; previewStart=Date() }
                                        .buttonStyle(.bordered)
                                        .tint(previewMove == item.1 ? SwayTheme.accent:SwayTheme.cyan)
                                }
                            }
                        }
                        Group {
                            switch category {
                            case .body: choiceRow(bodyNames,selection:SwayBodyStyle.allCases.firstIndex(of:store.character.bodyStyle) ?? 0){ store.character.bodyStyle=SwayBodyStyle.allCases[$0] }
                            case .skin: choiceRow(skinNames,selection:store.character.skinTone){store.character.skinTone=$0}
                            case .hair: choiceRow(hairNames,selection:store.character.hairStyle){store.character.hairStyle=$0}
                            case .hairColor: choiceRow(hairColorNames,selection:store.character.hairColor){store.character.hairColor=$0}
                            case .face: choiceRow(faceNames,selection:store.character.faceShape){store.character.faceShape=$0}
                            case .outfit: choiceRow(outfitNames,selection:store.character.outfitStyle){store.character.outfitStyle=$0}
                            case .footwear: choiceRow(footwearNames,selection:store.character.footwearStyle){store.character.footwearStyle=$0}
                            case .accessory: choiceRow(accessoryNames,selection:store.character.accessoryStyle){store.character.accessoryStyle=$0}
                            }
                        }
                        .frame(minHeight:54)
                        Text("Make your dancer yours. Changes are saved to your profile.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(SwayTheme.surface.opacity(0.96))
                }
            }
            .background(SwayTheme.background.ignoresSafeArea())
            .navigationTitle("Your Dancer").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.confirmationAction){Button("Done"){store.save();dismiss()}} }
        }.preferredColorScheme(.dark)
    }

    private func choiceRow(_ labels:[String],selection:Int,onSelect:@escaping(Int)->Void)->some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:10) {
                ForEach(labels.indices,id:\.self) { i in
                    Button { onSelect(i); store.save() } label: {
                        Text(labels[i]).font(.subheadline.bold()).padding(.horizontal,16)
                            .frame(minHeight:44)
                            .background(selection==i ? SwayTheme.accent:SwayTheme.surfaceStrong,in:Capsule())
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

struct SwayAvatarPreview:View {
    let character:SwayCharacterProfile
    var moveID:String="step-touch"
    var musicalTime:TimeInterval=0.22
    var paused:Bool=true
    var smile:Double=0; var brow:Double=0
    var body: some View {
        SWAYAvatarStageView(role:.user,moveID:moveID,elapsed:musicalTime,bpm:100,paused:paused,mirrored:false,cutout:AnyView(SWAYSkeletal2DAvatarView(role:.user,moveID:moveID,musicalTime:musicalTime,bpm:100,paused:paused,mirrored:false,profile:character)))
            .accessibilityLabel("Custom SWAY dancer preview")
    }
}


private extension Array { subscript(safe index:Int)->Element? { indices.contains(index) ? self[index]:nil } }


struct SwayImportPreviewView:View {
    @EnvironmentObject var store:SwayStore
    @Environment(\.dismiss) private var dismiss
    let package:SwayPackage
    var body:some View {
        NavigationStack {
            List {
                Section("Package") { LabeledContent("Title",value:package.metadata?.title ?? "Shared SWAY Content"); LabeledContent("Creator",value:package.creator); LabeledContent("Version",value:String(package.version)) }
                Section("Contents") { LabeledContent("Moves",value:String(package.moves.count)); LabeledContent("Combinations / routines",value:String(package.creations?.count ?? 0)); LabeledContent("Transitions",value:String(package.transitions.count)) }
                Section { Text("SWAY validates the package before this preview. Nothing is added until you choose Add to Library.").font(.caption).foregroundStyle(.secondary) }
                Button("ADD TO LIBRARY") { store.commitPendingImport(); dismiss() }.buttonStyle(.borderedProminent)
                Button("Cancel",role:.cancel) { store.pendingImport=nil; dismiss() }
            }.navigationTitle("Import Preview")
        }.preferredColorScheme(.dark)
    }
}
