//
//  AuthenticationDelegate.swift
//  
//
//  Created by Alsey Coleman Miller on 3/27/23.
//

import Foundation
import Bluetooth
import BluetoothAccessory

/// MPP Solar Accessory Authentication Delegate
public protocol MPPSolarAuthenticationDelegate: AnyObject {
    
    var isConfigured: Bool { get async }
        
    var allKeys: [KeysCharacteristic.Item] { get async }
    
    func key(for id: UUID) async -> Key?
    
    func newKey(for id: UUID) async -> NewKey?
    
    func secret(for id: UUID) async -> KeyData?
    
    func setup(_ request: SetupRequest, authenticationMessage: AuthenticationMessage) async -> Bool
    
    func create(_ request: CreateNewKeyRequest, authenticationMessage: AuthenticationMessage) async -> Bool
    
    func confirm(_ request: ConfirmNewKeyRequest, authenticationMessage: AuthenticationMessage) async -> Bool
    
    func remove(_ request: RemoveKeyRequest, authenticationMessage: AuthenticationMessage) async -> Bool
}
