import SwiftUI

@main
struct SWAYApp: App {
    @StateObject private var store = SwayStore()
    @StateObject private var session = SwaySessionController()
    @StateObject private var sharedSessions = SwaySharedSessionCoordinator()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(session)
                .environmentObject(sharedSessions)
                .sheet(item:$store.pendingImport) { package in SwayImportPreviewView(package:package).environmentObject(store) }
                .alert("SWAY Import",isPresented:Binding(get:{store.importMessage != nil},set:{if !$0 {store.importMessage=nil}})) { Button("OK",role:.cancel){store.importMessage=nil} } message:{Text(store.importMessage ?? "")}
                .onOpenURL { url in
                    guard url.pathExtension.lowercased() == "swaypack" else { return }
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    do { try store.prepareImport(from:url) } catch { store.importMessage=error.localizedDescription }
                }
        }
    }
}
