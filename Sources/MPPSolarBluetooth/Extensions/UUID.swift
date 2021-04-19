//
//  UUID.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import Bluetooth

public extension BluetoothUUID {
    
    static var solarService: BluetoothUUID {
        return BluetoothUUID(rawValue: "CC3CDD9F-A4B0-4F7D-88B0-6D3A93AE0000")!
    }
    
    static var solarInformationCharacteristic: BluetoothUUID {
        return BluetoothUUID(rawValue: "CC3CDD9F-A4B0-4F7D-88B0-6D3A93AE0001")!
    }
    
    static var solarCommandCharacteristic: BluetoothUUID {
        return BluetoothUUID(rawValue: "CC3CDD9F-A4B0-4F7D-88B0-6D3A93AE0002")!
    }
}
