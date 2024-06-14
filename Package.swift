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
            url: "https://github.com/readdle/tensorflow-lite-swift/releases/download/2.16.1/TensorFlowLiteC-2.16.1.xcframework.zip",
            checksum: "609d872d61d5553071a1c179ad7ddfc1a73b3ddc020a615e2a726e39fff4105e"
        ),
        .target(
            name: "TensorFlowLite",
            dependencies: ["TensorFlowLiteC"],
            linkerSettings: [
                .linkedLibrary("tensorflowlite_jni", .when(platforms: [.android]))
            ]
        ),
        .testTarget(
            name: "TensorFlowLiteTests",
            dependencies: ["TensorFlowLite"])
    ]
)
