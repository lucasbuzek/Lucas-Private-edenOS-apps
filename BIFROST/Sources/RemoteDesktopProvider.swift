import Foundation

@MainActor final class RemoteDesktopProvider: ObservableObject {
    enum State: String { case running="Running", stopped="Stopped", unavailable="Not installed", unknown="Checking…" }
    @Published private(set) var state:State = .unknown
    @Published private(set) var detail=""
    @Published private(set) var managedByBifrost=false
    private var managed:Process?
    private let signature="desktop-commander"

    func refresh(){
        if managed?.isRunning == true { state = .running; managedByBifrost=true; detail="Running · managed by BIFROST"; return }
        managed=nil; managedByBifrost=false
        if externalPID() != nil { state = .running; detail="Running · external session (observed only)"; return }
        let installed = ["/opt/homebrew/bin/npx","/usr/local/bin/npx"].contains{FileManager.default.isExecutableFile(atPath:$0)}
        state = installed ? .stopped : .unavailable; detail = installed ? "Provider installed and ready" : "Node/npx not installed"
    }
    func start(){ refresh(); guard state == .stopped else{return}; let p=Process(); p.executableURL=URL(fileURLWithPath:"/usr/bin/env");p.arguments=["npx","@wonderwhy-er/desktop-commander@latest","remote"]
        do{try p.run();managed=p;managedByBifrost=true;state = .running;detail="Starting · managed by BIFROST"}catch{detail="Start failed: \(error.localizedDescription)";refresh()} }
    func stop(){ guard let p=managed,p.isRunning else{detail="External session left untouched";refresh();return};p.terminate();managed=nil;managedByBifrost=false;refresh() }
    private func externalPID()->Int32? { let p=Process();let pipe=Pipe();p.executableURL=URL(fileURLWithPath:"/usr/bin/pgrep");p.arguments=["-f",signature];p.standardOutput=pipe;p.standardError=Pipe();do{try p.run();p.waitUntilExit();guard p.terminationStatus==0 else{return nil};let s=String(data:pipe.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8) ?? "";return s.split(separator:"\n").compactMap{Int32($0)}.first}catch{return nil} }
}
