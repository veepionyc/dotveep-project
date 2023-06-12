// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.


/*

Example package that is compatible with pre-existing XCode project

*/

import PackageDescription

let package = Package(
    name: "dotveep"
    ,platforms: [.iOS(.v14)]
   , products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "dotveep",
            targets: ["dotveep"]),
        .library(
            name: "VPKProtobuf",
            targets: ["VPKProtobuf"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "dotveep"
            ,dependencies: ["VPKProtobuf"]
            ,path: "dotveep"
            ,publicHeadersPath: "."
            ,cSettings: [
               .unsafeFlags(
                ["-fno-objc-arc"]
               )
            ]
        )
        
        ,.target(
            name: "VPKProtobuf"
            ,path: "VPKProtobuf"
            ,publicHeadersPath: "objectivec"
            ,cSettings: [
                .unsafeFlags(
                    ["-fno-objc-arc"]
                )
            ]
        )
        
    ]
)
