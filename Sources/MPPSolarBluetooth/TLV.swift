//
//  TLV.swift
//
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import TLVCoding

internal extension TLVEncoder {
    
    static var solar: TLVEncoder {
        var encoder = TLVEncoder()
        encoder.numericFormatting = .littleEndian
        encoder.uuidFormatting = .bytes
        return encoder
    }
}

internal extension TLVDecoder {
    
    static var solar: TLVDecoder {
        var decoder = TLVDecoder()
        decoder.numericFormatting = .littleEndian
        decoder.uuidFormatting = .bytes
        return decoder
    }
}

// MARK: - TLVCharacteristic

public protocol TLVCharacteristic: GATTProfileCharacteristic {
    
    /// TLV Encoder used to encode values.
    static var encoder: TLVEncoder { get }
    
    /// TLV Decoder used to decode values.
    static var decoder: TLVDecoder { get }
}

public extension TLVCharacteristic {
    
    static var encoder: TLVEncoder { return .solar }
    static var decoder: TLVDecoder { return .solar }
}

public extension TLVCharacteristic where Self: Codable {
    
    init?(data: Data) {
        
        guard let value = try? Self.decoder.decode(Self.self, from: data)
            else { return nil }
        self = value
    }
    
    var data: Data {
        return try! Self.encoder.encode(self)
    }
}
