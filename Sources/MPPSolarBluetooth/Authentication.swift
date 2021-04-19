//
//  AuthenticationMessage.swift
//
//
//  Created by Alsey Coleman Miller on 18/04/21.
//

import Foundation

public struct Authentication: Equatable, Hashable, Codable {
        
    public let message: AuthenticationMessage
    
    public let signedData: AuthenticationData
    
    public init(key: KeyData,
                message: AuthenticationMessage = AuthenticationMessage()) {
        
        self.message = message
        self.signedData = AuthenticationData(key: key, message: message)
    }
    
    public func isAuthenticated(with key: KeyData) -> Bool {
        return signedData.isAuthenticated(with: key, message: message)
    }
}

/// HMAC Message
public struct AuthenticationMessage: Equatable, Hashable, Codable {
    
    public let date: Date
    
    public let nonce: Nonce
    
    public init(date: Date = Date(),
                nonce: Nonce = Nonce()) {
        
        self.date = date
        self.nonce = nonce
    }
}
