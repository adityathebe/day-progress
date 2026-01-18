// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DayProgressMenubar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DayProgressMenubar", targets: ["DayProgressMenubar"])
    ],
    targets: [
        .executableTarget(
            name: "DayProgressMenubar",
            path: "Sources/DayProgressMenubar",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
