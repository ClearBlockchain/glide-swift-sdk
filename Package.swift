//
//  Package.swift
//  glide-swift-sdk
//
//  Created by amir avisar on 18/06/2024.
//

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
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", .upToNextMajor(from: "3.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GlideSwiftSDK",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ]
        ),
    ]
)
