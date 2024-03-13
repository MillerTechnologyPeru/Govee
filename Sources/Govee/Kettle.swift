//
//  KettleAdvertisement.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

import Foundation
import Bluetooth
import GATT

public extension GoveeAccessory {
    
    struct Kettle: Equatable, Hashable, Sendable, GoveeAccessoryProtocol {
        
        public static var type: GoveeAccessoryType { .kettle }
        
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

public extension GoveeAccessory.Kettle {
    
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

public extension GoveeAccessory.Kettle {
    
    struct ManufacturerData: Equatable, Hashable, Sendable {
        
        internal static var companyIdentifier: CompanyIdentifier { .goveeKettle }
                
        internal static var length: Int { 11 }
        
        internal let reserved0: UInt8
        internal let reserved1: UInt8
        internal let reserved2: UInt8
        internal let reserved3: UInt8
        internal let reserved4: UInt8
        internal let reserved5: UInt8
        internal let reserved6: UInt8
        internal let reserved7: UInt8
        internal let reserved8: UInt8
        internal let reserved9: UInt8
    }
}

public extension GoveeAccessory.Kettle.ManufacturerData {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
        guard manufacturerSpecificData.additionalData.count == Self.length,
            manufacturerSpecificData.companyIdentifier == Self.companyIdentifier,
            manufacturerSpecificData.additionalData.first == 0xEC else {
            return nil
        }
        let data = manufacturerSpecificData.additionalData
        self.reserved0 = data[1]
        self.reserved1 = data[2]
        self.reserved2 = data[3]
        self.reserved3 = data[4]
        self.reserved4 = data[5]
        self.reserved5 = data[6]
        self.reserved6 = data[7]
        self.reserved7 = data[8]
        self.reserved8 = data[9]
        self.reserved9 = data[10]
    }
}
