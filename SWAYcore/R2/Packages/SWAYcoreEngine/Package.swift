// swift-tools-version:5.9
import PackageDescription
// SWAYcoreEngine: Foundation-only, UI-free, camera-free reusable SWAYcore logic.
// Dance & Fitness (and later family apps) consume it; nothing here knows about SwiftUI, Vision, RealityKit or HealthKit.
let package = Package(
    name: "SWAYcoreEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SWAYcoreEngine", targets: ["SWAYcoreEngine"])],
    targets: [
        .target(name: "SWAYcoreEngine"),
        .testTarget(name: "SWAYcoreEngineTests", dependencies: ["SWAYcoreEngine"])
    ]
)
