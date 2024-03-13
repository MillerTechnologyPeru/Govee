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
        
        public let manufacturingData: ManufacturingData
        
        public let name: GoveeAdvertisementName
        
        public var model: GoveeModel {
            name.model
        }
        
        public var id: String {
            name.rawValue
        }
    }
}

public extension GoveeAccessory.Thermometer {
    
    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        guard let manufacturingData = advertisementData.manufacturerData.flatMap({ ManufacturingData($0) }),
              let rawName = advertisementData.localName,
              let name = GoveeAdvertisementName(rawValue: rawName),
              let serviceUUIDs = advertisementData.serviceUUIDs,
              serviceUUIDs.contains(where: { Self.services.contains($0) }) else {
            return nil
        }
        self.manufacturingData = manufacturingData
        self.name = name
    }
}

public extension GoveeAccessory.Thermometer {
    
    struct ManufacturingData: Equatable, Hashable, Sendable {
        
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

public extension GoveeAccessory.Thermometer.ManufacturingData {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
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

public extension GoveeAccessory.Thermometer.ManufacturingData {
    
    struct EncodedTemperature: Sendable {
        
        internal let byteValue: (UInt8, UInt8, UInt8)
        
        internal init(byteValue: (UInt8, UInt8, UInt8)) {
            self.byteValue = byteValue
        }
    }
}

public extension GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature {
    
    var temperature: Float {
        Float(rawValue) / 10000
    }
    
    var humidity: Float {
        Float(rawValue % 1000) / 10
    }
}

extension GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature: Codable { }

extension GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature: RawRepresentable {
    
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

extension GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt32) {
        self.init(value)
        assert(value == self.rawValue)
    }
}

extension GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature: CustomStringConvertible {
    
    public var description: String {
        return rawValue.description
    }
}

extension GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature: Equatable {
    
    public static func == (lhs: GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature, rhs: GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature) -> Bool {
        return lhs.byteValue.0 == rhs.byteValue.0
            && lhs.byteValue.1 == rhs.byteValue.1
            && lhs.byteValue.2 == rhs.byteValue.2
    }
}

extension GoveeAccessory.Thermometer.ManufacturingData.EncodedTemperature: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        withUnsafePointer(to: byteValue) {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: UnsafeRawPointer($0), count: 3))
        }
    }
}
