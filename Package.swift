// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

// import PackageDescription

// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "t-swift",
    platforms: [
        .macOS(.v11), // Set the minimum macOS version to 11.0
    ],
    products: [
        .executable(name: "t-swift", targets: ["t-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.0"),
        .package(url: "https://github.com/rensbreur/SwiftTUI.git", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "t-swift",
            dependencies: ["Alamofire", "SwiftSoup", "SwiftTUI"]
        ),
    ]
)

/*
 let package = Package(
     name: "t-swift",
     targets: [
         // Targets are the basic building blocks of a package, defining a module or a test suite.
         // Targets can depend on other targets in this package and products from dependencies.
         .executableTarget(
             name: "t-swift"),
     ]
 )
 */
