//
//  Error.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import Bluetooth

/// MPPSolar Bluetooth Error
public enum MPPSolarBluetoothError: Error {
    
    /// No service with UUID found.
    case serviceNotFound(BluetoothUUID)
    
    /// No characteristic with UUID found.
    case characteristicNotFound(BluetoothUUID)
    
    /// The characteristic's value could not be parsed. Invalid data.
    case invalidCharacteristicValue(BluetoothUUID)
    
    /// Not a compatible peripheral
    case incompatiblePeripheral(Error?)
    
    /// Encryption error.
    case encryptionError(Error)
    
    /// HMAC error
    case invalidAuthentication
}
/*
// MARK: - CustomNSError

#if canImport(Darwin)

extension MPPSolarBluetoothError: CustomNSError {
    
    public enum UserInfoKey: String {
        
        /// Bluetooth UUID value (for characteristic or service).
        case uuid = "com.mppsolar.bluetooth.error.uuid"
        
        /// Data
        case data = "com.mppsolar.bluetooth.error.data"
    }
    
    /// The domain of the error.
    public static var errorDomain: String { return "com.mppsolar.bluetooth.error" }
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        
        var userInfo = [String : Any](minimumCapacity: 2)
        switch self {
        case let .serviceNotFound(uuid):
            let description = String(format: NSLocalizedString("No service with UUID %@ found.", comment: "MPPSolarBluetoothError.serviceNotFound"), uuid.description)
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
        case let .characteristicNotFound(uuid):
            let description = String(format: NSLocalizedString("No characteristic with UUID %@ found.", comment: "MPPSolarBluetoothError.characteristicNotFound"), uuid.description)
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
        case let .invalidCharacteristicValue(uuid):
            let description = String(format: NSLocalizedString("The value of characteristic %@ could not be parsed.", comment: "MPPSolarBluetoothError.invalidCharacteristicValue"), uuid.description)
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[UserInfoKey.uuid.rawValue] = uuid
        case let .incompatiblePeripheral(error):
            let description = String(format: NSLocalizedString("Incompatible peripheral.", comment: "MPPSolarBluetoothError.incompatiblePeripheral"))
            userInfo[NSLocalizedDescriptionKey] = description
            userInfo[NSUnderlyingErrorKey] = error
        }
        return userInfo
    }
}

#endif
*/
