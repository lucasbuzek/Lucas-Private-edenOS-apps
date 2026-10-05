import SwiftUI

struct JanitorView: View {
    @EnvironmentObject var system: BifrostSystem
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            BifrostHeader(title: "JANITOR", subtitle: "Maintenance, inspection, cleanup and recovery — executed by the standalone JANITOR app.")
            HStack(spacing: 14) {
                StatusCard("JANITOR", system.janitor.available ? "Ready" : "Unavailable", "sparkles")
                StatusCard("Version", system.janitor.version, "number")
                StatusCard("Reports", system.janitor.lastReport == nil ? "None" : "Available", "doc.text")
            }
            GroupBox("Run JANITOR") {
                VStack(alignment: .leading, spacing: 14) {
                    Text(system.janitor.detail).foregroundStyle(.secondary)
                    HStack {
                        Button("Quick Scan") { system.janitor.runQuickScan() }.buttonStyle(.borderedProminent)
                        Button("Developer Quick") { system.janitor.runDeveloperQuick() }
                        Button("Full Scan") { system.janitor.runFullScan() }
                    }
                    HStack {
                        Button("Open JANITOR") { system.janitor.open() }
                        Button("Reports") { system.janitor.showReports() }
                        Button("Refresh") { system.janitor.refresh() }
                    }
                }.padding(10)
            }
            Text("BIFROST does not duplicate JANITOR. These controls invoke the installed standalone capability and preserve JANITOR's ownership.")
                .font(.callout).foregroundStyle(.secondary)
        }.frame(maxWidth: 940, alignment: .leading)
    }
}
