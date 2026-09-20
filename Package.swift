// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "SwiftQuitCore",
    defaultLocalization: "en",
    platforms: [.macOS(.v11)],
    targets: [
        .target(
            name: "SwiftQuitCore",
            path: "Swift Quit",
            exclude: [
                "AppDelegate.swift",
                "Assets.xcassets",
                "Base.lproj",
                "Swift_Quit.entitlements",
                "SwiftQuit.swift",
                "ViewController.swift"
            ],
            sources: ["WindowVisibility.swift"]
        ),
        .testTarget(
            name: "SwiftQuitCoreTests",
            dependencies: ["SwiftQuitCore"]
        )
    ]
)
