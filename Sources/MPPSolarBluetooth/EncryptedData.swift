//
//  EncryptedData.swift
//
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation

public struct EncryptedData: Equatable, Hashable, Codable {
    
    /// HMAC signature, signed by secret.
    public let authentication: Authentication
    
    /// Encrypted data
    public let encryptedData: Data
}

public extension EncryptedData {
    
    init(encrypt data: Data, with key: KeyData) throws {
        
        do {
            let encryptedData = try Crypto.encrypt(data, using: key)
            self.authentication = Authentication(key: key)
            self.encryptedData = encryptedData
        }
        catch { throw MPPSolarBluetoothError.encryptionError(error) }
    }
    
    func decrypt(with key: KeyData) throws -> Data {
        
        guard authentication.isAuthenticated(with: key)
            else { throw MPPSolarBluetoothError.invalidAuthentication }
        
        // attempt to decrypt
        do { return try Crypto.decrypt(encryptedData, using: key) }
        catch { throw MPPSolarBluetoothError.encryptionError(error) }
    }
}
