import Foundation
import SwiftUI
import AppKit

@MainActor func runSmoke() -> Int32 {
var failures = 0
func check(_ cond: Bool, _ message: String) {
    print((cond ? "PASS" : "FAIL") + " - " + message)
    if !cond { failures += 1 }
}
let defaults = UserDefaults.standard
let keys = ["level", "janitorInspectorOpen", "janitorExpandedGroups", "workRoots", "janitorAppearance"]
var saved: [String: Any] = [:]
for key in keys { saved[key] = defaults.object(forKey: key) }
defer {
    for key in keys {
        if let previous = saved[key] { defaults.set(previous, forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }
}

let model = Model()
let previouslySelected = model.level
model.level = .simple
check(model.level == .simple, "Standard interface model")
model.level = .advanced
check(model.level == .advanced && Model.Mode.developer.minLevel == .advanced, "Advanced interface exposes Developer tools")
model.level = .expert
check(model.level == .expert, "Expert interface model")
model.setSidebarExpanded("Developer", expanded: true)
check(model.sidebarIsExpanded("Developer"), "Developer sidebar expands")
model.setSidebarExpanded("Developer", expanded: false)
check(!model.sidebarIsExpanded("Developer"), "Developer sidebar collapses")
model.showInspector = false
check(!model.showInspector, "Inspector can be hidden")
model.showInspector = true
check(model.showInspector, "Inspector can be shown")
let testRoot = FileManager.default.temporaryDirectory.appendingPathComponent("janitor-ui-host-scan")
model.mode = .organize
model.workRoot = testRoot
model.mode = .developer
check(model.workRoot?.path != testRoot.path, "Developer scan root isolated from Organize")
model.mode = .organize
check(model.workRoot?.path == testRoot.path, "Organize scan root retained independently")
// Avoid persisting fixture paths.
model.workRoot = nil
model.mode = .developer
model.level = previouslySelected

let view = RootView().environmentObject(model)
let host = NSHostingView(rootView: view)
host.frame = NSRect(x: 0, y: 0, width: 1150, height: 780)
host.layoutSubtreeIfNeeded()
check(host.bounds.width == 1150 && host.bounds.height == 780, "SwiftUI Finder shell hosts in 1150×780 AppKit view")
check(host.intrinsicContentSize.width.isFinite, "SwiftUI host measurement is finite")

model.runSystemCheck()
let limit = Date().addingTimeInterval(30)
while model.busy && Date() < limit { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
check(!model.busy, "System Check completes under bounded time")
if let report = model.systemReport {
    check(report.areas.count == 5, "System Check provides five assessment categories")
    let controls = Set(["quick", "full", "storage", "startup", "duplicates", "cloud"])
    check(Set(report.recommendations.map(\.action)).isSubset(of: controls),
          "System Check recommendations map only to implemented UI actions")
} else {
    check(false, "System Check produced report")
}
check(model.workspace == .system, "System Check remains in system workspace")
check(failures == 0, "Integrated model and SwiftUI host smoke")
print(failures == 0 ? "UI_HOST_SMOKE: PASS" : "UI_HOST_SMOKE: FAIL (\(failures))")
return failures == 0 ? 0 : 1
}
exit(MainActor.assumeIsolated { runSmoke() })
