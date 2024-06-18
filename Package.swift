// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "glide-swift-sdk",
        platforms: [.iOS(.v17), .macOS(.v14)],
        products: [
            // Products define the executables and libraries a package produces, making them visible to other packages.
            .library(
                name: "GlideSwiftSDK",
                targets: ["GlideSwiftSDK"]),
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "glide-swift-sdk"),
    ]
)
