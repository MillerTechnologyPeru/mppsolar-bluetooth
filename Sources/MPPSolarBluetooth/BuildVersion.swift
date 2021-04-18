//
//  Version.swift
//
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

public struct SolarBuildVersion: RawRepresentable, Equatable, Hashable, Codable {
    
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        
        self.rawValue = rawValue
    }
}

// MARK: - Current Version

public extension SolarBuildVersion {
    
    static var current: SolarBuildVersion { return SolarBuildVersion(rawValue: GitCommits) }
}

// MARK: - CustomStringConvertible

extension SolarBuildVersion: CustomStringConvertible {
    
    public var description: String {
        
        return rawValue.description
    }
}
