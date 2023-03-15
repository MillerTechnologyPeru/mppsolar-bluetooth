//
//  Error.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation

enum CommandError: Error {
    
    /// Unable to load Bluetooth controller.
    case bluetoothUnavailable
    
    /// Unable to load solar device.
    case solarDeviceUnavailable
}
