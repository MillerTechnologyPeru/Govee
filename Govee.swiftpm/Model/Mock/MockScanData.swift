//
//  MockScanData.swift
//
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

#if DEBUG
import Foundation
import Bluetooth
import GATT

public typealias MockScanData = ScanData<GATT.Peripheral, MockAdvertisementData>

public extension MockScanData {
    
    static let beacon = MockScanData(
        peripheral: .beacon,
        date: Date(timeIntervalSinceReferenceDate: 10_000),
        rssi: -20,
        advertisementData: .beacon,
        isConnectable: true
    )
    
    static let savantThermostat = MockScanData(
        peripheral: .smartThermostat,
        date: Date(timeIntervalSinceReferenceDate: 10_100),
        rssi: -127,
        advertisementData: .savantThermostat,
        isConnectable: true
    )
    
    static var goveeThermometer: MockScanData {
        MockScanData(
            peripheral: .goveeThermometer,
            date: Date(timeIntervalSinceReferenceDate: 10_100),
            rssi: -127,
            advertisementData: .goveeThermometer,
            isConnectable: true
        )
    }
}

public extension MockCentral.Peripheral {
    
    static var random: MockCentral.Peripheral {
        Peripheral(id: BluetoothAddress(bytes: (
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max),
            .random(in: .min ... .max)))
        )
    }
    
    static var beacon: Peripheral {
        Peripheral(id: BluetoothAddress(rawValue: "00:AA:AB:03:10:01")!)
    }
    
    static var smartThermostat: Peripheral {
        Peripheral(id: BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!)
    }
    
    static var goveeThermometer: Peripheral {
        Peripheral(id: BluetoothAddress(rawValue: "A4:C1:38:2D:7A:27")!)
    }
}

public extension MockCentral.Peripheral.ID {
    
    static var random: MockCentral.Peripheral.ID {
        return MockCentral.Peripheral.random.id
    }
}

#endif
