//
//  Configuration.swift
//  
//
//  Created by Alsey Coleman Miller on 3/26/23.
//

import Foundation
import MPPSolar
import BluetoothAccessory

/// MPP Solar device configuration.
public struct MPPSolarConfiguration: Equatable, Hashable, Codable, JSONFile {
    
    /// Accessory Identifier
    public let id: UUID
    
    /// The received signal strength indicator (RSSI) value (measured in decibels) for the device.
    public let rssi: Int8
    
    /// The model of the solar inverter.
    public let model: String
    
    /// The secret payload used for setup pairing.
    public let setupSecret: BluetoothAccessory.KeyData
    
    public init(
        id: UUID = UUID(),
        rssi: Int8,
        model: String = "PIP-2424LV-MSD",
        setupSecret: KeyData = KeyData()
    ) {
        self.id = id
        self.rssi = rssi
        self.model = model
        self.setupSecret = setupSecret
    }
}
