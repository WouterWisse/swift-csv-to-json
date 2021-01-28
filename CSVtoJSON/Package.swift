// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CSVtoJSON",
    products: [
        .library(
            name: "CSVtoJSON",
            targets: ["CSVtoJSON"]),
    ],
    targets: [
        .target(
            name: "CSVtoJSON",
            dependencies: []),
        .testTarget(
            name: "CSVtoJSONTests",
            dependencies: ["CSVtoJSON"],
            resources: [
                .copy("Resources"),
            ]),
    ]
)
