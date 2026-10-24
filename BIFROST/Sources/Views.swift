import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var system: BifrostSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(title: "Connect · Keep · Resolve",
                          subtitle: "Local devices, apps, capabilities and power controls.")
            HStack(spacing: 14) {
                StatusCard("This Mac", "Available", "laptopcomputer")
                StatusCard("Headless",
                           system.headless.isRunning ? "Running" : "Stopped",
                           "server.rack")
                StatusCard("Nearby",
                           "\(system.discovery.services.count) observed",
                           "dot.radiowaves.left.and.right")
            }
            GroupBox("Local power management") {
                HStack(spacing: 14) {
                    Toggle("Keep Mac Awake", isOn: Binding(
                        get: { system.keepAwake },
                        set: { system.setKeepAwake($0) }
                    )).disabled(!system.headless.isRunning)
                    Spacer()
                    Button("Refresh") { system.refresh() }
                }.padding(8)
            }
            Text("External connections are managed separately by optional plugins.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: 940, alignment: .leading)
    }
}

struct StatusCard: View { let title:String,value:String,icon:String
 init(_ t:String,_ v:String,_ i:String){title=t;value=v;icon=i}
 var body:some View { GroupBox { VStack(alignment:.leading,spacing:10){Image(systemName:icon).font(.title2);Text(title).font(.headline);Text(value).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding(8)}.frame(minWidth:200) }
}
