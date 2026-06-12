// swift-tools-version: 5.9
// Package.swift — Swift Package Manager configuration for GoTiengViet
// This is used for command-line building and testing

import PackageDescription

let package = Package(
    name: "GoTiengViet",
    platforms: [
        .macOS(.v12) // Minimum macOS 12 Monterey
    ],
    products: [
        .library(
            name: "GoTiengVietEngine",
            targets: ["GoTiengVietEngine"]
        ),
    ],
    targets: [
        // Core engine + utils library — can be tested independently
        .target(
            name: "GoTiengVietEngine",
            dependencies: [],
            path: "GoTiengViet",
            exclude: [
                "Input",
                "UI",
                "Preferences",
                "Resources",
                "Info.plist",
                "main.swift",
                "AppDelegate.swift"
            ],
            sources: [
                "Engine/CharacterMap.swift",
                "Engine/TonePlacement.swift",
                "Engine/TelexProcessor.swift",
                "Engine/VNIProcessor.swift",
                "Engine/VietnameseEngine.swift",
                "Engine/SpellChecker.swift",
                "Engine/MacroEngine.swift",
                "Utils/Constants.swift",
                "Utils/Logger.swift"
            ]
        ),
        // Unit tests for the engine
        .testTarget(
            name: "GoTiengVietEngineTests",
            dependencies: ["GoTiengVietEngine"],
            path: "GoTiengVietTests/EngineTests"
        ),
    ]
)
