//
//  CommandCharacteristic.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import Bluetooth
import GATT
import MPPSolar

/// MPPSolar Command  GATT Characteristic.
public struct SolarCommandCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "CC3CDD9F-A4B0-4F7D-88B0-6D3A93AE0002")!
    
    public static let service: GATTProfileService.Type = SolarService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Encrypted payload.
    public let encryptedData: EncryptedData
    
    public init<T: Command>(command: T, sharedSecret: KeyData) throws {
        try self.init(command: command.rawValue, sharedSecret: sharedSecret)
    }
    
    public init(command: String, sharedSecret: KeyData) throws {
        
        self.encryptedData = try EncryptedData(
            encrypt: Data(command.utf8),
            with: sharedSecret
        )
    }
    
    public func decrypt(with sharedSecret: KeyData) throws -> String {
        
        let data = try encryptedData.decrypt(with: sharedSecret)
        guard let value = String(data: data, encoding: .utf8) else {
            throw MPPSolarBluetoothError.invalidCharacteristicValue(type(of: self).uuid)
        }
        return value
    }
}
