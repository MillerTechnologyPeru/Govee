//
//  CompanyIdentifier.swift
//
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

import Foundation
import Bluetooth

public extension Bluetooth.CompanyIdentifier {
    
    /// Govee (Shenzhen Intellirocks Tech. Co., Ltd.)
    static var govee: CompanyIdentifier {
        0xEC88
    }
}

internal extension Bluetooth.CompanyIdentifier {
    
    init(govee value: GoveeCompanyIdentifier) {
        self.init(rawValue: value.rawValue)
    }
}

internal enum GoveeCompanyIdentifier: UInt16, Sendable, Codable, CaseIterable {
    
    case thermometer    = 0xEC88
    case v2             = 0x8802
    case v3             = 0x8803

    /// Seen on H7173 kettle with newer firmware.
    case v3Alternate    = 0x8843
}
