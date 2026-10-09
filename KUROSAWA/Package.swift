// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "KUROSAWA", platforms: [.macOS(.v15), .iOS(.v18)], products: [.library(name: "KurosawaCore", targets: ["KurosawaCore"])], targets: [.target(name: "KurosawaCore"), .testTarget(name: "KurosawaCoreTests", dependencies: ["KurosawaCore"])])
