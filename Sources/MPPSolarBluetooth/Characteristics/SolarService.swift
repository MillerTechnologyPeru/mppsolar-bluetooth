//
//  SolarService.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import Bluetooth

public enum SolarService: GATTProfileService {
    
    public static let uuid = BluetoothUUID.solarService
    
    public static let isPrimary: Bool = true
    
    public static let characteristics: [GATTProfileCharacteristic.Type] = [
        SolarInformationCharacteristic.self,
        SolarCommandCharacteristic.self
    ]
}
