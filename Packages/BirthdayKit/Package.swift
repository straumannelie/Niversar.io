// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BirthdayKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "BirthdayKit", targets: ["BirthdayKit"])
    ],
    targets: [
        .target(name: "BirthdayKit"),
        .testTarget(name: "BirthdayKitTests", dependencies: ["BirthdayKit"]),
    ]
)
