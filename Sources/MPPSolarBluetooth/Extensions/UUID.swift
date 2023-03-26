//
//  UUID.swift
//  
//
//  Created by Alsey Coleman Miller on 3/26/23.
//

import Foundation
import Bluetooth

internal extension UUID {
    
    init(solarAccessory: UInt32) {
        self.init(UInt128(solarAccessory: solarAccessory))
    }
    
    init(solarAccessory: (UInt16, UInt16)) {
        self.init(UInt128(solarAccessory: solarAccessory))
    }
}

internal extension BluetoothUUID {
    
    init(solarAccessory: UInt32) {
        self = .bit128(.init(solarAccessory: solarAccessory))
    }
    
    init(solarAccessory: (UInt16, UInt16)) {
        self = .bit128(.init(solarAccessory: solarAccessory))
    }
}

internal extension UInt128 {
    
    init(solarAccessory: UInt32) {
        let bytes = solarAccessory.bigEndian.bytes
        self.init(bigEndian: .init(bytes: (bytes.0, bytes.1, bytes.2, bytes.3, 0x00, 0x00, 0x10, 0x00, 0xBA, 0x00, 0xCD, 0xA0, 0x00, 0x02, 0x0C, 0xDA)))
    }
    
    init(solarAccessory: (UInt16, UInt16)) {
        let bytes0 = solarAccessory.0.bigEndian.bytes
        let bytes1 = solarAccessory.1.bigEndian.bytes
        let value = UInt32(bigEndian: UInt32(bytes: (bytes0.0, bytes0.1, bytes1.0, bytes1.1)))
        self.init(solarAccessory: value)
    }
}
