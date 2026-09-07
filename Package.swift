// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GenericSyncEngine",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "generic-sync-engine", targets: ["GenericSyncEngine"])
    ],
    targets: [
        .executableTarget(name: "GenericSyncEngine")
    ]
)

