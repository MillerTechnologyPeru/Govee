//
//  UUID.swift
//  
//
//  Created by Alsey Coleman Miller on 3/15/23.
//

#if canImport(Foundation) && !hasFeature(Embedded)
import Foundation
#endif
import Bluetooth

#if canImport(Foundation) && !hasFeature(Embedded)
public extension UUID {
    
    static var goveeThermostat: UUID {
        UUID(uuidString: "494E5445-4C4C-495F-524F-434B535F4857")!
    }
}
#endif

public extension BluetoothUUID {
    
    /// Govee
    static var govee: BluetoothUUID {
        .bit16(0xEC88)
    }
    
    /// Govee Thermostat Service
    static var goveeThermostat: BluetoothUUID {
        BluetoothUUID(rawValue: "494E5445-4C4C-495F-524F-434B535F4857")!
    }

    /// Govee Control Service
    static var goveeControlService: BluetoothUUID {
        goveeControl(0x1910)
    }

    /// Govee Control Notify Characteristic
    static var goveeControlNotify: BluetoothUUID {
        goveeControl(0x2B10)
    }

    /// Govee Control Write Characteristic
    static var goveeControlWrite: BluetoothUUID {
        goveeControl(0x2B11)
    }

    /// Govee Setup Characteristic (`INTELLI_ROCKS_HW` service, thermometers)
    static var goveeSetup: BluetoothUUID {
        goveeIntelliRocks(0x2011)
    }

    /// Govee Data Characteristic (`INTELLI_ROCKS_HW` service, thermometers)
    static var goveeData: BluetoothUUID {
        goveeIntelliRocks(0x2012)
    }

    /// Govee History Characteristic (`INTELLI_ROCKS_HW` service, thermometers)
    static var goveeHistory: BluetoothUUID {
        goveeIntelliRocks(0x2013)
    }
}

private extension BluetoothUUID {

    /// `00010203-0405-0607-0809-0A0B0C0D____`
    static func goveeControl(_ suffix: UInt16) -> BluetoothUUID {
        BluetoothUUID(rawValue: "00010203-0405-0607-0809-0A0B0C0D" + suffix.toHexadecimal())!
    }

    /// `494E5445-4C4C-495F-524F-434B535F____`
    static func goveeIntelliRocks(_ suffix: UInt16) -> BluetoothUUID {
        BluetoothUUID(rawValue: "494E5445-4C4C-495F-524F-434B535F" + suffix.toHexadecimal())!
    }
}
