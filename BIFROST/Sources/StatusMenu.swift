import SwiftUI

struct StatusMenu: View {
 @EnvironmentObject var system:BifrostSystem; @Environment(\.openWindow) private var openWindow
 var body:some View { VStack(alignment:.leading,spacing:10){
  BifrostSpectrum();Text("BIFROST").font(.headline)
  Label(system.remote.state.rawValue,systemImage:"point.3.connected.trianglepath.dotted")
  Text("\(system.discovery.services.count) nearby services").font(.caption).foregroundStyle(.secondary)
  Toggle("Keep Mac Awake",isOn:Binding(get:{system.keepAwake},set:{system.setKeepAwake($0)}))
  Divider();HStack{Button("Start Remote"){system.remote.start()};Button("Stop"){system.remote.stop()}}
  Button("Open BIFROST"){openWindow(id:"main")} ; Button("Refresh"){system.refresh()}
  Divider();Button("Quit BIFROST"){NSApplication.shared.terminate(nil)}
 }.padding(10).frame(width:270) }
}
