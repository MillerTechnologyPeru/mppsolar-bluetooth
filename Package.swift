// swift-tools-version:5.1
import PackageDescription

var package = Package(
    name: "mppsolar-bluetooth",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        /*
        .executable(
            name: "mppsolar-bluetooth",
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
        ),
        .package(
            url: "https://github.com/apple/swift-crypto.git",
            .upToNextMinor(from: "1.1.6")
        ),
        .package(
            url: "https://github.com/PureSwift/TLVCoding.git",
            .branch("master")
        ),
    ],
    targets: [
        .target(
            name: "MPPSolarBluetooth",
            dependencies: [
                "MPPSolar",
                "Bluetooth",
                "GATT",
                "TLVCoding"
            ]
        ),
        .testTarget(
            name: "MPPSolarBluetoothTests",
            dependencies: ["MPPSolarBluetooth"]
        ),
    ]
)

#if os(Linux)
package.targets[0].dependencies.append("Crypto")
#endif
