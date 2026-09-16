// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesktopTodoDaemon",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "DesktopTodoDaemon", targets: ["DesktopTodoDaemon"])
    ],
    targets: [
        .executableTarget(
            name: "DesktopTodoDaemon",
            path: "Sources/DesktopTodoDaemon",
            resources: [.process("Resources")]
        )
    ]
)
