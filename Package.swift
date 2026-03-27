// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacPause",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MacPauseCore",
            targets: ["MacPauseCore"]
        ),
        .executable(
            name: "MacPauseApp",
            targets: ["MacPauseApp"]
        )
    ],
    targets: [
        .target(
            name: "MacPauseCore"
        ),
        .executableTarget(
            name: "MacPauseApp",
            dependencies: ["MacPauseCore"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Support/MacPauseApp-Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "MacPauseCoreTests",
            dependencies: ["MacPauseCore"]
        )
    ]
)
