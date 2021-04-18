//
//  Advertisement.swift
//
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

#if canImport(BluetoothHCI)
import Foundation
import BluetoothGAP
import BluetoothHCI

public extension BluetoothHostControllerInterface {
    
    /// LE Advertise with iBeacon
    func setSolarAdvertisingData(solar uuid: UUID, rssi: Int8, commandTimeout: HCICommandTimeout = .default) throws {
        
        do { try enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let beacon = AppleBeacon(uuid: uuid, rssi: rssi)
        let flags: GAPFlags = [
            .lowEnergyGeneralDiscoverableMode,
            .notSupportedBREDR
        ]
        
        try iBeacon(beacon, flags: flags, interval: .min, timeout: commandTimeout)
        
        do { try enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
    
    /// LE Scan Response
    func setSolarScanResponse(commandTimeout: HCICommandTimeout = .default) throws {
        
        do { try enableLowEnergyAdvertising(false) }
        catch HCIError.commandDisallowed { }
        
        let name: GAPCompleteLocalName = "MPPSolar"
        let serviceUUID: GAPCompleteListOf128BitServiceClassUUIDs = [
            UUID(bluetooth: SolarService.uuid)
        ]
        
        let encoder = GAPDataEncoder()
        let data = try encoder.encodeAdvertisingData(name, serviceUUID)
        
        try setLowEnergyScanResponse(data, timeout: commandTimeout)
        
        do { try enableLowEnergyAdvertising() }
        catch HCIError.commandDisallowed { }
    }
}

#endif
