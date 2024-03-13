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
        
        public static var companyIdentifier: CompanyIdentifier { .goveeKettle }
                
        internal static var length: Int { 11 }
        
        //internal let reserved0: UInt8
        
        //internal let reserved1: UInt8
    }
}

public extension GoveeAccessory.Kettle.ManufacturerData {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
        guard manufacturerSpecificData.additionalData.count >= Self.length,
            manufacturerSpecificData.companyIdentifier == Self.companyIdentifier
            else {
            return nil
        }
        let data = manufacturerSpecificData.additionalData
    }
}
