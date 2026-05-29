// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Memo",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(
            url: "https://github.com/argmaxinc/WhisperKit.git",
            from: "0.9.0"
        ),
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            from: "8.40.0"
        )
    ],
    targets: [
        .target(
            name: "Memo",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit", condition: .when(platforms: [.macOS])),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources/Memo",
            resources: [
                .process("Resources"),
            ]
        ),
        .executableTarget(
            name: "MemoMain",
            dependencies: ["Memo"],
            path: "Sources/MemoMain"
        ),
        .testTarget(
            name: "MemoTests",
            dependencies: ["Memo"],
            path: "Tests/MemoTests"
        )
    ]
)
