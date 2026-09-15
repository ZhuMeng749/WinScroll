// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WinScroll",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "WinScroll", targets: ["WinScroll"])],
    targets: [
        .target(name: "ScrollCore"),
        .executableTarget(name: "WinScroll", dependencies: ["ScrollCore"]),
        .testTarget(name: "ScrollCoreTests", dependencies: ["ScrollCore"])
    ]
)
