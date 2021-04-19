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
    
    public static let uuid = BluetoothUUID.solarCommandCharacteristic
    
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

// MARK: - Extensions

public extension CentralProtocol {
    
    /// Sends the specified command to the solar device.
    ///
    /// - Parameter peripheral: The Bluetooth LE peripheral.
    ///
    /// - Returns: The command response or acknowledgement.
    func solarCommand<T>(_ command: T,
                      using sharedSecret: KeyData,
                      for peripheral: Peripheral,
                      timeout: TimeInterval = .gattDefaultTimeout) throws -> T.Response where T: Command {
        
        return try connection(for: peripheral, timeout: timeout) {
            try $0.solarCommand(command, using: sharedSecret)
        }
    }
    
    /// Sends the specified command to the solar device.
    ///
    /// - Parameter peripheral: The Bluetooth LE peripheral.
    ///
    /// - Returns: The command response or acknowledgement.
    func solarCommand(_ command: String,
                      using sharedSecret: KeyData,
                      for peripheral: Peripheral,
                      timeout: TimeInterval = .gattDefaultTimeout) throws -> String {
        
        return try connection(for: peripheral, timeout: timeout) {
            try $0.solarCommand(command, using: sharedSecret)
        }
    }
}

public extension GATTConnection {
    
    /// Sends the specified command to the solar device.
    ///
    /// - Parameter peripheral: The Bluetooth LE peripheral.
    ///
    /// - Returns: The command response or acknowledgement.
    func solarCommand<T>(_ command: T, using sharedSecret: KeyData) throws -> T.Response where T: Command {
        let responseString = try solarCommand(command.rawValue, using: sharedSecret)
        guard let response = T.Response(rawValue: responseString) else {
            throw MPPSolarError.invalidResponse(Data(responseString.utf8))
        }
        return response
    }
    
    /// Sends the specified command to the solar device.
    ///
    /// - Parameter peripheral: The Bluetooth LE peripheral.
    ///
    /// - Returns: The command response or acknowledgement.
    func solarCommand(_ command: String, using sharedSecret: KeyData) throws -> String {
        try write(SolarCommandCharacteristic(command: command, sharedSecret: sharedSecret))
        fatalError()
    }
}
