#if os(Linux)
import Glibc
import BluetoothLinux
#elseif os(macOS)
import Darwin
import DarwinGATT
#endif

import Foundation
import CoreFoundation
import Dispatch
import ArgumentParser
import Bluetooth
import GATT
import BluetoothAccessory
import MPPSolar

#if os(Linux)
typealias LinuxCentral = GATTCentral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias LinuxPeripheral = GATTPeripheral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias NativeCentral = LinuxCentral
typealias NativePeripheral = LinuxPeripheral
#elseif os(macOS)
typealias NativeCentral = DarwinCentral
typealias NativePeripheral = DarwinPeripheral
#else
#error("Unsupported platform")
#endif

@main
struct MPPSolarBluetoothTool: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "A deamon for controlling an MPP Solar device via Bluetooth LE.",
        version: "1.0.0"
    )
    
    @Option(help: "The special file path to the solar device.")
    var path: String = "/dev/hidraw0"
    
    @Option(help: "The interval (in seconds) at which data is refreshed.")
    var refreshInterval: Int = 10
    
    @Option(help: "The model of the solar inverter.")
    var model: String = "PIP-2424LV-MSD"
    
    @Option(help: "The received signal strength indicator (RSSI) value (measured in decibels) for the device.")
    var rssi: Int8 = 30
    
    private static var server: BluetoothAccesoryServer<NativePeripheral>!
    
    func validate() throws {
        guard refreshInterval >= 1 else {
            throw ValidationError("<refresh-interval> must be at least 1 second.")
        }
    }
    
    func run() throws {
        
        // start async code
        Task {
            do {
                try await start()
            }
            catch {
                fatalError("\(error)")
            }
        }
        
        // run main loop
        RunLoop.current.run()
    }
    
    private func start() async throws {
        
        let id = UUID()
        let name = "MPPSolar"
        let rssi = self.rssi
        let advertisedService = ServiceType.solarPanel
        
        #if os(Linux)
        guard let hostController = await HostController.default else {
            throw CommandError.bluetoothUnavailable
        }
        let address = try await hostController.readDeviceAddress()
        print("Bluetooth Controller: \(address)")
        let serverOptions = GATTPeripheralOptions(
            maximumTransmissionUnit: .max,
            maximumPreparedWrites: 1000
        )
        let peripheral = LinuxPeripheral(
            hostController: hostController,
            options: serverOptions,
            socket: BluetoothLinux.L2CAPSocket.self
        )
        #elseif os(macOS)
        let peripheral = DarwinPeripheral()
        #endif
        
        print("Initialized \(String(reflecting: type(of: peripheral))) with options:")
        print(peripheral.options)
        
        peripheral.log = { print("Peripheral:", $0) }
        
        // publish GATT server, enable advertising
        try await Self.server = BluetoothAccesoryServer(
            peripheral: peripheral,
            id: id,
            rssi: rssi,
            name: name,
            advertised: advertisedService,
            services: [:]
        )
    }
    /*
    // change advertisment for notifications
    private func characteristicChanged(_ characteristic: CharacteristicType) {
        #if os(Linux)
        let id = self.uuid
        let rssi = self.rssi
        guard let hostController = self.hostController else {
            return
        }
        Task.detached {
            do {
                try await hostController.setAdvertisingData(
                    beacon: .characteristicChanged(id, characteristic),
                    rssi: rssi,
                    flags: [.limitedDiscoverable, .notSupportedBREDR]
                )
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                try await hostController.setAdvertisingData(
                    beacon: .id(id),
                    rssi: rssi
                )
            }
            catch {
                print("Unable to change advertising. \(error.localizedDescription)")
            }
        }
        #endif
    }*/
}

