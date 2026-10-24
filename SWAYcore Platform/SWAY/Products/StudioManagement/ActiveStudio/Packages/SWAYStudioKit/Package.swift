// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "SWAYStudioKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SWAYStudioKit", targets: ["SWAYStudioKit"])],
    targets: [
        .target(name: "SWAYStudioKit"),
        .testTarget(name: "SWAYStudioKitTests", dependencies: ["SWAYStudioKit"])
    ]
)
