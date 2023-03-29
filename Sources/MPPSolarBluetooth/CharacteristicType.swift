//
//  CharacteristicType.swift
//  
//
//  Created by Alsey Coleman Miller on 3/26/23.
//

import Foundation
import Bluetooth

/// MPP Solar Characteristics
public enum MPPSolarCharacteristicType: UInt16, Codable, CaseIterable {
    
    /// Protocol ID Characteristic
    case protocolID
    
    /// Firmware Main CPU
    case firmware
    
    /// Firmware Secondary CPU
    case firmware2
    
    /// Solar Command Request
    case solarRequest
    
    /// Solar Command Response
    case solarResponse
    
    /// Read-only power state for inverter output..
    case inverterPowerState
}

// MARK: - CustomStringConvertible

extension MPPSolarCharacteristicType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .protocolID:
            return "Protocol ID"
        case .firmware:
            return "Firmware Main CPU"
        case .firmware2:
            return "Firmware Secondary CPU"
        case .solarRequest:
            return "Solar Command Request"
        case .solarResponse:
            return "Solar Command Response"
        case .inverterPowerState:
            return "Inverter Power State"
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
