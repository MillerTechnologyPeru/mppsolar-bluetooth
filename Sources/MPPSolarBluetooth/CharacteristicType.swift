//
//  CharacteristicType.swift
//  
//
//  Created by Alsey Coleman Miller on 3/26/23.
//

import Foundation
import Bluetooth

public enum MPPSolarCharacteristicType: UInt16, Codable, CaseIterable {
    
    /// Protocol ID Characteristic
    case protocolID
}

// MARK: - CustomStringConvertible

extension MPPSolarCharacteristicType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .protocolID:
            return "Protocol ID"
        }
    }
}

// MARK: - UUID Extensions

public extension UUID {
    
    init(characteristic: MPPSolarCharacteristicType) {
        self.init(solarAccessory: (0x0002, characteristic.rawValue))
    }
}

public extension BluetoothUUID {
    
    init(characteristic: MPPSolarCharacteristicType) {
        self.init(uuid: .init(characteristic: characteristic))
    }
}

public extension MPPSolarCharacteristicType {
    
    init?(uuid: BluetoothUUID) {
        guard let value = Self.allCases.first(where: { BluetoothUUID(characteristic: $0) == uuid }) else {
            return nil
        }
        self = value
    }
}
