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
    
    init(govee value: GoveeManufacturerData.CompanyIdentifier) {
        self.init(rawValue: value.rawValue)
    }
}
