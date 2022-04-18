// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tuist-dependency-generator",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "tuist-dependency-generator", targets: ["TuistPluginDependencyGenerator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/ProjectAutomation", from: "3.2.0")
    ],
    targets: [
        .executableTarget(
            name: "TuistPluginDependencyGenerator",
            dependencies: [
                .product(name: "ProjectAutomation", package: "ProjectAutomation")
            ]
        )
    ]
)
