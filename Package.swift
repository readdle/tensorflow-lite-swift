// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "TensorFlowLite",
    products: [
        .library(
            name: "TensorFlowLite",
            targets: ["TensorFlowLite"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "TensorFlowLiteC",
            url: "https://github.com/readdle/tensorflow-lite-swift/releases/download/2.15.0/TensorFlowLiteC-2.15.0.xcframework.zip",
            checksum: "5cf7ded5cee62c97e0975fda74a7d798e150d6b0bd13dd745650c765ef66c7ea"
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
