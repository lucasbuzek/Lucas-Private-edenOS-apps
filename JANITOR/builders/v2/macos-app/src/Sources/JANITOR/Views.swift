import SwiftUI
import AppKit

func statusColor(_ s: ScanStatus) -> Color {
    switch s {
    case .complete: return .green
    case .partial: return .orange
    case .review: return .yellow
    case .skipped: return .gray
    case .protected: return .red
    case .deferred: return .blue
    }
}

func stateColor(_ s: String) -> Color {
    switch s {
    case "MOVED", "DELETED", "RESTORED": return .green
    case "FAILED": return .red
    case "MISSING": return .orange
    default: return .gray
    }
}

func friendlyCategory(_ raw: String) -> String {
    switch raw {
    case "CACHE": return "App cache"
    case "SAFE CACHE": return "Safe cache"
    case "CONTAINER CACHE": return "App cache"
    case "LOG": return "Log files"
    case "TRASH": return "Trash"
    case "TEMP": return "Temporary files"
    case "BUILD OUTPUT": return "Build files"
    case "PROJECT DATA": return "Project data"
    case "EXACT DUPLICATE": return "Duplicate copy"
    case "LARGE MEDIA": return "Large media"
    case "SUPPORT": return "App support files"
    case "BROKEN LINK": return "Broken shortcut"
    case "UNKNOWN": return "Needs review"
    default: return raw.lowercased().replacingOccurrences(of: "_", with: " ").capitalized
    }
}

func friendlyReason(_ c: Candidate) -> String {
    if c.keeper != nil { return "An identical copy is being kept elsewhere." }
    switch c.category {
    case "CACHE", "SAFE CACHE", "CONTAINER CACHE": return c.preselect ? "Temporary app data that can be recreated." : "System or app cache. Review before removing."
    case "LOG": return "Diagnostic log data that is normally safe to clear."
    case "TRASH": return "Already in the Trash."
    case "TEMP": return "Old temporary data no longer expected to be in active use."
    case "BUILD OUTPUT": return "Generated developer build data; source files are not included."
    case "PROJECT DATA": return "Project-related data. JANITOR will not assume it is disposable."
    default: return c.note.isEmpty ? (c.preselect ? "JANITOR considers this recoverable or regenerable." : "JANITOR needs you to review this item.") : c.note
    }
}

func categoryColor(_ c: Candidate) -> Color {
    if c.preselect { return .green }
    if c.keeper != nil { return .blue }
    if c.category.contains("PROJECT") || c.category.contains("UNKNOWN") { return .orange }
    return .orange
}

struct Pill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text).font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.22), in: Capsule())
            .foregroundStyle(color)
    }
}

struct Btn: View {
    let title: String
    let icon: String
    let action: () -> Void
    init(_ title: String, _ icon: String, _ action: @escaping () -> Void) { self.title = title; self.icon = icon; self.action = action }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color(red: 0.32, green: 0.62, blue: 1.0))
                    .background(Color.blue.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title).font(.system(size: 13, weight: .medium))
                Spacer(minLength: 6)
                Image(systemName: "chevron.right").font(.caption2.bold()).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(red: 0.13, green: 0.16, blue: 0.23), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.09), lineWidth: 1))
    }
}

