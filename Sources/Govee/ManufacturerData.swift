//
//  ManufacturerData.swift
//
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

import Foundation
import Bluetooth
import GATT

internal enum GoveeManufacturerData: Equatable, Hashable, Sendable {
    
    case thermometer(GoveeAccessory.Thermometer.ManufacturerData)
    case v2(GoveeManufacturerData.V2)
    case v3(GoveeManufacturerData.V3)
}

internal extension GoveeManufacturerData {
    
    enum CompanyIdentifier: UInt16, Sendable, Codable, CaseIterable {
        
        case thermometer    = 0xEC88
        case v2             = 0x8802
        case v3             = 0x8803
    }
}

extension GoveeManufacturerData {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
        guard let companyIdentifier = CompanyIdentifier(rawValue: manufacturerSpecificData.companyIdentifier.rawValue) else {
            return nil
        }
        switch companyIdentifier {
        case .thermometer:
            guard let value = GoveeAccessory.Thermometer.ManufacturerData(manufacturerSpecificData) else {
                return nil
            }
            self = .thermometer(value)
        case .v2:
            guard let value = GoveeManufacturerData.V2(manufacturerSpecificData) else {
                return nil
            }
            self = .v2(value)
        case .v3:
            guard let value = GoveeManufacturerData.V3(manufacturerSpecificData) else {
                return nil
            }
            self = .v3(value)
        }
    }
}

extension GoveeManufacturerData {

    struct V2: Equatable, Hashable, Sendable {
        
        internal static var companyIdentifier: CompanyIdentifier { .v2 }
        
        internal static var length: Int { 6 }
        
        internal let reserved0: UInt8
        
        internal let reserved1: UInt8
        
        internal let reserved2: UInt8
        
        public let isActive: Bool
        
        internal let reserved4: UInt8
    }
}

extension GoveeManufacturerData.V2 {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
        let data = manufacturerSpecificData.additionalData
        guard manufacturerSpecificData.companyIdentifier.rawValue == Self.companyIdentifier.rawValue,
              data.count == Self.length,
              data.first == 0xEC else {
            return nil
        }
        self.reserved0 = data[1]
        self.reserved1 = data[2]
        self.reserved2 = data[3]
        self.isActive = data[4] != 0x00
        self.reserved4 = data[5]
    }
}

extension GoveeManufacturerData {
    
    struct V3: Equatable, Hashable, Sendable {
        
        internal static var companyIdentifier: CompanyIdentifier { .v3 }
        
        internal static var length: Int { 11 }
        
        internal let reserved0: UInt8
        internal let reserved1: UInt8
        internal let reserved2: UInt8
        
        public let isActive: Bool
        
        internal let reserved4: UInt8
        
        public let state: UInt8
        
        internal let reserved6: UInt8
        internal let reserved7: UInt8
        internal let reserved8: UInt8
        internal let reserved9: UInt8
    }
}

extension GoveeManufacturerData.V3 {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
        let data = manufacturerSpecificData.additionalData
        guard manufacturerSpecificData.companyIdentifier.rawValue == Self.companyIdentifier.rawValue,
              data.count == Self.length,
              data.first == 0xEC else {
            return nil
        }
        self.reserved0 = data[1]
        self.reserved1 = data[2]
        self.reserved2 = data[3]
        self.isActive = data[4] != 0x00
        self.reserved4 = data[5]
        self.state = data[6]
        self.reserved6 = data[7]
        self.reserved7 = data[8]
        self.reserved8 = data[9]
        self.reserved9 = data[10]
    }
}
