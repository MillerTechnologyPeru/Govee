//
//  AccessoryType.swift
//  
//
//  Created by Alsey Coleman Miller on 3/15/24.
//

/// Govee Accessory Category
public enum GoveeAccessoryType: Equatable, Hashable, Sendable {
    
    case thermometer
    case heater
    case oilDiffuser
    case kettle
    case riceCooker
    case iceMaker
    case lighting
    case smartPlug
    case airPurifier
}

public extension GoveeModel {
    
    var type: GoveeAccessoryType {
        switch self {
        case .h5072:
            return .thermometer
        case .h5074:
            return .thermometer
        case .h5075:
            return .thermometer
        case .h5086:
            return .smartPlug
        case .h5101:
            return .thermometer
        case .h5102:
            return .thermometer
        case .h5177:
            return .thermometer
        case .h5178:
            return .thermometer
        case .h5179:
            return .thermometer
        case .h5182:
            return .thermometer
        case .h5183:
            return .thermometer
        case .h5184:
            return .thermometer
        case .h5185:
            return .thermometer
        case .h5198:
            return .thermometer
        case .h712C:
            return .airPurifier
        case .h7130:
            return .heater
        case .h7131:
            return .heater
        case .h7135:
            return .heater
        case .h7161:
            return .oilDiffuser
        case .h7162:
            return .oilDiffuser
        case .h7170:
            return .kettle
        case .h7171:
            return .kettle
        case .h7172:
            return .iceMaker
        case .h7173:
            return .kettle
        case .h7175:
            return .kettle
        case .h7180:
            return .riceCooker
        }
    }
}
