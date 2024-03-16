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
                
        public let id: GoveeAdvertisementName
        
        public let isActive: Bool
    }
}

public extension GoveeAccessory.Heater {
    
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
    
    internal init?(
        name: GoveeAdvertisementName,
        manufacturerData: GoveeManufacturerData
    ) {
        guard name.model.type == Self.type else {
            return nil
        }
        switch manufacturerData {
        case .thermometer:
            return nil
        case .v2(let manufacturerData):
            self.isActive = manufacturerData.isActive
        case .v3(let manufacturerData):
            self.isActive = manufacturerData.isActive
        }
        self.id = name
    }
}
