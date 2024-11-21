// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Core",
            targets: ["Core"]),
        .library(
            name: "SharedModels",
            targets: ["SharedModels"]),
        .library(
            name: "ChapterFeature",
            targets: ["ChapterFeature"]),
        .library(
            name: "ChaptersFeature",
            targets: ["ChaptersFeature"]),
        .library(
            name: "RecognitionFeature",
            targets: ["RecognitionFeature"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.16.0"), // Composable Architecture
        .package(url: "https://github.com/pointfreeco/swift-overture", from: "0.5.0"),
        .package( url: "https://github.com/apple/swift-collections.git", .upToNextMinor(from: "1.1.0") // or `.upToNextMajor
           )

    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "Core", dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        ]),
        .target(
            name: "ChapterFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "Overture", package: "swift-overture"),
                "SharedModels",
                "RecognitionFeature"
            ], resources: [.process("Animations")]
        ),
        .target(
            name: "ChaptersFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DequeModule", package: "swift-collections"),
                "SharedModels",
                "ChapterFeature"
            ]),
        .target(
            name: "RecognitionFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "Core",
                "SharedModels"
            ]),
        .target(name: "SharedModels"),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"])
    ])
