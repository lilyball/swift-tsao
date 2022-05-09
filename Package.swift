// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TSAO",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "swift-tsao",
            targets: ["swift_tsao"]
        ),
    ],
    targets: [
        .target(
            name: "swift_tsao",
            path: "./Sources"
        ),
    ]
)
