import Foundation
import AppKit

struct EdenAppRecord: Identifiable { let id:String; let name:String; let installed:Bool; let path:String? }
@MainActor final class AppRegistry: ObservableObject {
 @Published private(set) var apps:[EdenAppRecord]=[]
 func refresh(){ apps=["JANITOR","LINGUA","LECTOR","HEIMDALL"].map { name in
   let id=name.lowercased(); let url=NSWorkspace.shared.urlForApplication(withBundleIdentifier:"eden.private.\(id)")
   return .init(id:id,name:name,installed:url != nil,path:url?.path)
 } }
 func open(_ app:EdenAppRecord){ guard let path=app.path else{return}; NSWorkspace.shared.openApplication(at:URL(fileURLWithPath:path),configuration:.init()) }
}
