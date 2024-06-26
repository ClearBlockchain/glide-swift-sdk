// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GlideSwiftSDK",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "GlideSwiftSDK",
            targets: ["GlideSwiftSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.1.0"),
    ],
    targets: [
        .target(
            name: "GlideSwiftSDK",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ]),
    ]
)
