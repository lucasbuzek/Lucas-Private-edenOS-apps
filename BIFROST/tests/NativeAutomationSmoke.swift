import Foundation

@main
enum NativeAutomationSmoke {
    static func main() throws {
        func check(_ ok: Bool, _ name: String) {
            guard ok else { fputs("FAIL \(name)\n", stderr); exit(1) }
        }
        let known = ["Existing Workflow", "Text to Audio"]
        check(BifrostNativeWorkflowCatalog.canRunShortcut("Existing Workflow", known: known), "known exact shortcut")
        check(!BifrostNativeWorkflowCatalog.canRunShortcut("Not Installed", known: known), "missing shortcut denied")
        check(!BifrostNativeWorkflowCatalog.canRunShortcut("Existing Workflow\nother", known: known), "newline rejected")
        check(!BifrostNativeWorkflowCatalog.canRunShortcut(String(repeating: "a", count: 161),
                                                           known: [String(repeating: "a", count: 161)]), "long name rejected")
        check(BifrostNativeWorkflowCatalog.runShortcut("Unknown", known: []).contains("Refused"), "never executes unlisted name")
        let allow = BifrostLocalDashboardWebView.LocalOnlyDelegate.permitted
        check(allow(URL(string:"http://127.0.0.1:8798/")!), "local dashboard allowed")
        check(allow(URL(string:"http://127.0.0.1:8798/api/health")!), "local API same origin allowed")
        for url in ["http://127.0.0.1:8799/","https://127.0.0.1:8798/",
                    "http://localhost:8798/","http://example.com/",
                    "http://127.0.0.1:8798@evil.example/",
                    "file:///etc/passwd","javascript:alert(1)"] {
            check(!allow(URL(string:url)!), "external and unsafe origin rejected")
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("bifrost-workflow-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let services = root.appendingPathComponent("Library/Services")
        try FileManager.default.createDirectory(at: services.appendingPathComponent("Example.workflow"),
                                                withIntermediateDirectories: true)
        try "ignored".write(to: services.appendingPathComponent("ignored.txt"), atomically:true, encoding:.utf8)
        let found = BifrostNativeWorkflowCatalog.automatorWorkflows(home:root)
        check(found.count == 1 && found[0].name == "Example", "read-only workflow discovery")
        check(BifrostNativeWorkflowCatalog.canRunAutomator(found[0], discovered: found, home: root),
              "saved Automator path accepted only with exact catalog")
        let forged = BifrostNativeWorkflow(name: "Example", path: "/tmp/forged.workflow")
        check(!BifrostNativeWorkflowCatalog.canRunAutomator(forged, discovered: found, home: root),
              "forged Automator path refused")
        check(BifrostNativeWorkflowCatalog.runAutomator(forged, discovered: []).contains("Refused"),
              "unlisted Automator workflow never executes")
        print("PASS: native workflow and local browser security smoke")
    }
}
