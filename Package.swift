// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Memo",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // WhisperKit: Apple-native on-device speech recognition (Apple Silicon + CoreML).
        // Used by LocalWhisperService for offline transcription fallback.
        .package(
            url: "https://github.com/argmaxinc/WhisperKit.git",
            from: "0.9.0"
        )
    ],
    targets: [
        .target(
            name: "Memo",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit", condition: .when(platforms: [.macOS]))
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
