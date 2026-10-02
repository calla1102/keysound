// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HangulEngine",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "HangulEngine", targets: ["HangulEngine"]),
    ],
    targets: [
        .target(name: "HangulEngine"),
        .testTarget(name: "HangulEngineTests", dependencies: ["HangulEngine"]),
    ]
)
