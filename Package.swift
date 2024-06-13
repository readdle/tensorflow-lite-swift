// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "TensorFlowLite",
    platforms: [
        .iOS(.v12),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "TensorFlowLite",
            targets: ["TensorFlowLite"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "TensorFlowLiteC",
            path: "./TensorFlowLiteC.xcframework"
        ),
        .target(
            name: "TensorFlowLite",
            dependencies: ["TensorFlowLiteC"],
            linkerSettings: [
                .unsafeFlags(["-lc++"], .when(platforms: [.iOS])),
                .linkedLibrary("tensorflowlite_jni", .when(platforms: [.android]))
            ]
        ),
        .testTarget(
            name: "TensorFlowLiteTests",
            dependencies: ["TensorFlowLite"])
    ]
)
