// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "axeptio_sdk",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "axeptio-sdk", targets: ["axeptio_sdk"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "axeptio_sdk",
            dependencies: []
        )
    ]
)
