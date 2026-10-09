import SwiftUI
import Foundation

private struct Tile: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let path: String
    let bytes: Int64
    let status: ScanStatus
}

struct TreemapWindow: View {
    let root: URL
    @Environment(\.dismiss) private var dismiss
    @State private var current: URL?
    @State private var tiles: [Tile] = []
    @State private var selected: Tile?
    @State private var busy = true
    @State private var note = "Measuring local folders…"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("Storage treemap").font(.title2.bold()); Spacer(); Button("Close") { dismiss() } }
            HStack { Text((current ?? root).path).font(.caption).lineLimit(1); Spacer(); Button("Up") { current = (current ?? root).deletingLastPathComponent() }.disabled((current ?? root).path == root.path); Button("Root") { current = root } }
            if busy { ProgressView(note) }
            GeometryReader { geometry in
                let bounds = CGRect(origin: .zero, size: geometry.size)
                let frames = TreemapLayout.frames(weights: tiles.map(\.bytes), in: bounds)
                ZStack(alignment: .topLeading) {
                    if tiles.isEmpty && !busy {
                        Text("No measurable local folders in this location.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(tiles.indices, id: \.self) { index in
                        let tile = tiles[index]
                        let frame = frames[index]
                        Button {
                            selected = tile
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(tile.name).font(.caption.bold()).lineLimit(2)
                                if frame.height >= 45 {
                                    Text(fmtBytes(tile.bytes)).font(.caption2)
                                }
                                if frame.height >= 65 {
                                    Text(tile.status.rawValue).font(.system(size: 9))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(6)
                            .frame(width: max(frame.width - 2, 0), height: max(frame.height - 2, 0), alignment: .topLeading)
                            .background(selected?.id == tile.id ? Color.accentColor.opacity(0.65) : Color.accentColor.opacity(0.22), in: RoundedRectangle(cornerRadius: 5))
                            .clipped()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(tile.name), \(fmtBytes(tile.bytes)), \(tile.status.rawValue)")
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }.frame(height: 270)
            if let selected {
                Text("Selected: \(selected.name) — \(fmtBytes(selected.bytes)) [\(selected.status.rawValue)]").font(.callout)
                Button("Open selected folder") { current = URL(fileURLWithPath: selected.path) }
                Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: selected.path)]) }
            }
            Text(note).font(.caption).foregroundStyle(.secondary)
        }
        .padding(20).frame(minWidth: 700, minHeight: 430)
        .task(id: current?.path ?? root.path) {
            busy = true; selected = nil; tiles = []
            let target = current ?? root
            let result = await Task.detached(priority: .utility) { () -> ([Tile], String) in
                let rootPath = root.resolvingSymlinksInPath().standardized.path
                let targetPath = target.resolvingSymlinksInPath().standardized.path
                guard targetPath == rootPath || targetPath.hasPrefix(rootPath + "/") else { return ([], "Outside selected root — refused") }
                let cls = Storage.classify(target)
                guard cls.scannable, !Storage.isBoundary(target), !Storage.isManagedTree(target) else { return ([], "Protected or provider-managed root — refused") }
                let deadline = Date().addingTimeInterval(Prefs.timeout * 5)
                var values: [Tile] = []
                for u in (Scan.listChildren(target) ?? []).prefix(35) {
                    if Date() > deadline || Task.isCancelled { break }
                    guard Storage.classify(u).scannable, !Storage.isBoundary(u), !Storage.isManagedTree(u) else { continue }
                    let measure = Scan.size(of: u, deadline: Date().addingTimeInterval(2))
                    if measure.bytes > 0 { values.append(Tile(name: u.lastPathComponent, path: u.path, bytes: measure.bytes, status: measure.status)) }
                }
                values.sort { $0.bytes > $1.bytes }
                return (Array(values.prefix(12)), "Read-only local folder sample. Partial measurements are estimates; protected and cloud folders excluded.")
            }.value
            tiles = result.0; note = result.1; busy = false
        }
    }
}
