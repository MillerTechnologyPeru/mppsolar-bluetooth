//
//  Server.swift
//  
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

import Foundation
import Bluetooth
import BluetoothGATT
import BluetoothHCI
import BluetoothGAP
import GATT
#if canImport(DarwinGATT)
import DarwinGATT
#endif
import BluetoothAccessory
import MPPSolar

public actor MPPSolarBluetoothServer <Peripheral: AccessoryPeripheralManager>: BluetoothAccessoryServerDelegate {
    
    // MARK: - Properties
    
    public let id: UUID
    
    let rssi: Int8
    
    let model: String
    
    let name: String
    
    let manufacturer: String
    
    let accessoryType: AccessoryType
    
    let advertisedService: ServiceType
    
    let softwareVersion: String
    
    let serialNumber: SerialNumber // loaded from solar device
    
    let protocolID: ProtocolID
    
    
    
    public let setupSharedSecret: BluetoothAccessory.KeyData
    
    private var server: BluetoothAccessoryServer<Peripheral>!
    
    private var keySecrets = [UUID: KeyData]()
    private var keys = [UUID: Key]()
    private var newKeys = [UUID: NewKey]()
    
    public var cryptoHash: Nonce {
        get async {
            await self.authentication.cryptoHash
        }
    }
    
    var lastIdentify: (UUID, Date)?
    
    nonisolated var information: InformationService {
        get async {
            await server[InformationService.self]
        }
    }
    
    nonisolated var authentication: AuthenticationService {
        get async {
            await server[AuthenticationService.self]
        }
    }
    
    nonisolated var outlet: OutletService {
        get async {
            await server[OutletService.self]
        }
    }
    
    init(
        peripheral: Peripheral,
        device: MPPSolar,
        id: UUID,
        rssi: Int8,
        model: String,
        setupSharedSecret: BluetoothAccessory.KeyData
    ) async throws {
        
        let name = "MPPSolar"
        let manufacturer = "MPP Solar Inc."
        let accessoryType = AccessoryType.solarPanel
        let advertisedService = ServiceType.solarPanel
        let softwareVersion = MPPSolarBluetoothTool.configuration.version
        
        // read serial number from device
        let serialNumber = try device.send(SerialNumber.Query()).serialNumber
        let protocolID = try device.send(ProtocolID.Query()).protocolID
        
        let information = try await InformationService(
            peripheral: peripheral,
            id: id,
            name: name,
            accessoryType: accessoryType,
            manufacturer: manufacturer,
            model: model,
            serialNumber: serialNumber.rawValue,
            softwareVersion: softwareVersion,
            metadata: []
        )
        
        let authentication = try await AuthenticationService(
            peripheral: peripheral
        )
        
        let outlet = try await OutletService(
            peripheral: peripheral
        )
        
        self.id = id
        self.rssi = rssi
        self.model = model
        self.name = name
        self.manufacturer = manufacturer
        self.accessoryType = accessoryType
        self.advertisedService = advertisedService
        self.softwareVersion = softwareVersion
        self.serialNumber = serialNumber
        self.protocolID = protocolID
        self.setupSharedSecret = setupSharedSecret
        self.server = try await BluetoothAccessoryServer(
            peripheral: peripheral,
            delegate: self,
            id: id,
            rssi: rssi,
            name: name,
            advertised: advertisedService,
            services: [
                information,
                authentication,
                outlet
            ]
        )
        
        // add GATT device information
        #if os(Linux)
        try await addStandardDeviceInformation()
        #endif
    }
    
    private func addStandardDeviceInformation() async throws {
        
        let gattInformation = GATTAttribute.Service(
            uuid: .deviceInformation,
            characteristics: [
                GATTAttribute.Characteristic(
                    uuid: GATTManufacturerNameString.uuid,
                    value: GATTManufacturerNameString(rawValue: manufacturer).data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute.Characteristic(
                    uuid: GATTModelNumber.uuid,
                    value: GATTModelNumber(rawValue: model).data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute.Characteristic(
                    uuid: GATTSoftwareRevisionString.uuid,
                    value: GATTSoftwareRevisionString(rawValue: softwareVersion).data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute.Characteristic(
                    uuid: GATTSerialNumberString.uuid,
                    value: GATTSerialNumberString(rawValue: serialNumber.rawValue).data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
            ]
        )
        
        _ = try await self.server.peripheral.add(service: gattInformation)
    }
    
    public nonisolated func log(_ message: String) {
        print("Accessory:", message)
    }
    
    public nonisolated func didAdvertise(beacon: BluetoothAccessory.AccessoryBeacon) {
        
    }
    
    public func key(for id: UUID) -> KeyData? {
        self.keySecrets[id]
    }
    
    public func willRead(_ handle: UInt16, authentication authenticationMessage: AuthenticationMessage?) async -> Bool {
        return true
    }
    
    public func didWrite(_ handle: UInt16, authentication authenticationMessage: AuthenticationMessage?) async {
        
        switch handle {
        case await information.$identify.handle:
            if await information.identify {
                guard let authenticationMessage = authenticationMessage,
                      let key = self.keys[authenticationMessage.id] else {
                    assertionFailure()
                    return
                }
                log("Did identify with key \(key.name)")
                lastIdentify = (key.id, Date())
                // clear value
                await self.server.update(InformationService.self) {
                    $0.identify = false
                }
            }
        case await outlet.$powerState.handle:
            guard let authenticationMessage = authenticationMessage,
                  let key = self.keys[authenticationMessage.id] else {
                assertionFailure()
                return
            }
            let powerState = await self.outlet.powerState
            log("Did turn \(powerState ? "on" : "off") with key \(key.name)")
            
        case await authentication.$setup.handle:
            //assert(await authentication.$setup.value == characteristicValue)
            guard let request = await authentication.setup else {
                assertionFailure()
                return
            }
            // create new key
            let ownerKey = Key(setup: request)
            self.keys[ownerKey.id] = ownerKey
            self.keySecrets[ownerKey.id] = request.secret
            log("Setup owner key for \(ownerKey.name)")
            // clear value
            await self.server.update(AuthenticationService.self) {
                $0.setup = nil
                $0.keys = [.key(ownerKey)]
            }
        
        case await authentication.$createKey.handle:
            guard let request = await authentication.createKey else {
                assertionFailure()
                return
            }
            // create a new key
            let newKey = NewKey(request: request)
            let secret = request.secret
            self.newKeys[newKey.id] = newKey
            self.keySecrets[newKey.id] = secret
            // update db
            await self.server.update(AuthenticationService.self) {
                $0.createKey = nil
                $0.keys.append(.newKey(newKey))
            }
        case await authentication.$confirmKey.handle:
            guard let request = await authentication.confirmKey,
                  let authenticationMessage = authenticationMessage,
                  let newKey = self.newKeys[authenticationMessage.id] else {
                assertionFailure()
                return
            }
            // confirm key
            let key = newKey.confirm()
            self.newKeys[authenticationMessage.id] = nil
            self.keySecrets[authenticationMessage.id] = request.secret
            self.keys[newKey.id] = key
            // update db
            await self.server.update(AuthenticationService.self) {
                $0.createKey = nil
                $0.keys.removeAll(where: { $0.id == newKey.id })
                $0.keys.append(.key(key))
            }
        default:
            break
        }
    }
    
    public func updateCryptoHash() async {
        await self.server.update(AuthenticationService.self) {
            $0.cryptoHash = Nonce()
        }
    }
}
