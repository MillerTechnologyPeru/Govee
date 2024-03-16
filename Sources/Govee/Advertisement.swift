//
//  Advertisement.swift
//
//
//  Created by Alsey Coleman Miller on 3/15/24.
//

import Foundation
import Bluetooth
import GATT

/// Govee Advertisement
public struct GoveeAdvertisement: Equatable, Hashable, Sendable {
    
    public let name: GoveeAdvertisementName
    
    internal let manufacturerData: GoveeManufacturerData
    
    internal init(
        name: GoveeAdvertisementName,
        manufacturerData: GoveeManufacturerData
    ) {
        self.name = name
        self.manufacturerData = manufacturerData
    }
}

// MARK: - Identifiable

extension GoveeAdvertisement: Identifiable {
    
    public var id: String { name.rawValue }
}

// MARK: - GATT

public extension GoveeAdvertisement {
    
    init?<T: GATT.AdvertisementData>(_ advertisement: T) {
        guard let localName = advertisement.localName,
              let manufacturerData = advertisement.manufacturerData else {
            return nil
        }
        self.init(name: localName, manufacturerData: manufacturerData)
    }
    
    init?(name localName: String, manufacturerData: GATT.ManufacturerSpecificData) {
        guard let name = GoveeAdvertisementName(rawValue: localName),
              let manufacturerDataValue = GoveeManufacturerData(manufacturerData) else {
            return nil
        }
        self.init(name: name, manufacturerData: manufacturerDataValue)
    }
}
