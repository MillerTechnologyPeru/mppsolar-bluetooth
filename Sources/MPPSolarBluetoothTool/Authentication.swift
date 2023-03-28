//
//  MPPSolarAuthentication.swift
//  
//
//  Created by Alsey Coleman Miller on 3/27/23.
//


import Foundation
import MPPSolar
import BluetoothAccessory
import MPPSolarBluetooth

actor MPPSolarAuthentication {
    
    let configurationURL: URL
    
    let authenticationURL: URL
    
    private let fileManager = FileManager()
    
    init(configurationURL: URL, authenticationURL: URL) {
        self.configurationURL = configurationURL
        self.authenticationURL = authenticationURL
    }
}

// MARK: - Methods

private extension MPPSolarAuthentication {
    
    var configuration: MPPSolarConfiguration {
        get throws {
            return try MPPSolarConfiguration(url: configurationURL)
        }
    }
    
    func authenticationFile<T>(_ block: (inout MPPSolarAuthentication.File) -> T) throws -> T {
        let url = authenticationURL
        var file: File
        // create or read file
        if fileManager.fileExists(atPath: url.path) {
            file = File()
            try fileManager.createFile(atPath: url.path, contents: file.encode())
        } else {
            file = try File(url: authenticationURL)
        }
        let oldHash = file.hashValue
        let result = block(&file)
        // save file if changed
        if oldHash != file.hashValue {
            try file.encode().write(to: url, options: [.atomic])
        }
        return result
    }
}

// MARK: - AuthenticationDelegate

extension MPPSolarAuthentication: MPPSolarAuthenticationDelegate {
    
    var isConfigured: Bool {
        do {
            return try authenticationFile { $0.isConfigured }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return false
        }
    }
    
    var allKeys: [BluetoothAccessory.KeysCharacteristic.Item] {
        get {
            do {
                var list = [BluetoothAccessory.KeysCharacteristic.Item]()
                try authenticationFile {
                    $0.keys.forEach {
                        list.append(.key($0.value))
                    }
                    $0.newKeys.forEach {
                        list.append(.newKey($0.value))
                    }
                }
                return list
            }
            catch {
                assertionFailure("\(#function) \(error)")
                return []
            }
        }
    }
    
    func key(for id: UUID) -> BluetoothAccessory.Key? {
        do {
            return try authenticationFile {
                $0.keys[id]
            }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return nil
        }
    }
    
    func newKey(for id: UUID) -> BluetoothAccessory.NewKey? {
        do {
            return try authenticationFile {
                $0.newKeys[id]
            }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return nil
        }
    }
    
    func secret(for id: UUID) -> BluetoothAccessory.KeyData? {
        do {
            guard id != Key.setup else {
                // return setup shared secret
                return try configuration.setupSecret
            }
            return try authenticationFile {
                $0.secretData[id]
            }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return nil
        }
    }
    
    func setup(_ request: BluetoothAccessory.SetupRequest, authenticationMessage: BluetoothAccessory.AuthenticationMessage) async -> Bool {
        do {
            return try authenticationFile {
                // can only be setup once
                guard $0.isConfigured == false else {
                    return false
                }
                let ownerKey = Key(setup: request)
                $0 = .init(owner: ownerKey, secret: request.secret)
                return true
            }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return false
        }
    }
    
    func create(_ request: BluetoothAccessory.CreateNewKeyRequest, authenticationMessage: BluetoothAccessory.AuthenticationMessage) async -> Bool {
        do {
            return try authenticationFile {
                // must be setup first
                guard $0.isConfigured else {
                    return false
                }
                let newKey = NewKey(request: request)
                $0.newKeys[newKey.id] = newKey
                $0.secretData[newKey.id] = request.secret
                return true
            }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return false
        }
    }
    
    func confirm(_ request: BluetoothAccessory.ConfirmNewKeyRequest, authenticationMessage: BluetoothAccessory.AuthenticationMessage) async -> Bool {
        do {
            return try authenticationFile {
                // must be setup first
                guard $0.isConfigured else {
                    return false
                }
                guard let invitation = $0.newKeys[authenticationMessage.id] else {
                    return false
                }
                let key = invitation.confirm()
                $0.newKeys[key.id] = nil
                $0.keys[key.id] = key
                $0.secretData[key.id] = request.secret
                return true
            }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return false
        }
    }
    
    func remove(_ request: BluetoothAccessory.RemoveKeyRequest, authenticationMessage: BluetoothAccessory.AuthenticationMessage) async -> Bool {
        do {
            return try authenticationFile {
                // must be setup first
                guard $0.isConfigured else {
                    return false
                }
                // verify requestee is admin
                
                // verify key exists
                guard $0.keys.keys.contains(request.id) && $0.newKeys.keys.contains(request.id) else {
                    return false
                }
                if $0.keys.keys.contains(request.id) {
                    $0.keys.removeValue(forKey: request.id)
                    return true
                } else if $0.newKeys.keys.contains(request.id) {
                    $0.newKeys.removeValue(forKey: request.id)
                    return true
                } else {
                    return false
                }
            }
        }
        catch {
            assertionFailure("\(#function) \(error)")
            return false
        }
    }
}

// MARK: - Supporting Types

extension MPPSolarAuthentication {
    
    /// MPP Solar Authentication File.
    public struct File: Equatable, Hashable, Codable, JSONFile {
        
        public var keys: [UUID: Key]
        
        public var newKeys: [UUID: NewKey]
        
        public var secretData: [UUID: KeyData]
        
        public init() {
            self.keys = [:]
            self.newKeys = [:]
            self.secretData = [:]
        }
    }
}


public extension MPPSolarAuthentication.File {
    
    var isConfigured: Bool {
        keys.contains(where: { $0.value.permission == .owner })
    }
    
    init(owner: Key, secret: KeyData) {
        assert(owner.permission == .owner)
        self.keys = [owner.id : owner]
        self.newKeys = [:]
        self.secretData = [owner.id : secret]
    }
}
