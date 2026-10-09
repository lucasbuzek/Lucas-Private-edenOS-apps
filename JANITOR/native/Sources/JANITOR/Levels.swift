import SwiftUI
import AppKit

// MARK: - Disclosure levels (Simple / Advanced / Expert)
// A level only changes what is SHOWN. It never loosens a safety guard: every action still goes through
// preview -> confirm -> apply -> verify -> record, and keeper/quarantine protections apply at every level.

enum Level: Int, CaseIterable, Identifiable, Comparable {
    case simple = 0, advanced, expert
    var id: Int { rawValue }
    var label: String { ["Standard", "Advanced", "Expert"][rawValue] }
    static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }
}

struct LevelPicker: View {
    @EnvironmentObject var m: Model
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker("", selection: $m.level) {
                ForEach(Level.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden()
            Text(m.level == .simple ? "Essentials: the safe, everyday tools."
                 : m.level == .advanced ? "More tools and per-item control."
                 : "Everything, including permanent actions.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 10).padding(.top, 10)
    }
}

/// Per-feature expander: reveals the next level for one screen without changing the global level.
struct MoreOptions: View {
    @EnvironmentObject var m: Model
    let feature: String
    var body: some View {
        let cur = m.effective(feature)
        HStack(spacing: 14) {
            if cur < .expert {
                Button(cur == .simple ? "More options…" : "Even more options (Expert)…") { m.expand(feature) }
            }
            if cur > m.level {
                Button("Fewer options") { m.collapse(feature) }
            }
            Text("Showing: \(cur.label)").font(.caption).foregroundStyle(.secondary)
        }
        .buttonStyle(.link).font(.callout)
    }
}

// MARK: - Shell

struct RootView: View {
    var body: some View { FinderShellView() }
}


struct ModeView: View {
    @EnvironmentObject var m: Model
    var body: some View {
        switch m.mode {
        case .clean: CleanView()
        case .organize: OrganizeView()
        case .crew: FullCrewView()
        case .recovery: QuarantineView()
        case .developer: DeveloperView()
        case .tools: SettingsView()
        }
    }
}

// MARK: - Clean

struct CleanView: View {
    @EnvironmentObject var m: Model
    @State private var confirmOld = false

    var body: some View {
        let lv = m.effective(Model.Mode.clean.rawValue)
        Scaffold(title: "Clean",
                 subtitle: "Find what is safe to remove. Nothing changes until you review and confirm, and everything you remove can be undone from Recovery.",
                 feature: Model.Mode.clean.rawValue) {
            Btn("Check my Mac", "bolt") { m.run("Quick Scan") { Modes.quick(full: false) } }
            Btn("Storage overview", "internaldrive") { m.run("Storage Overview") { Modes.overview() } }
            Btn("Storage folder map", "square.grid.3x3.fill") { let r = m.workRoot; m.run("Storage treemap") { Modes.storageTreemap(root: r) } }
            Btn("Interactive storage treemap", "rectangle.split.3x3") { m.showTreemap = true }
            if lv >= .advanced {
                Btn("Deeper check", "magnifyingglass") { m.run("Full Scan") { Modes.quick(full: true) } }
                Btn("Choose what to check…", "folder") { m.chooseAndScan() }
            }
            if lv >= .expert {
                Btn("Delete recovery items > 30 days…", "clock.arrow.circlepath") { m.refreshOps(); confirmOld = true }
            }
        }
        .sheet(isPresented: $m.showTreemap) { TreemapWindow(root: m.workRoot ?? Storage.home) }
        .confirmationDialog("Delete \(m.oldOps(days: 30).count) quarantine operation(s) older than 30 days?", isPresented: $confirmOld, titleVisibility: .visible) {
            Button("Delete permanently", role: .destructive) { m.deleteOps(m.oldOps(days: 30)) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Their items can no longer be restored.") }
    }
}

// MARK: - Organize (file organisation / management)

struct OrganizeView: View {
    @EnvironmentObject var m: Model
    var body: some View {
        let lv = m.effective(Model.Mode.organize.rawValue)
        Scaffold(title: "Organize",
                 subtitle: "Find duplicate and large files and keep your folders tidy. Local media only: cloud-provider folders and Photos libraries are never scanned or changed. Nothing is removed automatically.",
                 rootHint: lv >= .advanced ? "Movies, Music, Pictures, Downloads" : nil,
                 feature: Model.Mode.organize.rawValue) {
            Btn("Find duplicate files", "doc.on.doc") { let r = m.workRoot; m.run("Exact duplicates") { Modes.duplicates(root: r) } }
            Btn("Find visually similar images", "photo.stack") { let r = m.workRoot; m.run("Similar images") { Modes.similarImages(root: r) } }
            Btn("Find large media", "film") { let r = m.workRoot; m.run("Media inventory") { Modes.media(root: r) } }
            if lv >= .advanced {
                Btn("Similar file names", "textformat") { let r = m.workRoot; m.run("Similar names") { Modes.similarNames(root: r) } }
                Btn("Photos library footprint", "photo.on.rectangle") { m.run("Photos footprint") { Modes.photosFootprint() } }
                Btn("Projects and versions", "square.stack.3d.up") { let r = m.devRoot; m.run("Project discovery") { Modes.projects(root: r) } }
            }
        }
    }
}

// MARK: - Full Crew (read-only diagnostics, available at every level)

struct FullCrewView: View {
    @EnvironmentObject var m: Model
    var body: some View {
        let lv = m.effective(Model.Mode.crew.rawValue)
        Scaffold(title: "Full Crew",
                 subtitle: "Inspect processes, startup items and installed apps. Expert mode can quarantine a selected user-installed app with confirmation and recovery; no support files are removed.",
                 rootHint: lv >= .advanced ? "home folder (Broken Items)" : nil,
                 feature: Model.Mode.crew.rawValue) {
            Btn("What is running", "cpu") { m.run("Processes") { Modes.processes() } }
            if lv >= .expert { Btn("Request user app to quit…", "xmark.app") { m.chooseUserAppToQuit() } }
            Btn("What starts automatically", "power") { m.run("Startup items") { Modes.startup() } }
            if lv >= .expert { Btn("Disable user login agent…", "power.circle") { m.chooseUserLaunchAgent() } }
            Btn("Installed apps", "square.grid.2x2") { m.run("Installed apps") { Modes.appsInventory() } }
            Btn("Review uninstall ownership", "app.badge.checkmark") { m.run("App uninstall review") { Modes.appUninstallReview() } }
            if lv >= .expert { Btn("Quarantine user-installed app…", "app.badge") { m.chooseAppForQuarantine() } }
            Btn("Cloud provider boundaries", "icloud") { m.run("Cloud residency") { Modes.cloudResidency() } }
            Btn("Native Photos inventory", "photo.on.rectangle.angled") { m.run("PhotoKit inventory") { Modes.photoKitInventory() } }
            Btn("Inspect cloud file residency…", "icloud.and.arrow.down") { m.chooseCloudItemMetadata() }
            Btn("App support files", "tray.full") { m.run("Support inventory") { Modes.supportInventory() } }
            Btn("Broken shortcuts", "link.badge.plus") { let r = m.workRoot ?? Storage.home; m.run("Broken items") { Modes.broken(root: r) } }
            Btn("What grew lately", "chart.bar") { m.run("Storage diagnostics") { Modes.storageGrowth() } }
        }
    }
}

// MARK: - Developer (Expert only; inspection first)

struct DeveloperView: View {
    @EnvironmentObject var m: Model
    @State private var confirmBrew = false
    @State private var confirmSim = false
    var body: some View {
        let lv = m.effective(Model.Mode.developer.rawValue)
        Scaffold(title: "Developer",
                 subtitle: "Inspect software-development leftovers and recover disk space. Review findings before any changes; active projects and Git data are protected.",
                 rootHint: "auto (\(Modes.abbrev(Modes.defaultDevRoot().path)))",
                 feature: Model.Mode.developer.rawValue) {
            Btn("Find development leftovers", "externaldrive.badge.magnifyingglass") { m.run("Developer Quick") { Modes.devQuick() } }
            Btn("Find projects and versions", "square.stack.3d.up") { let r = m.devRoot; m.run("Project discovery") { Modes.projects(root: r) } }
            Btn("Preview Homebrew cleanup", "eye") { m.run("Homebrew preview") { Maint.brew(dryRun: true) } }
            Btn("Run Homebrew cleanup…", "shippingbox") { confirmBrew = true }
            Btn("Review unavailable simulators", "iphone") { m.run("Simulator preview") { Maint.simulators(dryRun: true) } }
            if lv >= .expert {
                Btn("Review old build versions", "list.number") { let r = m.devRoot; m.run("Build families") { Modes.buildFamilies(root: r) } }
                Btn("Inspect build dependencies", "shippingbox") { let r = m.devRoot; m.run("Dependency discovery") { Modes.dependencies(root: r) } }
                Btn("Remove unavailable simulators…", "trash") { confirmSim = true }
            }
        }
        .confirmationDialog("Run Homebrew cleanup?", isPresented: $confirmBrew) {
            Button("Run cleanup") { m.run("Homebrew cleanup") { Maint.brew(dryRun: false) } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Uses Homebrew cleanup. Review the preview first.") }
        .confirmationDialog("Remove unavailable simulators?", isPresented: $confirmSim) {
            Button("Remove unavailable simulators", role: .destructive) { m.run("Remove simulators") { Maint.simulators(dryRun: false) } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Uses native Xcode simctl, only for unavailable simulators.") }
    }
}
