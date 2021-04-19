//
//  Crypto.swift
//  
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation
import TLVCoding
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

internal struct Crypto {
    
    static func random(_ count: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return random(count, using: &generator)
    }
    
    static func random<T>(_ count: Int, using generator: inout T) -> Data where T: RandomNumberGenerator {
        var data = Data(count: count)
        for index in 0 ..< count {
            data[index] = .random(in: 0...UInt8.max, using: &generator)
        }
        return data
    }
    
    static func encrypt(_ data: Data, using key: KeyData) throws -> Data {
        do {
            let sealedBox = try ChaChaPoly.seal(
                data,
                using: key.cryptoValue,
                nonce: .init()
            )
            return sealedBox.combined
        } catch {
            throw MPPSolarBluetoothError.encryptionError(error)
        }
    }
    
    static func decrypt(_ data: Data, using key: KeyData) throws -> Data {
        do {
            let sealedBox = try ChaChaPoly.SealedBox(combined: data)
            return try ChaChaPoly.open(sealedBox, using: key.cryptoValue)
        } catch {
            throw MPPSolarBluetoothError.encryptionError(error)
        }
    }
        
    static func authenticationCode(for message: AuthenticationMessage, using key: KeyData) -> HashedAuthenticationCode<SHA512> {
        let encoder = TLVEncoder.solar
        let messageData = try! encoder.encode(message)
        return HMAC<SHA512>.authenticationCode(for: messageData, using: key.cryptoValue)
    }
}

public extension AuthenticationData {
    
    init(key: KeyData, message: AuthenticationMessage) {
        let hmac = Crypto.authenticationCode(for: message, using: key)
        self.init(Data(hmac))
    }
    
    func isAuthenticated(with key: KeyData, message: AuthenticationMessage) -> Bool {
        return data == AuthenticationData(key: key, message: message).data
    }
}
