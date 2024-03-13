//
//  ManufacturerData.swift
//
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

import Foundation
import Bluetooth
import GATT

internal enum GoveeManufacturerData {
    
    case thermometer(GoveeAccessory.Thermometer.ManufacturerData)
    case heater(GoveeAccessory.Heater.ManufacturerData)
    case kettle(GoveeAccessory.Kettle.ManufacturerData)
}

internal extension GoveeManufacturerData {
    
    enum CompanyIdentifier: UInt16, Sendable, Codable, CaseIterable {
        
        case thermometer = 0xEC88
        case heater = 0x8802
        case kettle = 0x8803
    }
}
