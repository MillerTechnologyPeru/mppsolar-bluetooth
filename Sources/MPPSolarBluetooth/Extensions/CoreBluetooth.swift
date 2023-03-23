//
//  CoreBluetooth.swift
//
//
//  Created by Alsey Coleman Miller on 5/10/20.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT
import BluetoothAccessory

internal protocol CoreBluetoothManager {
    
    var state: DarwinBluetoothState { get async }
}

extension DarwinPeripheral: CoreBluetoothManager { }
extension DarwinCentral: CoreBluetoothManager { }

extension CoreBluetoothManager {
    
    /// Wait for CoreBluetooth to be ready.
    func waitPowerOn(warning: Int = 3, timeout: Int = 10) async throws {
        
        var powerOnWait = 0
        while await state != .poweredOn {
            
            // inform user after 3 seconds
            if powerOnWait == warning {
                print("Waiting for CoreBluetooth to be ready, please turn on Bluetooth")
            }
            
            try await Task.sleep(nanoseconds: 1_000_000_000)
            powerOnWait += 1
            guard powerOnWait < timeout
                else { throw CommandError.bluetoothUnavailable }
        }
    }
}

extension DarwinPeripheral: AccessoryPeripheralManager {
    
    public func advertise(
        beacon: AccessoryBeacon,
        rssi: Int8,
        name: String,
        service: ServiceType
    ) async throws {
        let isPoweredOn = await self.state == .poweredOn
        assert(isPoweredOn)
        let advertisingOptions = DarwinPeripheral.AdvertisingOptions(
            localName: name,
            serviceUUIDs: [BluetoothUUID(service: service)],
            beacon: AppleBeacon(bluetoothAccessory: beacon, rssi: rssi)
        )
        if await isAdvertising {
            await stop()
        }
        try await start(options: advertisingOptions)
    }
}

#endif
