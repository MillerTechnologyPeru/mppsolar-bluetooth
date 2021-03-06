//
//  InformationCharacteristic.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import Bluetooth
import GATT
import MPPSolar

/// MPPSolar Information GATT Characteristic.
public struct SolarInformationCharacteristic: TLVCharacteristic, Equatable, Hashable, Codable {
    
    public static let uuid = BluetoothUUID.solarInformationCharacteristic
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.read]
    
    public static let service: GATTProfileService.Type = SolarService.self
    
    // MARK: - Properties
    
    /// Device identifier
    public let uuid: UUID
    
    /// Firmware build number
    public let buildVersion: SolarBuildVersion
    
    /// Device serial number
    public let serialNumber: SerialNumber
    
    /// Device protocol ID.
    public let protocolID: ProtocolID
    
    // MARK: - Initialization
    
    public init(uuid: UUID,
                buildVersion: SolarBuildVersion = .current,
                serialNumber: SerialNumber,
                protocolID: ProtocolID) {
        
        self.uuid = uuid
        self.buildVersion = buildVersion
        self.serialNumber = serialNumber
        self.protocolID = protocolID
    }
}

// MARK: - Extensions

public extension CentralProtocol {
    
    /// Fetches the information for the specified solar device.
    ///
    /// - Parameter peripheral: The Bluetooth LE peripheral.
    ///
    /// - Returns: The information for the specified solar device.
    func solarInformation(for peripheral: Peripheral,
                          timeout: TimeInterval = .gattDefaultTimeout) throws -> SolarInformationCharacteristic {
        
        return try connection(for: peripheral, timeout: timeout) {
            try $0.solarInformation()
        }
    }
}

public extension GATTConnection {
    
    /// Fetches the information for the specified solar device
    ///
    /// - Parameter peripheral: The Bluetooth LE peripheral.
    ///
    /// - Returns: The information for the specified solar device.
    func solarInformation() throws -> SolarInformationCharacteristic {
        return try read(SolarInformationCharacteristic.self)
    }
}
