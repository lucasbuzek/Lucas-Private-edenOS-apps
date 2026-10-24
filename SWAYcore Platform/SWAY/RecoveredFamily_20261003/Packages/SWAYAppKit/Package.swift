// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "SWAYAppKit",
    platforms: [.iOS("18.0"), .macOS("15.0")],
    products: [.library(name: "SWAYAppKit", targets: ["SWAYAppKit"])],
    dependencies: [.package(path: "../SWAYcoreKit")],
    targets: [
        .target(name: "SWAYAppKit", dependencies: [.product(name: "SWAYcoreKit", package: "SWAYcoreKit")]),
        .testTarget(name: "SWAYAppKitTests", dependencies: ["SWAYAppKit"])
    ]
)
