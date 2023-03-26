//
//  MPPSolarBluetoothTool.swift
//  
//
//  Created by Alsey Coleman Miller on 3/26/23.
//

#if os(Linux)
import Glibc
import BluetoothLinux
#elseif os(macOS)
import Darwin
import DarwinGATT
#endif

import Foundation
import CoreFoundation
import Dispatch
import ArgumentParser
import Bluetooth
import GATT
import BluetoothAccessory
import MPPSolar
import MPPSolarBluetooth

#if os(Linux)
typealias LinuxCentral = GATTCentral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias LinuxPeripheral = GATTPeripheral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias NativeCentral = LinuxCentral
typealias NativePeripheral = LinuxPeripheral
#elseif os(macOS)
typealias NativeCentral = DarwinCentral
typealias NativePeripheral = DarwinPeripheral
#else
#error("Unsupported platform")
#endif

@main
struct MPPSolarBluetoothTool: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "A deamon for controlling an MPP Solar device via Bluetooth LE.",
        version: "1.0.0"
    )
    
    @Option(help: "The path to the solar device.")
    var device: String = "/dev/hidraw0"
    
    @Option(help: "The path to the configuration.")
    var configuration: String = "configuration.json"
    
    @Option(help: "The interval (in seconds) at which data is refreshed.")
    var refreshInterval: Int = 10
    
    private static var server: MPPSolarBluetoothServer<NativePeripheral>!
    
    private static let fileManager = FileManager()
    
    func validate() throws {
        guard refreshInterval >= 1 else {
            throw ValidationError("<refresh-interval> must be at least 1 second.")
        }
    }
    
    func run() throws {
        
        // read configuration first
        let configuration = try loadConfiguration()
        
        #if DEBUG
        printConfiguration(configuration)
        #endif
        
        // start async code
        Task {
            do {
                try await start(with: configuration)
            }
            catch {
                fatalError("\(error)")
            }
        }
        
        // run main loop
        RunLoop.current.run()
    }
    
    private func start(with configuration: MPPSolarConfiguration) async throws {
        
        // load solar device
        let device = try await loadSolarDevice()
        // load Bluetooth
        let peripheral = try await loadBluetooth()
        
        // publish GATT server, enable advertising
        Self.server = try await MPPSolarBluetoothServer(
            peripheral: peripheral,
            device: device,
            id: configuration.id,
            rssi: configuration.rssi,
            model: configuration.model,
            softwareVersion: MPPSolarBluetoothTool.configuration.version,
            setupSharedSecret: configuration.setupSecret
        )
    }
    
    static func url(for path: String) -> URL {
        let url: URL
        if path.contains("/") {
            url = URL(fileURLWithPath: path)
        } else {
            let currentDirectory = FileManager.default.currentDirectoryPath
            url = URL(fileURLWithPath: currentDirectory).appendingPathComponent(path)
        }
        return url
    }
    
    func loadConfiguration() throws -> MPPSolarConfiguration {
        
        let fileURL = Self.url(for: self.configuration)
        if Self.fileManager.fileExists(atPath: fileURL.path) {
            let configuration = try MPPSolarConfiguration(url: fileURL)
            #if DEBUG
            print("Loaded configuration at \(fileURL.path)")
            #endif
            return configuration
        } else {
            let configuration = MPPSolarConfiguration()
            let data = try configuration.encode()
            let didCreate = Self.fileManager.createFile(atPath: fileURL.path, contents: data)
            precondition(didCreate)
            #if DEBUG
            print("Created configuration at \(fileURL.path)")
            #endif
            return configuration
        }
    }
    
    func printConfiguration(_ configuration: MPPSolarConfiguration) {
        print("ID: \(configuration.id)")
        print("Model: \(configuration.model)")
        print("RSSI: \(configuration.rssi)")
        
    }
    
    func loadSolarDevice() async throws -> MPPSolar {
        
        #if os(macOS) && DEBUG
        let device = MPPSolar.mock
        print("Using mocked solar device")
        #else
        guard let device = MPPSolar(path: self.device) else {
            throw CommandError.solarDeviceUnavailable
        }
        print("Loaded solar device at \(self.device)")
        #endif
        
        return device
    }
    
    func loadBluetooth() async throws -> NativePeripheral {
        
        // TODO: Specify HCI device
        
        #if os(Linux)
        guard let hostController = await HostController.default else {
            throw CommandError.bluetoothUnavailable
        }
        let address = try await hostController.readDeviceAddress()
        print("Bluetooth Controller: \(address)")
        let serverOptions = GATTPeripheralOptions(
            maximumTransmissionUnit: .max,
            maximumPreparedWrites: 1000
        )
        let peripheral = LinuxPeripheral(
            hostController: hostController,
            options: serverOptions,
            socket: BluetoothLinux.L2CAPSocket.self
        )
        #elseif os(macOS)
        let peripheral = DarwinPeripheral()
        #endif
        
        peripheral.log = { print("Peripheral:", $0) }
        
        #if os(macOS)
        // wait till power on
        try await peripheral.waitPowerOn()
        #endif
        
        return peripheral
    }
}

