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

public extension GoveeAccessory.Kettle {
    
    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        guard let manufacturingData = advertisementData.manufacturerData.flatMap({ ManufacturingData($0) }),
              let rawName = advertisementData.localName,
              let name = GoveeAdvertisementName(rawValue: rawName) else {
            return nil
        }
        self.manufacturingData = manufacturingData
        self.name = name
    }
}

public extension GoveeAccessory.Kettle {
    
    struct ManufacturingData: Equatable, Hashable, Sendable {
                
        internal static var length: Int { 11 }
        
        //internal let reserved0: UInt8
        
        //internal let reserved1: UInt8
    }
}

public extension GoveeAccessory.Kettle.ManufacturingData {
    
    init?(_ manufacturerSpecificData: GATT.ManufacturerSpecificData) {
        guard manufacturerSpecificData.additionalData.count >= Self.length
            else {
            return nil
        }
        let data = manufacturerSpecificData.additionalData
    }
}
