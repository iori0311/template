// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Habit-Tracker-backend",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    /// productsのnameがビルド時に指定する実行可能ファイルの名前になる。
    /// targetsのnameはproductsを構成する構成単位の名前
    products: [
        .executable(name: "HummingbirdServer", targets: ["Habit-Tracker-backend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.10.0")
        // .package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "1.1.0"),

    ],
    targets: [
        .executableTarget(name: "Habit-Tracker-backend",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "Crypto", package: "swift-crypto")

            ],
            path: "Sources/App"
        ),
        .testTarget(name: "Habit-Tracker-backendTests",
            dependencies: [
                .byName(name: "Habit-Tracker-backend"),
                .product(name: "HummingbirdTesting", package: "hummingbird")
            ],
            path: "Tests/AppTests"
        )
    ]
)
