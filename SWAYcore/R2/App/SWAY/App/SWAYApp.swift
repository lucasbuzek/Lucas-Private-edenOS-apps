import SwiftUI

@main
struct SWAYApp: App {
    @StateObject private var store = SwayStore()
    @StateObject private var session = SwaySessionController()
    @StateObject private var sharedSessions = SwaySharedSessionCoordinator()
    @StateObject private var recoveryNotices = SwayRecoveryNotices.shared
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if SWAYAvatarGalleryView.requested { SWAYAvatarGalleryView() } else { app }
            #else
            app
            #endif
        }
    }

    private var app: some View {
            RootView()
                .environmentObject(store)
                .environmentObject(session)
                .environmentObject(sharedSessions)
                .sheet(item:$store.pendingImport) { package in SwayImportPreviewView(package:package).environmentObject(store) }
                .alert("SWAY Import",isPresented:Binding(get:{store.importMessage != nil},set:{if !$0 {store.importMessage=nil}})) { Button("OK",role:.cancel){store.importMessage=nil} } message:{Text(store.importMessage ?? "")}
                .alert("SWAY Recovered Your Data",isPresented:Binding(get:{recoveryNotices.message != nil},set:{if !$0 {recoveryNotices.message=nil}})) { Button("OK",role:.cancel){recoveryNotices.message=nil} } message:{Text(recoveryNotices.message ?? "")}
                .onOpenURL { url in
                    guard url.pathExtension.lowercased() == "swaypack" else { return }
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    do { try store.prepareImport(from:url) } catch { store.importMessage=error.localizedDescription }
                }
    }
}
