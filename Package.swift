// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mppsolar-bluetooth",
    products: [
        /*
        .executable(
            name: "mppsolar-bluetooth-deamon",
            targets: ["MPPSolarBluetoothServer"]
        ),*/
        .library(
            name: "MPPSolarBluetooth",
            targets: ["MPPSolarBluetooth"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/MillerTechnologyPeru/MPPSolar.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            .upToNextMinor(from: "0.1.0")
        ),
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/BluetoothLinux.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/BluetoothDarwin.git",
            .branch("master")
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MPPSolarBluetooth",
            dependencies: []),
        .testTarget(
            name: "MPPSolarBluetoothTests",
            dependencies: ["MPPSolarBluetooth"]),
    ]
)
