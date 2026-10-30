//
//  Model.swift
//  
//
//  Created by Alsey Coleman Miller on 3/16/23.
//

/// Govee Model
public enum GoveeModel: String, CaseIterable, Sendable {
    
    /// Govee Thermometer Hygrometer
    case h5072 = "H5072"
    
    case h5074 = "H5074"
    case h5075 = "H5075"
    
    /// Govee Smart Plug Pro with Energy Monitoring
    case h5086 = "H5086"
    
    case h5101 = "H5101"
    case h5102 = "H5102"
    case h5177 = "H5177"
    case h5178 = "H5178"
    case h5179 = "H5179"
    case h5182 = "H5182"
    case h5183 = "H5183"
    case h5184 = "H5184"
    case h5185 = "H5185"
    case h5198 = "H5198"
    
    /// Govee Smart Air Purifier
    case h712C = "H712C"

    /// Govee Smart Space Heater
    case h7130 = "H7130"
    
    /// Govee Smart Space Heater
    case h7131 = "H7131"
    
    /// Govee Smart Space Heater Lite
    case h7135 = "H7135"
    
    /// Govee Smart Essential Oil Diffuser (with white noise)
    case h7161 = "H7161"
    
    /// Govee Smart Essential Oil Diffuser (without white noise)
    case h7162 = "H7162"
    
    /// Govee Smart Gooseneck Kettle
    case h7170 = "H7170"
    
    /// Govee Smart Electric Kettle
    case h7171 = "H7171"
    
    /// Govee Portable Countertop Ice Maker
    case h7172 = "H7172"
    
    /// Govee Smart Electric Kettle Lite
    case h7173 = "H7173"
    
    /// Govee Smart Electric Gooseneck Kettle
    case h7175 = "H7175"
    
    /// Govee Smart Rice Cooker Pro
    case h7180 = "H7180"
}

// MARK: - Codable

#if !hasFeature(Embedded)
extension GoveeModel: Codable { }
#endif
