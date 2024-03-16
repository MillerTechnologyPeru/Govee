//
//  AdvertisementName.swift
//
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

import Foundation

/// Govee Advertisement Name
public struct GoveeAdvertisementName: RawRepresentable, Equatable, Hashable, Codable, Sendable {
    
    public let rawValue: String
    
    public let model: GoveeModel
    
    internal let addressSuffix: UInt16
    
    public init?(rawValue: String) {
        var string = rawValue
        // parse model and mac bytes
        if string.hasPrefix("GV") {
            string.removeFirst("GV".count)
        } else if string.hasPrefix("ihoment_") {
            string.removeFirst("ihoment_".count)
        }
        
        guard let model = GoveeModel.allCases.first(where: { string.hasPrefix($0.rawValue) }) else {
            return nil
        }
        string.removeFirst(model.rawValue.count)
        string = string.replacingOccurrences(of: "_", with: "")
        guard string.count == 4,
            let macSuffix = UInt16(string, radix: 16) else {
            return nil
        }
        self.init(
            rawValue: rawValue,
            model: model,
            addressSuffix: macSuffix
        )
    }
    
    internal init(rawValue: String, model: GoveeModel, addressSuffix: UInt16) {
        self.rawValue = rawValue
        self.model = model
        self.addressSuffix = addressSuffix
        assert(rawValue.localizedStandardContains(model.rawValue))
        assert(rawValue.hasSuffix(addressSuffix.toHexadecimal()))
    }
}

// MARK: - CustomStringConvertible

extension GoveeAdvertisementName: CustomStringConvertible {
    
    public var description: String {
        rawValue
    }
}
