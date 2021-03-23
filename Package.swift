// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcode-parallel-test",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "xcode-parallel-test", targets: ["xcode-parallel-test"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.1.0")),
        .package(name: "XcodeProj", url: "https://github.com/tuist/xcodeproj.git", from: "7.11.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "3.0.1")
    ],
    targets: [
        .target(
            name: "xcode-parallel-test",
            dependencies: [
                "XCParallelTest",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Yams"
            ]),
        .target(
            name: "XCParallelTest",
            dependencies: [
                "XcodeProj"
            ]),
        .testTarget(
            name: "XCParallelTestTests",
            dependencies: ["XCParallelTest"]),
    ]
)
