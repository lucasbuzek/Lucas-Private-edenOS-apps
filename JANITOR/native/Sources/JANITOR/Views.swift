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
    init(_ title: String, _ icon: String, _ action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.action = action
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 22)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))
        .accessibilityHint("Run this check or open its options")
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
    @State private var showTools = true
    let title: String
    let subtitle: String
    let rootHint: String?
    let feature: String?
    let buttons: Buttons

    init(title: String, subtitle: String, rootHint: String? = nil, feature: String? = nil, @ViewBuilder buttons: () -> Buttons) {
        self.title = title; self.subtitle = subtitle; self.rootHint = rootHint
        self.feature = feature; self.buttons = buttons()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.system(size: 24, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let h = rootHint { RootBar(hint: h) }
            HStack {
                Text("Tools").font(.subheadline.bold())
                Spacer()
                Button(showTools ? "Hide tools" : "Show tools") {
                    withAnimation(.easeInOut(duration: 0.16)) { showTools.toggle() }
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(showTools ? "Collapse tool list" : "Expand tool list")
            }
            if showTools {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 205), spacing: 7)], alignment: .leading, spacing: 7) {
                    buttons
                }
                .disabled(m.busy)
                if let f = feature { MoreOptions(feature: f) }
            }
            Divider()
            ResultsView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 17)
        .padding(.top, 13)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: m.busy) { isBusy in
            if !isBusy && m.out != nil { withAnimation { showTools = false } }
        }
        .onAppear { if m.out != nil { showTools = false } }
    }
}

// MARK: - Results

struct ResultsView: View {
    @EnvironmentObject var m: Model
    @State private var confirmQ = false
    @State private var confirmD = false
    @State private var showTechnical = false
    @State private var showOtherFindings = false

    private func totalBytes(_ items: [Candidate]) -> Int64 {
        items.reduce(Int64(0)) { $0 + max($1.bytes, 0) }
    }

