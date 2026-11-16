// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MathQuest",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MathQuest", targets: ["MathQuest"])],
    targets: [
        .executableTarget(name: "MathQuest", resources: [.process("Assets.xcassets")]),
        .testTarget(name: "MathQuestTests", dependencies: ["MathQuest"])
    ]
)
