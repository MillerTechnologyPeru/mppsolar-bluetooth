//
//  Server.swift
//  
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

#if canImport(BluetoothGATT)
import Foundation
import Bluetooth
import BluetoothGATT
import GATT
import BluetoothAccessory
import MPPSolar

public actor MPPSolarBluetoothServer <Peripheral: AccessoryPeripheralManager, Authentication: MPPSolarAuthenticationDelegate> {
    
    // MARK: - Properties
    
    public let id: UUID
    
    public let rssi: Int8
    
    public let model: String
    
    public let name: String
    
    public let manufacturer: String
    
    public let accessoryType: AccessoryType
    
    public let advertisedService: ServiceType
    
    public let softwareVersion: String
    
    public let serialNumber: SerialNumber // loaded from solar device
    
    public let protocolID: ProtocolID
            
    private var server: BluetoothAccessoryServer<Peripheral>!
    
    public let device: MPPSolar
    
    public let refreshInterval: TimeInterval
    
    internal let authenticationDelegate: Authentication
    
    var lastIdentify: (UUID, Date)?
    
    public init(
        peripheral: Peripheral,
        device: MPPSolar,
        id: UUID,
        rssi: Int8,
        model: String,
        softwareVersion: String,
        refreshInterval: TimeInterval,
        authentication authenticationDelegate: Authentication
    ) async throws {
        
        assert(refreshInterval > 1)
        let name = "MPPSolar"
        let manufacturer = "MPP Solar Inc."
        let accessoryType = AccessoryType.solarPanel
        let advertisedService = ServiceType.solarPanel
        
        // read serial number from device
        let serialNumber = try device.send(SerialNumber.Query()).serialNumber
        let protocolID = try device.send(ProtocolID.Query()).protocolID
        //let firmwareVersion = try device.send(FirmwareVersion.Query()).version
        //let firmwareVersion2 = try device.send(FirmwareVersion.Query.Secondary()).version
        
        let information = try await MPPSolarInformationService(
            peripheral: peripheral,
            id: id,
            name: name,
            accessoryType: accessoryType,
            manufacturer: manufacturer,
            model: model,
            serialNumber: serialNumber.rawValue,
            softwareVersion: softwareVersion,
            metadata: [],
            protocolID: protocolID
        )
        
        // services
        let authentication = try await AuthenticationService(peripheral: peripheral)
        let battery = try await MPPSolarBatteryService(peripheral: peripheral)
        let outlet = try await OutletService(peripheral: peripheral)
        
        // service delegate
        self.authenticationDelegate = authenticationDelegate
        
        // store properties
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
        self.device = device
        self.refreshInterval = refreshInterval
        
        // accessory server
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
                battery,
                outlet,
            ]
        )
        
        // add GATT device information
        #if os(Linux)
        try await addStandardDeviceInformation()
        #endif
        
        // read data from device
        try await refresh()
        
        // reload periodically
        Task { [weak self] in
            while let self = self {
                try await Task.sleep(timeInterval: self.refreshInterval)
                do {
                    try await self.refresh()
                }
                catch {
                    self.log("Unable to reload data: \(error)")
                }
            }
        }
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
    
    public func refresh() async throws {
        
        let status = try device.send(GeneralStatus.Query())
        
        // update battery service
        await server.update(MPPSolarBatteryService.self) {
            $0.batteryLevel = UInt8(status.batteryCapacity)
            $0.batteryVoltage = status.batteryVoltage
            $0.batteryChargingCurrent = UInt8(status.batteryChargingCurrent)
            $0.statusLowBattery = status.statusLowBattery
            $0.chargingState = status.chargingState
        }
        
        await server.update(OutletService.self) {
            $0.powerState = status.outputVoltage > 0
            //$0.outletInUse = status.outputActivePower > 0
        }
        
        //let mode = try device.send(DeviceMode.Query())
        //let warning = try device.send(WarningStatus.Query())
        //let flags = try device.send(FlagStatus.Query())
        //let rating = try device.send(DeviceRating.Query())
    }
}

// MARK: - BluetoothAccessoryServerDelegate

extension MPPSolarBluetoothServer: BluetoothAccessoryServerDelegate {
       
    public var cryptoHash: Nonce {
        get async {
            await self.authentication.cryptoHash
        }
    }
    
    public nonisolated func log(_ message: String) {
        print("Accessory:", message)
    }
    
    public nonisolated func didAdvertise(beacon: BluetoothAccessory.AccessoryBeacon) { }
    
    public func key(for id: UUID) async -> KeyData? {
        await self.authenticationDelegate.secret(for: id)
    }
    
    public func willRead(_ handle: UInt16, authentication authenticationMessage: AuthenticationMessage?) async -> Bool {
        return true
    }
    
    public func willWrite(_ handle: UInt16, authentication: BluetoothAccessory.AuthenticationMessage?) async -> Bool {
        return true
    }
    
    public func didWrite(_ handle: UInt16, authentication authenticationMessage: AuthenticationMessage?) async {
        
        switch handle {
        case await information.$identify.handle:
            if await information.identify {
                guard let authenticationMessage = authenticationMessage,
                      let key = await authenticationDelegate.key(for: authenticationMessage.id) else {
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
                  let key = await authenticationDelegate.key(for: authenticationMessage.id) else {
                assertionFailure()
                return
            }
            let powerState = await self.outlet.powerState
            log("Did turn \(powerState ? "on" : "off") with key \(key.name)")
            
        case await authentication.$setup.handle:
            //assert(await authentication.$setup.value == characteristicValue)
            guard let authenticationMessage = authenticationMessage,
                  let request = await authentication.setup else {
                assertionFailure()
                return
            }
            // create new owner key
            guard await authenticationDelegate.setup(request, authenticationMessage: authenticationMessage) else {
                assertionFailure()
                return
            }
            log("Setup owner key for \(request.name)")
            // clear value
            let newKeysValue = await self.authenticationDelegate.allKeys
            await self.server.update(AuthenticationService.self) {
                $0.setup = nil
                $0.keys = newKeysValue
            }
        
        case await authentication.$createKey.handle:
            guard let request = await authentication.createKey,
                let authenticationMessage = authenticationMessage else {
                assertionFailure()
                return
            }
            // create a new key
            guard await authenticationDelegate.create(request, authenticationMessage: authenticationMessage) else {
                assertionFailure()
                return
            }
            // update db
            let newKeysValue = await self.authenticationDelegate.allKeys
            await self.server.update(AuthenticationService.self) {
                $0.createKey = nil
                $0.keys = newKeysValue
            }
        case await authentication.$confirmKey.handle:
            guard let request = await authentication.confirmKey,
                  let authenticationMessage = authenticationMessage else {
                assertionFailure()
                return
            }
            // confirm key
            guard await authenticationDelegate.confirm(request, authenticationMessage: authenticationMessage) else {
                assertionFailure()
                return
            }
            // update db
            let newKeysValue = await self.authenticationDelegate.allKeys
            await self.server.update(AuthenticationService.self) {
                $0.createKey = nil
                $0.keys = newKeysValue
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

internal extension MPPSolarBluetoothServer {
    
    nonisolated var authentication: AuthenticationService {
        get async {
            await server[AuthenticationService.self]
        }
    }
    
    nonisolated var information: MPPSolarInformationService {
        get async {
            await server[MPPSolarInformationService.self]
        }
    }
    
    nonisolated var outlet: OutletService {
        get async {
            await server[OutletService.self]
        }
    }
        
    nonisolated var battery: MPPSolarBatteryService {
        get async {
            await server[MPPSolarBatteryService.self]
        }
    }
}

#endif