struct RootBar: View {
    @EnvironmentObject var m: Model
    let hint: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope").foregroundStyle(.secondary)
            Text("Root").font(.caption.bold()).foregroundStyle(.secondary)
            Text(m.workRoot.map { Modes.abbrev($0.path) } ?? hint).font(.callout).lineLimit(1)
            Spacer()
            Button("Choose…") { m.chooseWorkRoot() }
            if m.workRoot != nil { Button("Reset") { m.workRoot = nil } }
        }
        .padding(10)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct Scaffold<Buttons: View>: View {
    @EnvironmentObject var m: Model
    let title: String
    let subtitle: String
    let rootHint: String?
    let feature: String?
    let buttons: Buttons

    init(title: String, subtitle: String, rootHint: String? = nil, feature: String? = nil, @ViewBuilder buttons: () -> Buttons) {
        self.title = title; self.subtitle = subtitle; self.rootHint = rootHint; self.feature = feature; self.buttons = buttons()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 28, weight: .bold, design: .rounded))
                Text(subtitle).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            if let h = rootHint { RootBar(hint: h) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 235), spacing: 10)], alignment: .leading, spacing: 10) { buttons }
                .disabled(m.busy)
            if let f = feature { MoreOptions(feature: f) }
            Divider().opacity(0.6)
            ResultsView()
        }
        .padding(.horizontal, 22).padding(.top, 20)
        .frame(maxWidth: 1120, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.09, blue: 0.14))
    }

}

// MARK: - Results

