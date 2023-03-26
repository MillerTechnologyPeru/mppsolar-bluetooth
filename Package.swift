// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "mppsolar-bluetooth",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "mppsolar-bluetooth",
            targets: ["MPPSolarBluetooth"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/MillerTechnologyPeru/MPPSolar.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/MillerTechnologyPeru/BluetoothAccessory.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            .upToNextMajor(from: "6.0.0")
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/BluetoothLinux.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.2.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "MPPSolarBluetooth",
            dependencies: [
                "MPPSolar",
                "BluetoothAccessory",
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth",
                    condition: .when(platforms: [.macOS, .linux])
                ),
                .product(
                    name: "BluetoothHCI",
                    package: "Bluetooth",
                    condition: .when(platforms: [.macOS, .linux])
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth",
                    condition: .when(platforms: [.macOS, .linux])
                ),
                .product(
                    name: "DarwinGATT",
                    package: "GATT",
                    condition: .when(platforms: [.macOS])
                ),
                .product(
                    name: "BluetoothLinux",
                    package: "BluetoothLinux",
                    condition: .when(platforms: [.linux])
                ),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        )
    ]
)
