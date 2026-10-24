// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "SWAYcoreKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SWAYcoreKit", targets: ["SWAYcoreKit"]), .executable(name: "sway-fixtures", targets: ["sway-fixtures"])],
    targets: [
        .target(name: "SWAYcoreKit"),
        .executableTarget(name: "sway-fixtures", dependencies: ["SWAYcoreKit"]),
        .testTarget(name: "SWAYcoreKitTests", dependencies: ["SWAYcoreKit"])
    ]
)
