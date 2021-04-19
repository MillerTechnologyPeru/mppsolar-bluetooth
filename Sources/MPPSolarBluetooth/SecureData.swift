//
//  SecureData.swift
//
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation

#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

/// Secure Data Protocol. 
public protocol SecureData {
    
    /// The data length. 
    static var length: Int { get }
    
    /// Initialize with data.
    init?(data: Data)
    
    /// Calls the given closure with the contents of underlying storage.
    ///
    /// - note: Calling `withUnsafeBytes` multiple times does not guarantee that
    ///         the same buffer pointer will be passed in every time.
    /// - warning: The buffer argument to the body should not be stored or used
    ///            outside of the lifetime of the call to the closure.
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension SecureData where Self: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes {
            hasher.combine(bytes: $0)
        }
    }
}

public extension SecureData where Self: Decodable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard let value = Self(data: data) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid number of bytes \(data.count) for \(String(reflecting: Self.self))"))
        }
        self = value
    }
}

public extension SecureData where Self: Encodable {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try self.withUnsafeBytes {
            try container.encode(Data($0)) // FIXME: Don't copy data
        }
    }
}

// MARK: - Key

/// Authentication Key (256 bit)
public struct KeyData: SecureData, Equatable, Hashable, Codable {
    
    public static let length = SymmetricKeySize.bits256.bitCount / 8
    
    internal typealias CryptoType = SymmetricKey
    
    internal let cryptoValue: CryptoType
    
    public init?(data: Data) {
        guard data.count == type(of: self).length
            else { return nil }
        self.cryptoValue = CryptoType(data: data)
    }
    
    /// Initializes a `Key` with a random value.
    public init() {
        self.cryptoValue = CryptoType(size: .bits256)
    }
    
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try self.cryptoValue.withUnsafeBytes(body)
    }
}

// MARK: - Nonce

/// Cryptographic nonce
public struct Nonce: SecureData, Equatable, Hashable, Codable {
    
    public static let length = 16
    
    internal let data: Data
    
    public init?(data: Data) {
        guard data.count == type(of: self).length
            else { return nil }
        self.data = data
    }
    
    public init() {
        self.data = Crypto.random(type(of: self).length)
    }
    
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try data.withUnsafeBytes(body)
    }
}

// MARK: - HMAC

/// HMAC data
public struct AuthenticationData: SecureData, Equatable, Hashable, Codable {
    
    public static let length = 16
    
    internal let data: Data
    
    public init?(data: Data) {
        guard data.count == type(of: self).length
            else { return nil }
        self.data = data
    }
    
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try data.withUnsafeBytes(body)
    }
}
