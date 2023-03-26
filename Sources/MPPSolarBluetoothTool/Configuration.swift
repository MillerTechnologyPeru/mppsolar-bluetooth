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
public struct MPPSolarConfiguration: Equatable, Hashable, Codable {
    
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
        rssi: Int8 = .random(in: 20 ... 30),
        model: String = "PIP-2424LV-MSD",
        setupSecret: KeyData = KeyData()
    ) {
        self.id = id
        self.rssi = rssi
        self.model = model
        self.setupSecret = setupSecret
    }
}

internal extension MPPSolarConfiguration {
    
    static let decoder = JSONDecoder()
    
    static let encoder = JSONEncoder()
}

public extension MPPSolarConfiguration {
    
    init(data: Data) throws {
        self = try Self.decoder.decode(MPPSolarConfiguration.self, from: data)
    }
    
    func encode() throws -> Data {
        try Self.encoder.encode(self)
    }
    
    /// Write configuration to file path.
    init(url: URL) throws {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        self = try Self.decoder.decode(MPPSolarConfiguration.self, from: data)
    }
    
    /// Write configuration to file path.
    func write(to url: URL) throws {
        let data = try self.encode()
        try data.write(to: url, options: [.atomic])
    }
}
