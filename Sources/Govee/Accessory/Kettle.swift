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
    
    struct Kettle: Equatable, Hashable, Sendable, Codable, GoveeAccessoryProtocol {
        
        public static var type: GoveeAccessoryType { .kettle }
                
        public let id: GoveeAdvertisementName
        
        public let isActive: Bool
        
        public let state: KettleHeatingState?
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
    
    init?(
        name: String,
        manufacturerData: GATT.ManufacturerSpecificData
    ) {
        guard let name = GoveeAdvertisementName(rawValue: name),
              let manufacturerData = GoveeManufacturerData(manufacturerData) else {
            return nil
        }
        self.init(name: name, manufacturerData: manufacturerData)
    }
    
    internal init?(name: GoveeAdvertisementName, manufacturerData: GoveeManufacturerData) {
        guard name.model.type == Self.type else {
            return nil
        }
        switch manufacturerData {
        case .thermometer:
            return nil
        case .v2(let manufacturerData):
            self.isActive = manufacturerData.isActive
            self.state = nil
        case .v3(let manufacturerData):
            guard let state = KettleHeatingState(rawValue: manufacturerData.state) else {
                return nil
            }
            self.isActive = manufacturerData.isActive
            self.state = state
        }
        self.id = name
    }
}


// MARK: - Supporting Types

public enum KettleHeatingState: UInt8, Codable, Sendable, CaseIterable {
    
    case idle = 0x00
    
    case heating = 0x01
    
    case keepingWarm = 0x02
    
    case finishedBoiling = 0x04
}
