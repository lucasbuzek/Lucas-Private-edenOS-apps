import Foundation
import AppKit

struct BifrostCapability: Identifiable, Hashable {
    enum Kind: String { case native = "Native", automation = "Automation", eden = "EDEN", bridge = "Bridge" }
    let id: String; let name: String; let provider: String; let kind: Kind; let available: Bool; let detail: String
}

@MainActor final class CapabilityRegistry: ObservableObject {
    @Published private(set) var items: [BifrostCapability] = []
    @Published private(set) var shortcuts: [String] = []
    @Published private(set) var shortcutsStatus = "Not checked"
    func refresh(remote: RemoteDesktopProvider) {
        var found: [BifrostCapability] = []
        func add(_ id:String,_ name:String,_ provider:String,_ kind:BifrostCapability.Kind,_ ok:Bool,_ detail:String){ found.append(.init(id:id,name:name,provider:provider,kind:kind,available:ok,detail:detail)) }
        add("native.keepawake","Keep Awake","macOS",.native,true,"caffeinate")
        add("native.automation","AppleScript / Automator","macOS",.automation,FileManager.default.fileExists(atPath:"/usr/bin/osascript"),"Native automation")
        add("native.shortcuts","Shortcuts","macOS",.automation,FileManager.default.fileExists(atPath:"/usr/bin/shortcuts"),"App Shortcuts and user shortcuts")
        add("bridge.remote","Remote Desktop Commander","BIFROST",.bridge,remote.state != .unavailable,remote.detail)
        let apps = [("janitor","JANITOR"),("lingua","LINGUA"),("lector","LECTOR")]
        for (id,name) in apps { let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier:"eden.private.\(id)"); add("eden.\(id)",name,name,.eden,url != nil,url == nil ? "Not installed as registered app" : "Installed") }
        items = found
        refreshShortcuts()
    }
    private func refreshShortcuts() {
        guard FileManager.default.isExecutableFile(atPath:"/usr/bin/shortcuts") else {
            shortcuts=[]
            shortcutsStatus="Shortcuts command unavailable"
            return
        }

        let p=Process(); let output=Pipe(); let errors=Pipe()
        p.executableURL=URL(fileURLWithPath:"/usr/bin/shortcuts")
        p.arguments=["list"]
        p.standardOutput=output
        p.standardError=errors
        do {
            try p.run()
            p.waitUntilExit()
            let out=String(data:output.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8) ?? ""
            let errorText=String(data:errors.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8)?
                .trimmingCharacters(in:.whitespacesAndNewlines) ?? ""
            if p.terminationStatus == 0 {
                shortcuts=out.split(separator:"\n").map(String.init)
                shortcutsStatus="Query succeeded · \(shortcuts.count) shortcuts"
            } else {
                shortcuts=[]
                shortcutsStatus=errorText.isEmpty
                    ? "Query failed · exit \(p.terminationStatus)"
                    : "Query failed · \(errorText)"
            }
        } catch {
            shortcuts=[]
            shortcutsStatus="Query failed · \(error.localizedDescription)"
        }
    }
}
