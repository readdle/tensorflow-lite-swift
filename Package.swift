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
            name: "RDTensorFlowLiteC",
            url: "https://github.com/readdle/tensorflow-lite-swift/releases/download/2.15.0/RDTensorFlowLiteC-2.15.0.xcframework.zip",
            checksum: "2266eb72627f829be3f87b826f40d350d74a8df69837267698af4ec98799ae11"
        ),
        .target(
            name: "TensorFlowLite",
            dependencies: ["RDTensorFlowLiteC"],
            linkerSettings: [
                .linkedLibrary("tensorflowlite_jni", .when(platforms: [.android]))
            ]
        ),
        .testTarget(
            name: "TensorFlowLiteTests",
            dependencies: ["TensorFlowLite"])
    ]
)
