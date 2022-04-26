// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tuist-dependency-generator",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "tuist-dependency-generator", targets: ["TuistPluginDependencyGenerator"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TuistPluginDependencyGenerator",
            dependencies: []
        )
    ]
)
