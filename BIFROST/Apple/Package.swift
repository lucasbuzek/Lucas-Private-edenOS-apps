// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "BifrostChatGPTApple",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "BifrostChatGPTApple", targets: ["BifrostChatGPTApple"])],
    targets: [
        .target(name: "BifrostChatGPTApple"),
        .testTarget(name: "BifrostChatGPTAppleTests", dependencies: ["BifrostChatGPTApple"])
    ]
)
