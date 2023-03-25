//
//  Error.swift
//
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

import Foundation
import Govee

/// Govee app errors.
public enum GoveeAppError: Error {
    
    case bluetoothUnavailable
    
    case unknown(GoveeAdvertisement.ID)
}
