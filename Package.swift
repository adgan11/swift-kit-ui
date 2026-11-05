// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftKitUI",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SwiftKitUI", targets: ["SwiftKitUI"]),
    ],
    targets: [
        .target(name: "SwiftKitUI"),
    ]
)
