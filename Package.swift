// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WallhavenDownloader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WallhavenDownloader", targets: ["WallhavenDownloader"])
    ],
    targets: [
        .executableTarget(
            name: "WallhavenDownloader",
            path: "Sources",
            resources: [
                .copy("Resources/AppIcon.icns")
            ]
        )
    ]
)
