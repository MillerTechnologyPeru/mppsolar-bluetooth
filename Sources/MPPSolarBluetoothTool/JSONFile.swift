//
//  File.swift
//  
//
//  Created by Alsey Coleman Miller on 3/27/23.
//

import Foundation

/// JSON File
public protocol JSONFile: Codable {
    
    static var encoder: JSONEncoder { get }
    
    static var decoder: JSONDecoder { get }
}

public extension JSONFile {
    
    static var decoder: JSONDecoder { JSONDecoder() }
    
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        #if DEBUG
        encoder.outputFormatting.insert(.prettyPrinted)
        #endif
        encoder.outputFormatting.insert(.sortedKeys)
        return encoder
    }
}

public extension JSONFile {
    
    init(data: Data) throws {
        self = try Self.decoder.decode(Self.self, from: data)
    }
    
    func encode() throws -> Data {
        try Self.encoder.encode(self)
    }
    
    /// Write configuration to file path.
    init(url: URL) throws {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        self = try Self.decoder.decode(Self.self, from: data)
    }
    
    /// Write configuration to file path.
    func write(to url: URL) throws {
        let data = try self.encode()
        try data.write(to: url, options: [.atomic])
    }
}
