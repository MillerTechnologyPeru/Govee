//
//  RiceCookerTests.swift
//  
//
//  Created by Alsey Coleman Miller  on 3/13/24.
//

import Foundation
import XCTest
@testable import Govee
import Bluetooth
import GATT
import BluetoothGAP
import BluetoothHCI
import BluetoothGATT

final class RiceCookerTests: XCTestCase {
    
    func testH7180Advertisement() {
        
        /*
         HCI Event        0x0000  60:74:F4:14:A6:93  LE - Ext ADV - 1 Report - Normal - Public - 60:74:F4:14:A6:93  -61 dBm - GVH7180A693 - Channel 39
             Parameter Length: 42 (0x2A)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:74:F4:14:A6:93
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -61 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 16
                 Flags: 0x5
                     LE Limited Discoverable Mode
                     BR/EDR Not Supported
                 Local Name: GVH7180A693
                 Data: 02 01 05 0C 09 47 56 48 37 31 38 30 41 36 39 33
         */
        
        let advertisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x0C, 0x09, 0x47, 0x56, 0x48, 0x37, 0x31, 0x38, 0x30, 0x41, 0x36, 0x39, 0x33]
        
        XCTAssertEqual(advertisementData.localName, "GVH7180A693")
        
        /*
         HCI Event        0x0000  60:74:F4:14:A6:93  LE - Ext ADV - 1 Report - Normal - Public - 60:74:F4:14:A6:93  -61 dBm - Manufacturer Specific Data - Channel 39
             Parameter Length: 42 (0x2A)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Scan Response - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:74:F4:14:A6:93
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -61 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 16
                 Appearance: 000000
                 Data: 03 19 00 00 0B FF 02 88 EC 00 01 01 00 00 00 00
         */
        
        let scanResponse: LowEnergyAdvertisingData = [0x03, 0x19, 0x00, 0x00, 0x0B, 0xFF, 0x02, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00]
        
        XCTAssertEqual(scanResponse.manufacturerData?.companyIdentifier, 0x8802)
    }
}
