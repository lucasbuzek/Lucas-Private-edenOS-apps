import Foundation

/// Read-only work-capability discovery for the EXISTING BIFROST resolver.
/// Professional applications, Apple, FORGE, CONDUCTOR and remote connectors
/// retain execution and authorization. Presence does not grant access.
struct BifrostWorkCapability: Identifiable {
    let id: String
    let name: String
    let provider: String
    let detected: Bool
    let boundary: String
}

enum BifrostWorkCapabilityProbe {
    static func discover(
        executable: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) -> [BifrostWorkCapability] {
        func has(_ paths: [String]) -> Bool { paths.contains(where: executable) }
        return [
            .init(id: "work.apps.open", name: "Open installed Mac applications",
                  provider: "Existing AppRegistry / NSWorkspace", detected: true,
                  boundary: "Explicit action. Opening an app is not permission to automate it."),
            .init(id: "work.apps.operate", name: "Operate app interfaces",
                  provider: "Apple Events / Accessibility", detected: has(["/usr/bin/osascript"]),
                  boundary: "Prefer native actions. Separate per-app Automation/Accessibility permission."),
            .init(id: "work.files", name: "Create and edit files",
                  provider: "Finder / Foundation / appropriate editor", detected: true,
                  boundary: "Exact approved files and destination. Preserve originals and rollback."),
            .init(id: "work.images", name: "Image and photo operations",
                  provider: "sips / installed specialist editor",
                  detected: has(["/usr/bin/sips"]),
                  boundary: "Image conversion is available; complex editing is delegated."),
            .init(id: "work.video", name: "Audio and video processing",
                  provider: "FFmpeg", detected: has(["/opt/homebrew/bin/ffmpeg",
                                                    "/usr/local/bin/ffmpeg"]),
                  boundary: "Review source, codecs, output, resource usage and overwrites."),
            .init(id: "work.render", name: "3D and rendering",
                  provider: "DÜRER / Blender", detected: has(["/opt/homebrew/bin/blender",
                      "/Applications/Blender.app/Contents/MacOS/Blender"]),
                  boundary: "Domain specialist owns the source/assets and render job."),
            .init(id: "work.build", name: "Software compilation",
                  provider: "FORGE / Xcode", detected: has(["/usr/bin/xcodebuild",
                     "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"]),
                  boundary: "Verified source, project builder audit, tests and LKG."),
            .init(id: "work.apple.automation", name: "Shortcuts and Automator",
                  provider: "Existing BIFROST native workflow catalog",
                  detected: has(["/usr/bin/shortcuts", "/usr/bin/automator"]),
                  boundary: "Inspect exact saved workflow and confirm execution."),
            .init(id: "work.remote", name: "Remote execution and coordination",
                  provider: "RDC6 / CONDUCTOR / owner adapters", detected: false,
                  boundary: "Available in this authorized ChatGPT session; NOT bundled or authenticated in this native app.")
        ]
    }
}
