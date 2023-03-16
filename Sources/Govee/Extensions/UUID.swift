//
//  UUID.swift
//  
//
//  Created by Alsey Coleman Miller on 3/15/23.
//

import Foundation
import Bluetooth

public extension UUID {
    
    static var goveeThermostat: UUID {
        UUID(uuidString: "494E5445-4C4C-495F-524F-434B535F4857")!
    }
}

public extension BluetoothUUID {
    
    /// Govee
    static var govee: BluetoothUUID {
        .bit16(0xEC88)
    }
    
    /// Govee Thermostat Service
    static var goveeThermostat: BluetoothUUID {
        BluetoothUUID(uuid: .goveeThermostat)
    }
}

public extension CompanyIdentifier {
    
    /// Govee (Shenzhen Intellirocks Tech. Co., Ltd.)
    static var govee: CompanyIdentifier {
        0xEC88
    }
}
