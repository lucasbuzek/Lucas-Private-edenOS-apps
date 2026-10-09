// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JANITOR",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "JANITOR", path: "Sources/JANITOR")
    ]
)
