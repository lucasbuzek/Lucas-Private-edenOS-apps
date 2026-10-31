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
            GroupBox("Keep Awake") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(system.headless.caffeinateActive ? "Active" : "Inactive",
                              systemImage: system.headless.caffeinateActive ? "sun.max.fill" : "sun.max")
                        if let until = system.headless.awakeUntil {
                            Text("Until \(until.formatted(date: .omitted, time: .shortened))")
                                .foregroundStyle(.secondary)
                            Text(until, style: .timer).foregroundStyle(.secondary)
                        } else if system.headless.caffeinateActive {
                            Text("Until stopped").foregroundStyle(.secondary)
                        }
                        Spacer()
                        if system.headless.caffeinateActive {
                            Button("Stop") { system.headless.stopCaffeinate() }
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach([30, 60, 120, 0], id: \.self) { minutes in
                            Button(durationName(minutes)) {
                                system.headless.activateCaffeinate(minutes: minutes)
                            }
                            .disabled(system.headless.systemCaffeinateObserved == true &&
                                      !system.headless.caffeinateActive)
                        }
                        Spacer()
                        Button("Refresh") { system.refresh() }
                    }
                    if !system.headless.isRunning {
                        Text("Choosing a duration starts BIFROST Headless on this Mac.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(8)
            }
            Text("External connections are managed separately by optional plugins.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: 940, alignment: .leading)
    }
    private func durationName(_ minutes: Int) -> String {
        if minutes == 0 { return "Until stopped" }
        if minutes == 60 { return "1 hour" }
        if minutes.isMultiple(of: 60) { return "\(minutes / 60) hours" }
        return "\(minutes) minutes"
    }
}

struct StatusCard: View { let title:String,value:String,icon:String
 init(_ t:String,_ v:String,_ i:String){title=t;value=v;icon=i}
 var body:some View { GroupBox { VStack(alignment:.leading,spacing:10){Image(systemName:icon).font(.title2);Text(title).font(.headline);Text(value).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding(8)}.frame(minWidth:200) }
}
