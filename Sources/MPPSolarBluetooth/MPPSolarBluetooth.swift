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
    
    #if os(Linux)
    private var hostController: HostController!
    #endif
    
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
        hostController = await HostController.default
        // keep trying to load Bluetooth device
        while hostController == nil {
            print("No Bluetooth adapters found")
            try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            hostController = await HostController.default
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
        
        #if os(macOS)
        // wait until XPC connection to bluetoothd is established and hardware is on
        try await peripheral.waitPowerOn()
        let advertisingOptions = DarwinPeripheral.AdvertisingOptions(
            localName: name,
            serviceUUIDs: [BluetoothUUID(service: advertisedService)],
            beacon: AppleBeacon(bluetoothAccessory: .id(id), rssi: rssi)
        )
        #elseif os(Linux)
        // write classic BT name
        try await hostController.writeLocalName(name)
        // advertise iBeacon and interval
        try await hostController.setAdvertisingData(
            beacon: .id(id),
            rssi: rssi
        )
        let advertisingOptions = LinuxPeripheral.AdvertisingOptions(
            advertisingData: LowEnergyAdvertisingData(beacon: .id(id), rssi: rssi),
            scanResponse: LowEnergyAdvertisingData(service: advertisedService, name: name)
        )
        #endif
        
        // publish GATT server, enable advertising
        try await peripheral.start(options: advertisingOptions)
        
        #if os(Linux)
        // make sure the device is always discoverable
        Task.detached {
            while controller != nil {
                try await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                do { try await hostController?.enableLowEnergyAdvertising() }
                catch HCIError.commandDisallowed { } // already enabled
                catch {
                    print("Unable to enable advertising")
                    dump(error)
                }
            }
        }
        #endif
    }
    
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
    }
}

