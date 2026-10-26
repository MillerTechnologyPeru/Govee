//
//  ThermometerAdvertisement.swift
//  
//
//  Created by Alsey Coleman Miller on 3/15/23.
//

import Foundation
import Bluetooth
import GATT

public extension GoveeAccessory {
    
    struct Thermometer: Equatable, Hashable, Sendable, GoveeAccessoryProtocol {
        
        public static var type: GoveeAccessoryType { .thermometer }
        
        public static var services: Set<BluetoothUUID> { [.govee] }
                
        public let id: GoveeAdvertisementName
        
        internal let manufacturerData: ManufacturerData
        
        public var temperature: Float {
            manufacturerData.temperature
        }
        
        public var humidity: Float {
            manufacturerData.humidity
        }
        
        public var batteryLevel: UInt8 {
            manufacturerData.batteryLevel
        }
    }
}

public extension GoveeAccessory.Thermometer {
    
    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        guard let name = advertisementData.localName,
              let serviceUUIDs = advertisementData.serviceUUIDs,
              let manufacturerData = advertisementData.manufacturerData else {
            return nil
        }
        self.init(name: name, services: Set(serviceUUIDs), manufacturerData: manufacturerData)
    }
    
    init?<T: DataContainer>(
        name: String,
        services serviceUUIDs: Set<BluetoothUUID>,
        manufacturerData: GATT.ManufacturerSpecificData<T>
    ) {
        guard let name = GoveeAdvertisementName(rawValue: name),
              let manufacturerData = ManufacturerData(manufacturerData),
              serviceUUIDs.contains(where: { Self.services.contains($0) }) else {
            return nil
        }
        self.init(name: name, manufacturerData: manufacturerData)
    }
    
    internal init?(
        name: GoveeAdvertisementName,
        manufacturerData: ManufacturerData
    ) {
        guard name.model.type == Self.type else {
            return nil
        }
        self.id = name
        self.manufacturerData = manufacturerData
    }
}

internal extension GoveeAccessory.Thermometer {
    
    struct ManufacturerData: Equatable, Hashable, Sendable {
        
        public static var companyIdentifier: CompanyIdentifier { .govee }
        
        internal static var length: Int { 6 }
        
        internal let reserved0: UInt8
        
        internal let encodedTemperature: EncodedTemperature
        
        public var temperature: Float {
            encodedTemperature.temperature
        }
        
        public var humidity: Float {
            encodedTemperature.humidity
        }
        
        public let batteryLevel: UInt8
        
        internal let reserved1: UInt8
    }
}

internal extension GoveeAccessory.Thermometer.ManufacturerData {
    
    init?<T: DataContainer>(_ manufacturerSpecificData: GATT.ManufacturerSpecificData<T>) {
        guard manufacturerSpecificData.companyIdentifier == Self.companyIdentifier,
              manufacturerSpecificData.additionalData.count >= Self.length
            else {
            return nil
        }
        let data = manufacturerSpecificData.additionalData
        let batteryLevel = data[4]
        guard batteryLevel <= 100 else {
            return nil
        }
        self.reserved0 = data[0]
        self.encodedTemperature = .init(byteValue: (data[1], data[2], data[3]))
        self.batteryLevel = batteryLevel
        self.reserved1 = data[5]
    }
}

internal extension GoveeAccessory.Thermometer.ManufacturerData {
    
    struct EncodedTemperature: Sendable {
        
        internal let byteValue: (UInt8, UInt8, UInt8)
        
        internal init(byteValue: (UInt8, UInt8, UInt8)) {
            self.byteValue = byteValue
        }
    }
}

internal extension GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature {
    
    var temperature: Float {
        Float(rawValue) / 10000
    }
    
    var humidity: Float {
        Float(rawValue % 1000) / 10
    }
}

extension GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature: Codable { }

extension GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature: RawRepresentable {
    
    public init?(rawValue: UInt32) {
        guard rawValue.bigEndian.bytes.0 == 0x00 else {
            return nil
        }
        self.init(rawValue)
        assert(rawValue == self.rawValue)
    }
    
    internal init(_ raw: UInt32) {
        let bytes = raw.bigEndian.bytes
        self.init(byteValue: (bytes.1, bytes.2, bytes.3))
    }
    
    public var rawValue: UInt32 {
        UInt32(bigEndian: UInt32(bytes: (0x00, byteValue.0, byteValue.1, byteValue.2)))
    }
}

extension GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt32) {
        self.init(value)
        assert(value == self.rawValue)
    }
}

extension GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature: CustomStringConvertible {
    
    public var description: String {
        return rawValue.description
    }
}

extension GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature: Equatable {
    
    public static func == (lhs: GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature, rhs: GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature) -> Bool {
        return lhs.byteValue.0 == rhs.byteValue.0
            && lhs.byteValue.1 == rhs.byteValue.1
            && lhs.byteValue.2 == rhs.byteValue.2
    }
}

extension GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        withUnsafePointer(to: byteValue) {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: UnsafeRawPointer($0), count: 3))
        }
    }
}
