// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "OnlyEQ",
    platforms: [.macOS("14.4")],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.4"),
    ],
    targets: [
        // Command Line Tools ship no XCTest/Testing module, so the self-test
        // suite runs inside the app binary: `swift run OnlyEQ --test`.
        .executableTarget(
            name: "OnlyEQ",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/OnlyEQ",
            resources: [.copy("Fixtures")]
        ),
    ]
)
