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

/// MPPSolar Information Characteristic
public struct SolarInformationCharacteristic: TLVCharacteristic, Equatable, Hashable, Codable {
    
    public static let uuid = BluetoothUUID(rawValue: "CC3CDD9F-A4B0-4F7D-88B0-6D3A93AE0001")!
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.read]
    
    public static let service: GATTProfileService.Type = SolarService.self
    
    // MARK: - Properties
    
    /// Device identifier
    public let uuid: UUID
    
    /// Firmware build number
    public let buildVersion: SolarBuildVersion
    
    /// Device serial number
    public let serialNumber: SerialNumber
    
    /// Device serial number
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
