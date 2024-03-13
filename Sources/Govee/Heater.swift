//
//  Heater.swift
//
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

import Foundation
import Bluetooth
import GATT

public extension GoveeAccessory {
    
    struct Heater: Equatable, Hashable, Sendable, GoveeAccessoryProtocol {
        
        public static var type: GoveeAccessoryType { .heater }
        
        public let manufacturerData: ManufacturerData
        
        public let name: GoveeAdvertisementName
        
        public var model: GoveeModel {
            name.model
        }
        
        public var id: String {
            name.rawValue
        }
    }
}

public extension GoveeAccessory.Heater {
    
    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        guard let manufacturerData = advertisementData.manufacturerData.flatMap({ ManufacturerData($0) }),
              let rawName = advertisementData.localName,
              let name = GoveeAdvertisementName(rawValue: rawName) else {
            return nil
        }
        self.manufacturerData = manufacturerData
        self.name = name
    }
}

public extension GoveeAccessory.Heater {
    
    struct ManufacturerData: Equatable, Hashable, Sendable {
        
        internal static var companyIdentifier: CompanyIdentifier { .goveeHeater }
                
        internal static var length: Int { 6 }
        
        internal let reserved0: UInt8
        internal let reserved1: UInt8
        internal let reserved2: UInt8
        public let isActive: Bool
        internal let reserved4: UInt8
    }
}

public extension GoveeAccessory.Heater.ManufacturerData {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
        let data = manufacturerSpecificData.additionalData
        guard manufacturerSpecificData.companyIdentifier == Self.companyIdentifier,
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