struct ResultsView: View {
    @EnvironmentObject var m: Model
    @State private var confirmQ = false
    @State private var confirmD = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if m.busy {
                    HStack { ProgressView().controlSize(.small); Text(m.busyTitle); Button("Cancel") { m.cancel() } }
                }
                if let o = m.out { content(o) }
                if !m.message.isEmpty { Text(m.message).font(.headline) }
                if !m.results.isEmpty { ActionResultsView(results: m.results) }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    func content(_ o: ScanOutput) -> some View {
        Text(o.title).font(.headline)
        ForEach(Array(o.lines.enumerated()), id: \.offset) { _, l in Text(l).font(.callout) }

        if !o.roots.isEmpty {
            DisclosureGroup("Roots (\(o.roots.count))") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(o.roots) { r in
                        HStack(alignment: .firstTextBaseline) {
                            Pill(text: r.status.rawValue, color: statusColor(r.status))
                            Text("\(r.storage.rawValue) · \(Modes.abbrev(r.path)) · \(fmtOrDash(r.bytes))\(r.note.isEmpty ? "" : " · " + r.note)")
                                .font(.caption)
                        }
                    }
                }.padding(.vertical, 4)
            }
        }

        ForEach(o.sections) { s in
            DisclosureGroup("\(s.title) (\(s.rows.count))") {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(s.rows.enumerated()), id: \.offset) { _, r in
                        Text(r).font(.caption.monospaced()).textSelection(.enabled)
                    }
                }.padding(.vertical, 4)
            }
        }

        if !o.candidates.isEmpty { candidateList(o) }
    }

    /// Simple level: one row per category instead of one per file. Groups that are neither SAFE nor duplicate
    /// copies (with a recorded kept copy) cannot be bulk-selected here; they need "More options" to review file by file.
    @ViewBuilder
    func groupedList(_ o: ScanOutput) -> some View {
        let groups = Dictionary(grouping: o.candidates, by: { $0.category }).sorted { $0.key < $1.key }
        ForEach(groups, id: \.key) { g in
            let ids = Set(g.value.map { $0.id })
            let safe = g.value.allSatisfy { $0.preselect }
            let dupes = g.value.allSatisfy { $0.keeper != nil }
            let size = g.value.reduce(Int64(0)) { $0 + $1.bytes }
            HStack(alignment: .top) {
                Toggle("", isOn: Binding(get: { ids.isSubset(of: m.selection) },
                                         set: { on in if on { m.selection.formUnion(ids) } else { m.selection.subtract(ids) } }))
                    .labelsHidden().disabled(!(safe || dupes))
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(friendlyCategory(g.key)).bold()
                        Pill(text: safe ? "SAFE TO RECOVER" : "REVIEW FIRST", color: safe ? .green : .orange)
                        Spacer()
                        Text(size > 0 ? fmtBytes(size) : "—").monospacedDigit()
                    }
                    Text("\(g.value.count) item(s)" + ((safe || dupes) ? "" : " · open “More options” to review these one by one"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        Text("Want to see each file first? Use “More options…” above.").font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder
    func candidateList(_ o: ScanOutput) -> some View {
        let sel = m.selected()
        let lv = m.effective()
        let bytes = sel.reduce(Int64(0)) { $0 + $1.bytes }
        Divider()
        HStack {
            Text("Review (\(o.candidates.count))").font(.headline)
            Spacer()
            if lv >= .advanced { Button("Select all") { m.selection = Set(o.candidates.map { $0.id }) } }
            Button("None") { m.selection = [] }
            Button("Safe only") { m.selection = Set(o.candidates.filter { $0.preselect }.map { $0.id }) }
        }
        if lv == .simple { groupedList(o) } else {
        ForEach(o.candidates) { c in
            HStack(alignment: .top) {
                Toggle("", isOn: Binding(get: { m.selection.contains(c.id) },
                                         set: { on in if on { m.selection.insert(c.id) } else { m.selection.remove(c.id) } }))
                    .labelsHidden()
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(c.title).bold().lineLimit(1)
                        Pill(text: friendlyCategory(c.category), color: categoryColor(c))
                        Spacer()
                        Text(c.bytes > 0 ? fmtBytes(c.bytes) : "—").monospacedDigit()
                    }
                    Text(friendlyReason(c))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Text(Modes.abbrev(c.url.path))
                        .font(.caption2.monospaced()).foregroundStyle(.tertiary).lineLimit(1).textSelection(.enabled)
                }
            }
        }
        }
        HStack {
            Text("\(sel.count) selected · \(fmtBytes(bytes))").font(.callout)
            Spacer()
            Button(lv == .simple ? "Move selected to Recovery…" : "Quarantine selected…") { confirmQ = true }.disabled(sel.isEmpty || m.busy)
            if lv == .expert { Button("Delete selected…", role: .destructive) { confirmD = true }.disabled(sel.isEmpty || m.busy) }
        }
        .confirmationDialog("Move \(sel.count) item(s) (\(fmtBytes(bytes))) to quarantine?", isPresented: $confirmQ, titleVisibility: .visible) {
            Button("Quarantine") { m.quarantineSelected() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Items stay recoverable under QUARANTINE / RECOVERY. Each move is verified.") }
        .confirmationDialog("Permanently delete \(sel.count) item(s) (\(fmtBytes(bytes)))?", isPresented: $confirmD, titleVisibility: .visible) {
            Button("Delete permanently", role: .destructive) { m.deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This cannot be undone. Choose Quarantine instead if you may want these back.") }
    }
}

struct ActionResultsView: View {
    let results: [ActionResult]
    var body: some View {
        DisclosureGroup("Result per item (\(results.count))", isExpanded: .constant(true)) {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(results) { r in
                    HStack(alignment: .firstTextBaseline) {
                        Pill(text: r.state, color: stateColor(r.state))
                        Text("\(r.name) — \(r.detail)").font(.caption).textSelection(.enabled)
                    }
                }
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Modes

struct QuarantineView: View {
    @EnvironmentObject var m: Model
    @State private var deleteTarget: QOp?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recovery").font(.title2.bold())
                Spacer()
                Button("Refresh") { m.refreshOps() }
                Button("Reveal root") { reveal(Prefs.quarantineRoot) }
            }
            MoreOptions(feature: Model.Mode.recovery.rawValue)
            Text("Root: \(Modes.abbrev(Prefs.quarantineRoot.path)) — items removed by hand are marked MISSING and never block the manager.")
                .font(.callout).foregroundStyle(.secondary)
            if m.busy { HStack { ProgressView().controlSize(.small); Text(m.busyTitle) } }
            if m.ops.isEmpty { Text("No quarantine operations yet.").foregroundStyle(.secondary) }
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(m.ops) { op in opView(op) }
                    if !m.message.isEmpty { Text(m.message).font(.headline) }
                    if !m.results.isEmpty { ActionResultsView(results: m.results) }
                }
            }
        }
        .padding()
        .onAppear { m.refreshOps() }
        .confirmationDialog("Delete this quarantine operation permanently?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), titleVisibility: .visible) {
            Button("Delete permanently", role: .destructive) { if let t = deleteTarget { m.deleteOps([t]) }; deleteTarget = nil }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        } message: { Text("Items still inside can no longer be restored.") }
    }

    func reveal(_ u: URL) {
        if Quarantine.present(u.path) { NSWorkspace.shared.activateFileViewerSelecting([u]) }
        else { NSWorkspace.shared.activateFileViewerSelecting([u.deletingLastPathComponent()]) }
    }

    @ViewBuilder
    func opView(_ op: QOp) -> some View {
        let moved = op.manifest.items.filter { $0.state == "MOVED" }
        let missing = op.manifest.items.filter { $0.state == "MISSING" }.count
        DisclosureGroup(isExpanded: Binding(get: { m.openOp == op.id }, set: { m.openOp = $0 ? op.id : nil })) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(op.manifest.items) { it in
                    HStack(alignment: .top) {
                        if m.effective() >= .advanced {
                            Toggle("", isOn: Binding(get: { m.opSelection.contains(it.id) },
                                                     set: { on in if on { m.opSelection.insert(it.id) } else { m.opSelection.remove(it.id) } }))
                                .labelsHidden().disabled(it.state != "MOVED")
                        }
                        Pill(text: it.state, color: stateColor(it.state))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(URL(fileURLWithPath: it.original).lastPathComponent).bold()
                            Text("\(Modes.abbrev(it.original)) · \(it.reason) · \(fmtBytes(it.bytes))").font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                        }
                    }
                }
                HStack {
                    if m.effective() >= .advanced {
                        Button("Restore selected") { m.restore(op, ids: m.opSelection) }
                            .disabled(m.opSelection.isEmpty || m.busy)
                    }
                    Button(m.effective() == .simple ? "Undo this clean-up" : "Restore all") { m.restore(op, ids: nil) }.disabled(moved.isEmpty || m.busy)
                    Button("Reveal") { reveal(op.folder) }
                    if m.effective() >= .expert { Button("Delete operation…", role: .destructive) { deleteTarget = op }.disabled(m.busy) }
                }
            }.padding(.vertical, 4)
        } label: {
            Text("\(op.id) — \(op.manifest.items.count) item(s), \(moved.count) in quarantine\(missing > 0 ? ", \(missing) MISSING" : "") · \(fmtBytes(moved.reduce(Int64(0)) { $0 + $1.bytes }))")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var m: Model
    @AppStorage("timeout") private var timeout: Double = 6
    @AppStorage("maxDepth") private var maxDepth: Int = 4
    @AppStorage("quarantineRoot") private var qRoot: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tools").font(.title2.bold())
            if m.effective() >= .expert {
            Stepper("Per-root time budget: \(Int(timeout)) s", value: $timeout, in: 2...60, step: 1)
            Stepper("Discovery depth: \(maxDepth)", value: $maxDepth, in: 2...6)
            HStack {
                Text("Quarantine root: \(qRoot.isEmpty ? Modes.abbrev(Prefs.defaultQuarantineRoot.path) : Modes.abbrev(qRoot))").font(.callout)
                Button("Choose…") { m.chooseQuarantineRoot() }
                if !qRoot.isEmpty { Button("Reset") { qRoot = "" } }
            }
            RootBar(hint: "auto (per mode)")
            }
            MoreOptions(feature: Model.Mode.tools.rawValue)
            HStack {
                Button("Run Diagnostics") { m.run("Diagnostics") { Modes.diagnostics() } }.disabled(m.busy)
                Button("Open reports folder") {
                    try? FileManager.default.createDirectory(at: Report.dir, withIntermediateDirectories: true)
                    NSWorkspace.shared.open(Report.dir)
                }
            }
            Divider()
            ResultsView()
        }
        .padding()
    }
}
