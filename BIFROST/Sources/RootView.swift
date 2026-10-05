import SwiftUI

struct RootView: View {
 @EnvironmentObject var system:BifrostSystem; @State private var selection="Overview"
 let primary=["Overview","ChatGPT","JANITOR","Devices","Connections","Capabilities","Representations"]
 let management=["App Management","Development & Releases"]
 var body:some View { NavigationSplitView { List(selection:$selection){ Section("BIFROST"){ForEach(primary,id:\.self){Label($0,systemImage:icon($0)).tag($0)}}; if system.complexity != .simple {Section("Management"){ForEach(management,id:\.self){Label($0,systemImage:icon($0)).tag($0)}}};Section{Label("Settings",systemImage:"gearshape").tag("Settings")} }.navigationTitle("BIFROST") } detail:{ detail.padding(30).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading).background(.ultraThinMaterial) }.toolbar {ToolbarItem{Picker("UI",selection:$system.complexity){ForEach(Complexity.allCases){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented).frame(width:260)}} }
 @ViewBuilder var detail:some View { switch selection { case "Overview":OverviewView();case "ChatGPT":ChatGPTPane();case "JANITOR":JanitorView();case "Devices":DevicesView();case "Connections":ConnectionsView();case "Capabilities":CapabilitiesView(capabilities:system.capabilities);case "Representations":RepresentationsView();case "Settings":SettingsView();default:ManagementView(title:selection) } }
 func icon(_ n:String)->String { ["ChatGPT":"bubble.left.and.bubble.right","Overview":"square.grid.2x2","JANITOR":"sparkles","Devices":"macbook.and.iphone","Connections":"point.3.connected.trianglepath.dotted","Capabilities":"wand.and.stars","Representations":"rectangle.3.group","App Management":"shippingbox","Development & Releases":"hammer"][n] ?? "circle" }
}
