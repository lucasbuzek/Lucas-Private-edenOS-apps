import SwiftUI

struct OverviewView: View {
 @EnvironmentObject var system:BifrostSystem
 var body: some View { VStack(alignment:.leading,spacing:24){
  BifrostHeader(title:"Connect · Keep · Resolve",subtitle:"The bridge between your EDEN devices and capabilities.")
  HStack(spacing:14){ StatusCard("This Mac","Available","laptopcomputer"); StatusCard("Remote Access",system.remote.state.rawValue,"network"); StatusCard("Nearby","\(system.discovery.services.count) services","dot.radiowaves.left.and.right") }
  GroupBox("Bridge Controls") { HStack(spacing:14){ Toggle("Keep Mac Awake",isOn:Binding(get:{system.keepAwake},set:{system.setKeepAwake($0)})); Spacer(); Button("Start Remote"){system.remote.start()}; Button("Stop Remote"){system.remote.stop()}; Button("Refresh"){system.refresh()} }.padding(8) }
  Text(system.remote.detail).font(.callout).foregroundStyle(.secondary)
 }.frame(maxWidth:940,alignment:.leading) }
}

struct StatusCard: View { let title:String,value:String,icon:String
 init(_ t:String,_ v:String,_ i:String){title=t;value=v;icon=i}
 var body:some View { GroupBox { VStack(alignment:.leading,spacing:10){Image(systemName:icon).font(.title2);Text(title).font(.headline);Text(value).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding(8)}.frame(minWidth:200) }
}

struct DevicesView:View { @EnvironmentObject var system:BifrostSystem
 var body:some View { VStack(alignment:.leading,spacing:18){ BifrostHeader(title:"Nearby",subtitle:"Observed network services. Discovery does not imply trust or control."); if system.discovery.services.isEmpty { ContentUnavailableView("Looking for nearby services",systemImage:"dot.radiowaves.left.and.right",description:Text("BIFROST uses native Bonjour discovery.")) } else { List(system.discovery.services){s in HStack{Image(systemName:"network");VStack(alignment:.leading){Text(s.name).font(.headline);Text(s.type).foregroundStyle(.secondary)};Spacer();Text("Discovered").foregroundStyle(.secondary)}} } }.frame(maxWidth:900,alignment:.leading) }
}
