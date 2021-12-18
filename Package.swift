// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GRPHLexer",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GRPHLexer",
            targets: ["GRPHLexer"]),
        .library(
            name: "GRPHValues",
            targets: ["GRPHValues"]),
        .library(
            name: "GRPHGenerator",
            targets: ["GRPHGenerator"]),
        .library(
            name: "GRPHRuntime",
            targets: ["GRPHRuntime"]),
        .library(
            name: "DocGen",
            targets: ["DocGen"]),
        .executable(
            name: "CLI",
            targets: ["CLI"]),
        .executable(
            name: "LSP",
            targets: ["LSP"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/Snowy1803/Rainbow", .branch("master")),
        .package(url: "https://github.com/Snowy1803/sourcekit-lsp", .branch("main")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GRPHLexer",
            dependencies: []),
        .target(
            name: "GRPHValues",
            dependencies: []),
        .target(
            name: "GRPHGenerator",
            dependencies: ["GRPHLexer", "GRPHValues"]),
        .target(
            name: "DocGen",
            dependencies: ["GRPHGenerator"],
            resources: [.process("builtins.grph")]),
        .target(
            name: "GRPHRuntime",
            dependencies: ["GRPHValues"]),
        
        .executableTarget(
            name: "CLI",
            dependencies: [
                "GRPHGenerator", "GRPHRuntime", "DocGen",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Rainbow", package: "Rainbow"),
            ]),
        .executableTarget(
            name: "LSP",
            dependencies: [
                "GRPHGenerator", "DocGen",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "LSPBindings", package: "sourcekit-lsp"),
            ]),
        
        .testTarget(
            name: "GRPHLexerTests",
            dependencies: ["GRPHLexer"]),
        .testTarget(
            name: "GeneratorTests",
            dependencies: ["DocGen"]),
    ]
)
