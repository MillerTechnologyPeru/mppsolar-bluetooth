//
//  SolarService.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import Bluetooth

public enum SolarService: GATTProfileService {
    
    public static let uuid = BluetoothUUID(rawValue: "CC3CDD9F-A4B0-4F7D-88B0-6D3A93AE0000")!
    
    public static let isPrimary: Bool = true
    
    public static let characteristics: [GATTProfileCharacteristic.Type] = [
        SolarInformationCharacteristic.self,
        SolarCommandCharacteristic.self
    ]
}
