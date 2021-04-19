//
//  GATTConnection.swift
//  
//
//  Created by Alsey Coleman Miller on 19/04/21.
//

import Foundation
import Bluetooth
import GATT

public extension CentralProtocol {
    
    func connection<T>(
        for peripheral: Peripheral,
        timeout: TimeInterval = .gattDefaultTimeout,
        _ connection: (GATTConnection<Self>) throws -> (T)) throws -> T {
        
        let timeout = Timeout(duration: timeout)
        
        // connect first
        try self.connect(to: peripheral, timeout: try timeout.timeRemaining())
        
        // disconnect eventually
        defer { self.disconnect(peripheral: peripheral) }
        
        // cache MTU
        let maximumTransmissionUnit = try self.maximumTransmissionUnit(for: peripheral)
        
        // get characteristics by UUID
        let characteristics = try self.characteristics(
            for: peripheral,
            timeout: timeout
        )
        
        let cache = GATTConnection(
            central: self,
            timeout: timeout,
            maximumTransmissionUnit: maximumTransmissionUnit,
            characteristics: characteristics
        )
        
        // perform action
        return try connection(cache)
    }
}

public struct GATTConnection <Central: CentralProtocol> {
    
    internal let central: Central
    
    internal let timeout: Timeout
    
    public let maximumTransmissionUnit: GATT.MaximumTransmissionUnit
    
    internal let characteristics: [BluetoothUUID: [Characteristic<Central.Peripheral>]]
}

public extension GATTConnection {
    
    subscript (type: GATTProfileCharacteristic.Type) -> Characteristic<Central.Peripheral>? {
        return try? characteristic(for: type)
    }
    
    func characteristic(for type: GATTProfileCharacteristic.Type) throws -> Characteristic<Central.Peripheral> {
        guard let cache = self.characteristics[type.service.uuid]
            else { throw MPPSolarBluetoothError.serviceNotFound(type.service.uuid) }
        guard let foundCharacteristic = cache.first(where: { $0.uuid == type.uuid })
            else { throw MPPSolarBluetoothError.characteristicNotFound(type.uuid) }
        return foundCharacteristic
    }
    
    func read<T: GATTProfileCharacteristic>(_ type: T.Type) throws -> T {
        let characteristics = self.characteristics[T.service.uuid] ?? []
        return try central.read(type, for: characteristics, timeout: timeout)
    }
    
    func write<T: GATTProfileCharacteristic>(_ value: T, response: Bool = true) throws {
        let characteristics = self.characteristics[T.service.uuid] ?? []
        try central.write(value, for: characteristics, response: response, timeout: timeout)
    }
}

internal extension CentralProtocol {
    
    /// Connects to the device, fetches the data, and performs the action, and disconnects.
    func connection<T>(
        for peripheral: Peripheral,
        characteristics: [GATTProfileCharacteristic.Type],
        timeout: Timeout,
        _ action: ([Characteristic<Peripheral>]) throws -> (T)) throws -> T {
                
        // connect first
        try self.connect(to: peripheral, timeout: try timeout.timeRemaining())
        
        // disconnect eventually
        defer { self.disconnect(peripheral: peripheral) }
        
        // get characteristics by UUID
        let foundCharacteristics = try self.characteristics(
            characteristics,
            for: peripheral,
            timeout: timeout
        )
        
        // perform action
        return try action(foundCharacteristics)
    }
    
    /// Verify a peripheral declares the GATT profile.
    func characteristics(
        _ characteristics: [GATTProfileCharacteristic.Type],
        for peripheral: Peripheral,
        timeout: Timeout) throws -> [Characteristic<Peripheral>] {
                
        // group characteristics by service
        var characteristicsByService = [BluetoothUUID: [BluetoothUUID]]()
        characteristics.forEach {
            characteristicsByService[$0.service.uuid] = (characteristicsByService[$0.service.uuid] ?? []) + [$0.uuid]
        }
        
        var results = [Characteristic<Peripheral>]()
        
        // validate required characteristics
        let foundServices = try discoverServices([], for: peripheral, timeout: try timeout.timeRemaining())
        
        for (serviceUUID, characteristics) in characteristicsByService {
            
            // validate service exists
            guard let service = foundServices.first(where: { $0.uuid == serviceUUID })
                else { throw MPPSolarBluetoothError.serviceNotFound(serviceUUID) }
            
            // validate characteristic exists
            let foundCharacteristics = try discoverCharacteristics([], for: service, timeout: try timeout.timeRemaining())
            
            for characteristicUUID in characteristics {
                
                guard foundCharacteristics.contains(where: { $0.uuid == characteristicUUID })
                    else { throw MPPSolarBluetoothError.characteristicNotFound(characteristicUUID) }
            }
            
            results += foundCharacteristics
        }
        
        return results
    }
    
    /// Fetch all characteristics for all services.
    func characteristics(
        for peripheral: Peripheral,
        timeout: Timeout) throws -> [BluetoothUUID: [Characteristic<Peripheral>]] {
        
        var characteristicsByService = [BluetoothUUID: [Characteristic<Peripheral>]]()
        let foundServices = try discoverServices([], for: peripheral, timeout: try timeout.timeRemaining())
        for service in foundServices {
            let foundCharacteristics = try discoverCharacteristics([], for: service, timeout: try timeout.timeRemaining())
            for characteristic in foundCharacteristics {
                characteristicsByService[service.uuid, default: []].append(characteristic)
            }
        }
        return characteristicsByService
    }
    
    func write <T: GATTProfileCharacteristic> (
        _ characteristic: T,
        for cache: [Characteristic<Peripheral>],
        response: Bool,
        timeout: Timeout) throws {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        try self.writeValue(characteristic.data,
                               for: foundCharacteristic,
                               withResponse: response,
                               timeout: try timeout.timeRemaining())
    }
    
    func read<T: GATTProfileCharacteristic>(
        _ characteristic: T.Type,
        for cache: [Characteristic<Peripheral>],
        timeout: Timeout) throws -> T {
        
        guard let foundCharacteristic = cache.first(where: { $0.uuid == T.uuid })
            else { throw CentralError.invalidAttribute(T.uuid) }
        
        let data = try self.readValue(for: foundCharacteristic,
                                      timeout: try timeout.timeRemaining())
        
        guard let value = T.init(data: data)
            else { throw MPPSolarBluetoothError.invalidCharacteristicValue(T.uuid) }
        
        return value
    }
}
