//
//  Error.swift
//
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

#if canImport(FoundationEmbedded)
import FoundationEmbedded
#else
import Foundation
#endif
import Govee
#if hasFeature(Embedded)
import GATT
import DarwinGATT
#endif

/// Govee app errors.
public enum GoveeAppError: Error {
    
    case bluetoothUnavailable
    
    case unknown(GoveeAccessory.ID)
}

/// A message describing the error, for the log or the user.
func errorDescription(_ error: Error) -> String {
    #if hasFeature(Embedded)
    // Embedded Swift has no `localizedDescription`.
    if let error = error as? GoveeConnectionError {
        return error.description
    }
    if let error = error as? DarwinCentralError {
        return error.description
    }
    if let error = error as? GoveeAppError {
        switch error {
        case .bluetoothUnavailable:
            return "Bluetooth is unavailable"
        case let .unknown(id):
            return "Unknown device \(id)"
        }
    }
    if let error = error as? CentralError {
        switch error {
        case .timeout:
            return "The operation timed out"
        case .disconnected:
            return "The device is disconnected"
        case .unknownPeripheral:
            return "Unknown device"
        case let .invalidAttribute(uuid):
            return "Invalid attribute \(uuid)"
        }
    }
    return "Error"
    #else
    return String(describing: error)
    #endif
}
