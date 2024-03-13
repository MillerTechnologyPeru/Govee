import Foundation
import Bluetooth
import GATT

/// Govee Accessory
public enum GoveeAccessory: Equatable, Hashable, Sendable {
    
    case thermometer(Thermometer)
    case heater(Heater)
    case kettle(Kettle)
}

public extension GoveeAccessory {
    
    var model: GoveeModel {
        switch self {
        case .thermometer(let value):
            return value.model
        case .heater(let value):
            return value.model
        case .kettle(let value):
            return value.model
        }
    }
    
    var type: GoveeAccessoryType {
        switch self {
        case .thermometer:
            return .thermometer
        case .heater:
            return .heater
        case .kettle:
            return .kettle
        }
    }
}

// MARK: - Identifiable

extension GoveeAccessory: Identifiable {
    
    public var id: String {
        switch self {
        case .thermometer(let value):
            return value.id
        case .heater(let value):
            return value.id
        case .kettle(let value):
            return value.id
        }
    }
}

// MARK: - AdvertisementData

public extension GoveeAccessory {
    
    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        if let thermometer = Thermometer(advertisementData) {
            self = .thermometer(thermometer)
        } else if let heater = Heater(advertisementData) {
            self = .heater(heater)
        } else if let kettle = Kettle(advertisementData) {
            self = .kettle(kettle)
        } else {
            return nil
        }
    }
}

// MARK: - Supporting Types

public protocol GoveeAccessoryProtocol: Identifiable {
    
    /// Accessory Category
    static var type: GoveeAccessoryType { get }
    
    /// Accessory Model
    var model: GoveeModel { get }
    
    /// Unique identifier
    ///
    /// Typically the local name which is the model and the last 2 bytes of the Bluetooth MAC address.
    var id: String { get }
}

/// Govee Accessory Category
public enum GoveeAccessoryType: Equatable, Hashable, Sendable {
    
    case thermometer
    case heater
    case kettle
    case riceCooker
}