    private func plainNotice(_ text: String) -> String? {
        let x = text.lowercased()
        if x.contains("xcode is running") {
            return "Xcode is open. Active build files have not been automatically selected."
        }
        if x.contains("homebrew cache present") {
            return "Homebrew manages its own cache. Use the Homebrew preview before cleaning it."
        }
        if x.contains("cancelled") {
            return "The check was stopped early. These results may be incomplete."
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 11) {
                    if m.busy {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(m.busyTitle).font(.subheadline)
                            Spacer()
                            Button("Cancel") { m.cancel() }
                        }
                    }
                    if !m.results.isEmpty {
                        let moved = m.results.filter { $0.state == "MOVED" }.count
                        let deleted = m.results.filter { $0.state == "DELETED" }.count
                        let failed = m.results.filter { $0.state == "FAILED" || $0.state == "SKIPPED" }.count
                        VStack(alignment: .leading, spacing: 3) {
                            Text("What happened").font(.headline)
                            if moved > 0 { Text("\(moved) item(s) moved to Recovery. You can restore them there.") }
                            if deleted > 0 { Text("\(deleted) item(s) permanently deleted.") }
                            if failed > 0 { Text("\(failed) item(s) could not be processed or were skipped. See the details below.") }
                            if moved == 0 && deleted == 0 && failed == 0 { Text(m.message) }
                        }.font(.callout)
                        ActionResultsView(results: m.results)
                    } else if !m.message.isEmpty {
                        Text(m.message).font(.callout)
                    }
                    if let output = m.out {
                        content(output)
                    } else if !m.busy {
                        Text("Choose a tool in the sidebar to see findings here.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let output = m.out, !output.candidates.isEmpty {
                Divider()
                HStack(spacing: 12) {
                    let selected = m.selected()
                    let bytes = totalBytes(selected)
                    Text("\(selected.count) selected · \(fmtBytes(bytes))")
                        .font(.subheadline.bold())
                    Spacer()
                    Button("Move to Recovery…") { confirmQ = true }
                        .disabled(selected.isEmpty || m.busy)
                        .buttonStyle(.borderedProminent)
                    if m.effective() == .expert {
                        Button("Delete permanently…", role: .destructive) { confirmD = true }
                            .disabled(selected.isEmpty || m.busy)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .confirmationDialog("Move \(m.selected().count) item(s) to Recovery?", isPresented: $confirmQ, titleVisibility: .visible) {
            Button("Move to Recovery") { m.quarantineSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Items are moved to recoverable local storage and do not free space until Recovery is emptied.")
        }
        .confirmationDialog("Permanently delete \(m.selected().count) item(s)?", isPresented: $confirmD, titleVisibility: .visible) {
            Button("Delete permanently", role: .destructive) { m.deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deletion cannot be undone. Use Move to Recovery if you may need these files again.")
        }
    }

    @ViewBuilder
    func content(_ o: ScanOutput) -> some View {
        let suggested = o.candidates.filter { $0.preselect }
        let review = o.candidates.filter { !$0.preselect }
        let incomplete = o.roots.filter {
            $0.status == .partial || $0.status == .review || $0.status == .deferred
        }
        let protected = o.roots.filter { $0.status == .protected || $0.status == .skipped }
        let notices = o.lines.compactMap { plainNotice($0) }
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("Results").font(.title3.bold())
                Text(o.title).font(.subheadline).foregroundStyle(.secondary)
            }
            if !o.candidates.isEmpty {
                HStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Suggested for review").font(.caption).foregroundStyle(.secondary)
                        Text("\(suggested.count) items · \(fmtBytes(totalBytes(suggested)))")
                            .font(.headline).monospacedDigit()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Check individually").font(.caption).foregroundStyle(.secondary)
                        Text("\(review.count) items · \(fmtBytes(totalBytes(review)))")
                            .font(.headline).monospacedDigit()
                    }
                }
                .padding(.vertical, 4)
                Text("Nothing has been removed. Suggested items are selected for your review; moving them to Recovery does not free disk space until Recovery is emptied.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if !o.sections.isEmpty {
                Text("This is an information report. No files are selected for cleanup.")
                    .font(.callout).foregroundStyle(.secondary)
            } else if o.lines.isEmpty {
                Text("This check did not return any items.").font(.callout)
            }

            if !incomplete.isEmpty {
                Label("\(incomplete.count) location(s) were not fully checked. The results may be incomplete.", systemImage: "exclamationmark.triangle")
                    .font(.callout).foregroundStyle(.orange)
            }
            if !protected.isEmpty {
                Label("\(protected.count) location(s) were skipped or protected. They were not changed.", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(Array(notices.enumerated()), id: \.offset) { _, notice in
                Label(notice, systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if !o.candidates.isEmpty { candidateList(o) }

            if !o.sections.isEmpty {
                if o.candidates.isEmpty {
                    ForEach(o.sections) { section in
                        ScanSectionView(section: section, initiallyExpanded: true)
                    }
                } else {
                    DisclosureGroup("Additional findings (\(o.sections.count))", isExpanded: $showOtherFindings) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(o.sections) { section in
                                ScanSectionView(section: section, initiallyExpanded: false)
                            }
                        }.padding(.vertical, 5)
                    }
                }
            }
            if o.candidates.isEmpty && o.sections.isEmpty {
                ForEach(Array(o.lines.prefix(8).enumerated()), id: \.offset) { _, line in
                    Text(line).font(.callout).textSelection(.enabled)
                }
            }

            DisclosureGroup("Technical details", isExpanded: $showTechnical) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Original scan notes").font(.caption.bold())
                    ForEach(Array(o.lines.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption).textSelection(.enabled)
                    }
                    if !o.roots.isEmpty {
                        Divider()
                        Text("Locations checked (\(o.roots.count))").font(.caption.bold())
                        ForEach(o.roots) { r in
                            HStack(alignment: .top, spacing: 6) {
                                Pill(text: r.status.rawValue, color: statusColor(r.status))
                                Text("\(Modes.abbrev(r.path)) — \(r.storage.rawValue) · \(fmtOrDash(r.bytes))\(r.note.isEmpty ? "" : " · " + r.note)")
                                    .font(.caption).textSelection(.enabled)
                            }
                        }
                    }
                }.padding(.vertical, 6)
            }
            .font(.caption)
        }
    }

    /// Simple mode groups findings and only bulk-selects groups JANITOR has marked as recoverable.
    @ViewBuilder
    func groupedList(_ o: ScanOutput) -> some View {
        let groups = Dictionary(grouping: o.candidates, by: { $0.category })
            .sorted { $0.key < $1.key }
        ForEach(groups, id: \.key) { group in
            let ids = Set(group.value.map { $0.id })
            let selectable = group.value.allSatisfy { $0.preselect || $0.keeper != nil }
            let count = group.value.count
            let amount = totalBytes(group.value)
            HStack(alignment: .center, spacing: 10) {
                Toggle("", isOn: Binding(
                    get: { ids.isSubset(of: m.selection) },
                    set: { on in
                        if on { m.selection.formUnion(ids) }
                        else { m.selection.subtract(ids) }
                    }
                ))
                .labelsHidden()
                .disabled(!selectable)
                .accessibilityLabel("Select \(friendlyCategory(group.key))")
                VStack(alignment: .leading, spacing: 3) {
                    Text(friendlyCategory(group.key)).font(.subheadline.bold())
                    Text("\(count) item(s) · \(amount > 0 ? fmtBytes(amount) : "size unknown")")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(selectable ? "Review and move to Recovery if you agree." : "Needs a closer look. Select Advanced in the top-right toolbar to review files.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 2)
            }
            .padding(.vertical, 4)
            Divider().opacity(0.35)
        }
    }

    @ViewBuilder
    func candidateList(_ o: ScanOutput) -> some View {
        let lv = m.effective()
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Items to review (\(o.candidates.count))").font(.headline)
                Spacer()
                if lv >= .advanced {
                    Button("Select all") { m.selection = Set(o.candidates.map { $0.id }) }
                }
                Button("Select suggested") {
                    m.selection = Set(o.candidates.filter { $0.preselect }.map { $0.id })
                }
                Button("Clear") { m.selection = [] }
            }.buttonStyle(.borderless).font(.caption)

            if lv == .simple {
                groupedList(o)
            } else {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(o.candidates) { c in
                        HStack(alignment: .top, spacing: 8) {
                            Toggle("", isOn: Binding(
                                get: { m.selection.contains(c.id) },
                                set: { on in
                                    if on { m.selection.insert(c.id) }
                                    else { m.selection.remove(c.id) }
                                }
                            ))
                            .labelsHidden()
                            .accessibilityLabel("Select \(c.title)")
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(c.title).font(.callout.bold()).lineLimit(1)
                                    Spacer()
                                    Text(c.bytes > 0 ? fmtBytes(c.bytes) : "—")
                                        .font(.caption).monospacedDigit()
                                }
                                Text("\(friendlyCategory(c.category)): \(friendlyReason(c))")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(Modes.abbrev(c.url.path))
                                    .font(.caption2.monospaced()).foregroundStyle(.tertiary)
                                    .lineLimit(1).textSelection(.enabled)
                                Button("Details") {
                                    m.inspectedCandidateID = c.id
                                    m.showInspector = true
                                }
                                .buttonStyle(.link)
                                .font(.caption2)
                                .accessibilityHint("Show this item's details in Inspector")
                            }
                        }
                        Divider().opacity(0.35)
                    }
                }
            }

        }

    }
}

struct ScanSectionView: View {
    let section: InfoSection
    @State private var expanded: Bool

    init(section: InfoSection, initiallyExpanded: Bool) {
        self.section = section
        _expanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        DisclosureGroup("\(section.title) (\(section.rows.count))", isExpanded: $expanded) {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                    Text(row).font(.callout).textSelection(.enabled)
                    Divider().opacity(0.3)
                }
            }.padding(.vertical, 6)
        }
    }
}

struct ActionResultsView: View {
    let results: [ActionResult]
    @State private var expanded = false
    var body: some View {
        DisclosureGroup("Details for each item (\(results.count))", isExpanded: $expanded) {
            LazyVStack(alignment: .leading, spacing: 5) {
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
