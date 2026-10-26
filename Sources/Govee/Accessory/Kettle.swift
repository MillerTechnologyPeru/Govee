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
                
        public let id: GoveeAdvertisementName
        
        internal let manufacturerData: ManufacturerData
        
        public var isActive: Bool {
            manufacturerData.isActive
        }
        
        public var state: KettleHeatingState {
            manufacturerData.state
        }
    }
}

public extension GoveeAccessory.Kettle {
    
    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        guard let manufacturerData = advertisementData.manufacturerData,
              let name = advertisementData.localName else {
            return nil
        }
        self.init(name: name, manufacturerData: manufacturerData)
    }
    
    init?<T: DataContainer>(
        name: String,
        manufacturerData: GATT.ManufacturerSpecificData<T>
    ) {
        guard let name = GoveeAdvertisementName(rawValue: name),
              let manufacturerData = ManufacturerData(manufacturerData) else {
            return nil
        }
        self.init(name: name, manufacturerData: manufacturerData)
    }
    
    internal init?(name: GoveeAdvertisementName, manufacturerData: ManufacturerData) {
        guard name.model.type == Self.type else {
            return nil
        }
        self.id = name
        self.manufacturerData = manufacturerData
    }
}

extension GoveeAccessory.Kettle {
    
    struct ManufacturerData: Equatable, Hashable, Sendable {
                
        internal static var length: Int { 11 }
        
        internal let companyIdentifier: GoveeCompanyIdentifier
        
        internal let reserved0: UInt8
        internal let reserved1: UInt8
        internal let reserved2: UInt8
        
        public let isActive: Bool
        
        internal let reserved4: UInt8
        
        public let state: KettleHeatingState
        
        internal let reserved6: UInt8
        internal let reserved7: UInt8
        internal let reserved8: UInt8
        internal let reserved9: UInt8
    }
}

internal extension GoveeAccessory.Kettle.ManufacturerData {
    
    init?<T: DataContainer>(_ manufacturerSpecificData: GATT.ManufacturerSpecificData<T>) {
        let data = manufacturerSpecificData.additionalData
        guard let companyIdentifier = GoveeCompanyIdentifier(rawValue: manufacturerSpecificData.companyIdentifier.rawValue),
              data.count == Self.length,
              data.first == 0xEC else {
            return nil
        }
        guard let state = KettleHeatingState(rawValue: data[6]) else {
            return nil
        }
        self.companyIdentifier = companyIdentifier
        self.reserved0 = data[1]
        self.reserved1 = data[2]
        self.reserved2 = data[3]
        self.isActive = data[4] != 0x00
        self.reserved4 = data[5]
        self.state = state
        self.reserved6 = data[7]
        self.reserved7 = data[8]
        self.reserved8 = data[9]
        self.reserved9 = data[10]
    }
}

// MARK: - Supporting Types

public enum KettleHeatingState: UInt8, Codable, Sendable, CaseIterable {
    
    case idle = 0x00
    
    case heating = 0x01
    
    case keepingWarm = 0x02
    
    case finishedBoiling = 0x04
}
