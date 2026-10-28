import Foundation
import Bluetooth
import GATT

/// Govee Accessory
public enum GoveeAccessory: Equatable, Hashable, Sendable {
    
    case thermometer(Thermometer)
    case heater(Heater)
    case kettle(Kettle)
    case riceCooker(RiceCooker)
}

// MARK: - Identifiable

extension GoveeAccessory: Identifiable {
    
    public var id: GoveeAdvertisementName {
        switch self {
        case .thermometer(let value):
            return value.id
        case .heater(let value):
            return value.id
        case .kettle(let value):
            return value.id
        case .riceCooker(let value):
            return value.id
        }
    }
    
    public var type: GoveeAccessoryType {
        id.model.type
    }
    
    public var model: GoveeModel {
        id.model
    }
}

// MARK: - AdvertisementData

public extension GoveeAccessory {
    
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
        guard let name = GoveeAdvertisementName(rawValue: name) else {
            return nil
        }
        
        switch name.model.type {
        case .thermometer:
            guard let manufacturerData = GoveeAccessory.Thermometer.ManufacturerData(manufacturerData),
                let value = GoveeAccessory.Thermometer(name: name, manufacturerData: manufacturerData) else {
                return nil
            }
            self = .thermometer(value)
        case .heater:
            guard let manufacturerData = GoveeAccessory.Heater.ManufacturerData(manufacturerData),
                let value = GoveeAccessory.Heater(name: name, manufacturerData: manufacturerData) else {
                return nil
            }
            self = .heater(value)
        case .kettle:
            guard let manufacturerData = GoveeAccessory.Kettle.ManufacturerData(manufacturerData),
                let value = GoveeAccessory.Kettle(name: name, manufacturerData: manufacturerData) else {
                return nil
            }
            self = .kettle(value)
        case .riceCooker:
            guard let manufacturerData = GoveeAccessory.RiceCooker.ManufacturerData(manufacturerData),
                let value = GoveeAccessory.RiceCooker(name: name, manufacturerData: manufacturerData) else {
                return nil
            }
            self = .riceCooker(value)
        case .iceMaker,
            .lighting,
            .smartPlug,
            .oilDiffuser:
            // Not implemented
            return nil
        }
    }
}

// MARK: - Supporting Types

public protocol GoveeAccessoryProtocol: Identifiable {
    
    /// Accessory Category
    static var type: GoveeAccessoryType { get }
    
    var id: GoveeAdvertisementName { get }
}
