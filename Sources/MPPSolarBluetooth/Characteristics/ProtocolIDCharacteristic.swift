//
//  MPPSolarProtocolIDCharacteristic.swift
//  
//
//  Created by Alsey Coleman Miller on 3/26/23.
//

import Foundation
import Bluetooth
import GATT
import BluetoothAccessory
import MPPSolar

/// MPP Solar Protocol ID Characteristic
public struct MPPSolarProtocolIDCharacteristic: Equatable, Hashable, AccessoryCharacteristic {
    
    public static var type: BluetoothUUID { BluetoothUUID(characteristic: .protocolID) }
    
    public static var properties: BitMaskOptionSet<BluetoothAccessory.CharacteristicProperty> { [.read, .encrypted] }
    
    public static var name: String { MPPSolarCharacteristicType.protocolID.description }
    
    public init(value: ProtocolID) {
        self.value = value
    }
    
    public var value: ProtocolID
}

// MARK: - CharacteristicCodable

extension ProtocolID: BluetoothAccessory.CharacteristicCodable {
    
    public static var characteristicFormat: CharacteristicFormat { .uint32 }
    
    public var characteristicValue: CharacteristicValue { .uint32(UInt32(rawValue)) }
    
    public init?(characteristicValue: CharacteristicValue) {
        guard let rawValue = UInt32(characteristicValue: characteristicValue) else {
            return nil
        }
        self.init(rawValue: UInt(rawValue))
    }
}

// MARK: - Central


