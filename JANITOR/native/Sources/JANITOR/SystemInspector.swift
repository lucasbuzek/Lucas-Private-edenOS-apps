import Foundation
import Photos

/// One on-demand, read-only snapshot. No background service, provider hydration or deletion.
struct SystemCheckReport: Sendable {
    enum State: String, Sendable {
        case attention = "Attention"
        case opportunity = "Worth reviewing"
        case normal = "No issue detected"
        case unchecked = "Not fully checked"
    }

    struct Area: Identifiable, Sendable {
        let id: String
        let title: String
        let state: State
        let summary: String
        let detail: String
    }

    struct Advice: Identifiable, Sendable {
        let id: String
        let title: String
        let reason: String
        let priority: State
        let action: String
    }

    let finishedAt: Date
    let areas: [Area]
    let recommendations: [Advice]
    let suggestedCount: Int
    let suggestedBytes: Int64
    let manualCount: Int
    let checkedLocations: Int
    let incompleteLocations: Int
    let notes: [String]
}

enum SystemInspector {
    static func inspect() -> SystemCheckReport {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        var areas: [SystemCheckReport.Area] = []
        var advice: [SystemCheckReport.Advice] = []
        var notes: [String] = []

        // Filesystem statistics are metadata only; no disk health claim follows from free space.
        let attributes = try? fm.attributesOfFileSystem(forPath: home.path)
        let total = (attributes?[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free = (attributes?[.systemFreeSize] as? NSNumber)?.int64Value ?? -1
        if total > 0 && free >= 0 {
            let ratio = Double(free) / Double(total)
            if ratio < 0.10 {
                areas.append(.init(id: "storage", title: "Storage", state: .attention,
                                   summary: "\(fmtBytes(free)) available",
                                   detail: "Less than 10% of the reported volume capacity is free."))
                advice.append(.init(id: "storage", title: "Examine storage usage",
                                    reason: "Only \(fmtBytes(free)) is free on the inspected volume.",
                                    priority: .attention, action: "storage"))
            } else {
                areas.append(.init(id: "storage", title: "Storage", state: .normal,
                                   summary: "\(fmtBytes(free)) available of \(fmtBytes(total))",
                                   detail: "Free capacity checked. Hardware health and disk errors were not tested."))
            }
        } else {
            areas.append(.init(id: "storage", title: "Storage", state: .unchecked,
                               summary: "Capacity could not be measured",
                               detail: "No estimate was made. Open Storage for further information."))
            advice.append(.init(id: "storage", title: "Check storage",
                                reason: "Available capacity could not be determined.",
                                priority: .opportunity, action: "storage"))
        }

        // Reuse JANITOR's bounded, protected-path-aware native quick scan.
        // This is a review inventory, never a reclaimable-space guarantee.
        let quick = Modes.quick(full: false)
        let suggested = quick.candidates.filter { $0.preselect }
        let manual = quick.candidates.filter { !$0.preselect }
        let suggestedBytes = suggested.reduce(Int64(0)) { $0 + max($1.bytes, 0) }
        let incomplete = quick.roots.filter { $0.status != .complete }.count
        let checked = quick.roots.filter { $0.status == .complete }.count
        if incomplete > 0 {
            areas.append(.init(id: "maintenance", title: "Temporary files", state: .unchecked,
                               summary: "\(suggested.count) suggested; \(incomplete) locations not fully checked",
                               detail: "The scan was bounded, so some findings may be missing. Only explicit local candidates can be reviewed."))
        } else if !suggested.isEmpty || !manual.isEmpty {
            areas.append(.init(id: "maintenance", title: "Temporary files", state: .opportunity,
                               summary: "\(suggested.count) suggested; \(manual.count) need individual review",
                               detail: "These are possible cleanup candidates, not proof that removal is necessary."))
        } else {
            areas.append(.init(id: "maintenance", title: "Temporary files", state: checked > 0 ? .normal : .unchecked,
                               summary: checked > 0 ? "No cleanup candidates found in checked locations" : "No local cleanup roots checked",
                               detail: "Results cover only the bounded quick-scan locations."))
        }
        if !quick.candidates.isEmpty {
            advice.append(.init(id: "cleanup", title: "Review temporary files",
                                reason: "\(suggested.count) items marked for review (\(fmtBytes(suggestedBytes))); \(manual.count) require individual judgment.",
                                priority: .opportunity, action: "quick"))
        }
        if incomplete > 0 {
            advice.append(.init(id: "deeper", title: "Run a more detailed check",
                                reason: "\(incomplete) scan locations were incomplete or skipped.",
                                priority: .opportunity, action: "full"))
        }

        // Only current-user LaunchAgents are inspected; System Settings Login Items
        // and system/third-party background processes are NOT thereby proven safe.
        let agents = home.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        let agentNames = (Scan.listChildren(agents) ?? []).filter { $0.pathExtension.lowercased() == "plist" }
        areas.append(.init(id: "startup", title: "Apps & startup", state: .unchecked,
                           summary: "\(agentNames.count) user LaunchAgent file(s)",
                           detail: "Login Items, running background jobs and their health were not fully checked."))
        if !agentNames.isEmpty {
            advice.append(.init(id: "startup", title: "Review what starts automatically",
                                reason: "\(agentNames.count) user LaunchAgent entries were found. This is informational, not a problem diagnosis.",
                                priority: .opportunity, action: "startup"))
        }

        // Media duplicate checks require the user's explicit root and more I/O.
        areas.append(.init(id: "media", title: "Media & duplicates", state: .unchecked,
                           summary: "Deep duplicate scan not run",
                           detail: "Checking content equality can take time. Choose Duplicates when you want to inspect local files."))
        advice.append(.init(id: "media", title: "Look for duplicate files",
                            reason: "This optional check was not run during the quick system inspection.",
                            priority: .opportunity, action: "duplicates"))

        // Provider boundaries: metadata about container locations, not cloud residency.
        let cloudFolder = home.appendingPathComponent("Library/CloudStorage", isDirectory: true)
        let providers = Scan.listChildren(cloudFolder) ?? []
        let hasICloud = Storage.iCloudActive
        let photosStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let photoAccess: String
        switch photosStatus {
        case .authorized: photoAccess = "Photos access authorized"
        case .limited: photoAccess = "Limited Photos access"
        case .notDetermined: photoAccess = "Photos access not requested"
        case .denied: photoAccess = "Photos access denied"
        case .restricted: photoAccess = "Photos access restricted"
        @unknown default: photoAccess = "Photos access status unknown"
        }
        areas.append(.init(id: "cloud", title: "Cloud & Photos", state: .unchecked,
                           summary: "\(providers.count) cloud-provider location(s)\(hasICloud ? "; iCloud Drive detected" : "")",
                           detail: "\(photoAccess). Cloud-file residency and Photos local-versus-cloud storage are unknown. No content was downloaded."))
        if !providers.isEmpty || hasICloud {
            advice.append(.init(id: "cloud", title: "Review cloud storage boundaries",
                                reason: "Cloud-managed locations were detected, but files were not opened or downloaded.",
                                priority: .opportunity, action: "cloud"))
        }
        notes.append("This quick check does not measure disk hardware health, malware, system integrity or backups.")
        notes.append("Cloud residency, Photos reclaimability and media duplicates are not inferred from metadata.")
        notes.append("No scanned files or system settings were changed. JANITOR saves a local diagnostic report; recommended actions open separate review workflows.")

        return SystemCheckReport(finishedAt: Date(), areas: areas,
                                 recommendations: advice,
                                 suggestedCount: suggested.count,
                                 suggestedBytes: suggestedBytes,
                                 manualCount: manual.count,
                                 checkedLocations: checked,
                                 incompleteLocations: incomplete,
                                 notes: notes)
    }
}
