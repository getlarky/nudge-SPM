// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

// Pre-traits stand-in for swift-tools 6.1 package traits. Defaults to geo-enabled so
// normal SPM consumption matches CocoaPods/existing behavior; set NUDGE_GEO_ENABLED=0
// in the environment (see build_xcframework.sh) to produce a build with no location
// code compiled in, for the one client that needs a location-free framework.
let geoEnabled = ProcessInfo.processInfo.environment["NUDGE_GEO_ENABLED"] != "0"
let nudgeSwiftSettings: [SwiftSetting] = geoEnabled ? [.define("GEO_ENABLED")] : []

let package = Package(
    name: "Nudge",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Nudge",
            type: .dynamic,
            targets: ["Nudge"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Nudge",
            path: "Sources/Nudge",
            swiftSettings: nudgeSwiftSettings),
        .testTarget(
            name: "NudgeTests",
            dependencies: ["Nudge"]
        ),
    ]
)
