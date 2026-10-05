// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BIFROSTNativeAccess",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "BIFROSTNativeAccess", targets: ["BIFROSTNativeAccess"])],
    targets: [.executableTarget(name: "BIFROSTNativeAccess")]
)
