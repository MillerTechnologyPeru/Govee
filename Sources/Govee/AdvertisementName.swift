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
    
    internal let macSuffix: UInt16
    
    public init?(rawValue: String) {
        var string = rawValue
        // parse model and mac bytes
        guard string.hasPrefix("GV") else {
            return nil
        }
        string.removeFirst(2)
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
            macSuffix: macSuffix
        )
    }
    
    internal init(rawValue: String, model: GoveeModel, macSuffix: UInt16) {
        self.rawValue = rawValue
        self.model = model
        self.macSuffix = macSuffix
        assert(rawValue.localizedStandardContains(model.rawValue))
        assert(rawValue.hasSuffix(macSuffix.toHexadecimal()))
    }
}

// MARK: - CustomStringConvertible

extension GoveeAdvertisementName: CustomStringConvertible {
    
    public var description: String {
        rawValue
    }
}
