//
//  Address.swift
//
//
//  Created by Alsey Coleman Miller on 3/15/24.
//

import Foundation
import Bluetooth

public extension GoveeAdvertisementName {
    
    /// Bluetooth address based on advertised name.
    var address: BluetoothAddress {
        let prefix = self.model.addressPrefix
        let suffix = self.addressSuffix.bigEndian.bytes
        return BluetoothAddress(
            bigEndian:
                BluetoothAddress(
                    bytes: (
                        prefix.0,
                        prefix.1,
                        prefix.2,
                        prefix.3,
                        suffix.0,
                        suffix.1
                    )
                )
        )
    }
}

internal extension GoveeModel {
    
    /// Address Prefix in big endian format
    var addressPrefix: (UInt8, UInt8, UInt8, UInt8) {
        switch self {
        case .h5072:
            return (0xA4, 0xC1, 0x38, 0x2D)
        case .h5074:
            assertionFailure("Not implemented")
            return (0xA4, 0xC1, 0x38, 0x2D)
        case .h5075:
            assertionFailure("Not implemented")
            return (0xA4, 0xC1, 0x38, 0x2D)
        case .h5086:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5101:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5102:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5177:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5178:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5179:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5182:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5183:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5184:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5185:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h5198:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h7130:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h7131:
            return (0x60, 0x74, 0xF4, 0x75)
        case .h7135:
            return (0xD4, 0xAD, 0xFC, 0x84)
        case .h7161:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h7162:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h7170:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h7171:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h7172:
            assertionFailure("Not implemented")
            return (0x00, 0x00, 0x00, 0x00)
        case .h7173:
            return (0x60, 0x74, 0xF4, 0x57)
        case .h7175:
            return (0x60, 0x74, 0xF4, 0x8B)
        case .h7180:
            return (0x60, 0x74, 0xF4, 0x14)
        }
    }
}
