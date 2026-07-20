// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TasteMapCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TasteMapCore", targets: ["TasteMapCore"])
    ],
    targets: [
        .target(name: "TasteMapCore"),
        .testTarget(name: "TasteMapCoreTests", dependencies: ["TasteMapCore"])
    ]
)
