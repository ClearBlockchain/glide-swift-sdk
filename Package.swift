// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "glide-swift-sdk",
    products: [
        .library(
            name: "GlideSwiftSDK",
            targets: ["GlideSwiftSDK"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "glide-swift-sdk",
            dependencies: []),
    ]
)
