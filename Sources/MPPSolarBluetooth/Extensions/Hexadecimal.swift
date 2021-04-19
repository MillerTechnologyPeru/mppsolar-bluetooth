//
//  Hexadecimal.swift
//
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

internal extension FixedWidthInteger {
    
    func toHexadecimal() -> String {
        
        var string = String(self, radix: 16)
        while string.utf8.count < (MemoryLayout<Self>.size * 2) {
            string = "0" + string
        }
        return string.uppercased()
    }
}

internal extension Collection where Element == UInt8 {
    
    func toHexadecimal() -> String {
        return reduce("") { $0 + $1.toHexadecimal() }
    }
}
