//
//  CommandResponseCharacteristic.swift
//  
//
//  Created by Alsey Coleman Miller on 19/04/21.
//

import Foundation
import Bluetooth
import GATT
import MPPSolar

/// MPPSolar Command  GATT Characteristic.
public struct SolarCommandResponseCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID.solarCommandResponseCharacteristic
    
    public static let service: GATTProfileService.Type = SolarService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.notify]
    
    /// Encrypted payload.
    public let chunk: Data
    
}
