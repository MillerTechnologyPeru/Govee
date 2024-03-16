//
//  HeaterTests.swift
//
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

import Foundation
import XCTest
@testable import Govee
import Bluetooth
import GATT
import BluetoothGAP
import BluetoothHCI
import BluetoothGATT

final class HeaterTests: XCTestCase {
    
    func testH7131Advertisement() {
        
        /*
         0x0000  60:74:F4:75:A9:75  LE - Ext ADV - 1 Report - Normal - Public - 60:74:F4:75:A9:75  -74 dBm - ihoment_H7131_A975 - Channel 37
             Parameter Length: 49 (0x31)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:74:F4:75:A9:75
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -74 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 23
                 Flags: 0x5
                     LE Limited Discoverable Mode
                     BR/EDR Not Supported
                 Local Name: ihoment_H7131_A975
                 Data: 02 01 05 13 09 69 68 6F 6D 65 6E 74 5F 48 37 31 33 31 5F 41 39 37 35
         */
        
        let advertisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x13, 0x09, 0x69, 0x68, 0x6F, 0x6D, 0x65, 0x6E, 0x74, 0x5F, 0x48, 0x37, 0x31, 0x33, 0x31, 0x5F, 0x41, 0x39, 0x37, 0x35]
        
        XCTAssertEqual(advertisementData.localName, "ihoment_H7131_A975")
        XCTAssertNil(advertisementData.serviceUUIDs)
        XCTAssertNil(advertisementData.serviceData)
        XCTAssertNil(advertisementData.manufacturerData)
        
        /*
         HCI Event        0x0000  60:74:F4:75:A9:75  LE - Ext ADV - 1 Report - Normal - Public - 60:74:F4:75:A9:75  -74 dBm - Manufacturer Specific Data - Channel 37
             Parameter Length: 40 (0x28)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Scan Response - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:74:F4:75:A9:75
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -74 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 14
                 Appearance: 000000
                 Data: 03 19 00 00 09 FF 02 88 EC 00 01 01 01 00

         */
        
        let scanResponse: LowEnergyAdvertisingData = [0x03, 0x19, 0x00, 0x00, 0x09, 0xFF, 0x02, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00]
        
        XCTAssertNil(scanResponse.localName)
        XCTAssertNil(scanResponse.serviceUUIDs)
        XCTAssertNil(scanResponse.serviceData)
        XCTAssertEqual(scanResponse.manufacturerData?.companyIdentifier, 0x8802)
        XCTAssertEqual(scanResponse.manufacturerData?.additionalData.count, 6)
        
        guard let name = advertisementData.localName,
              let manufacturerData = scanResponse.manufacturerData,
              let heater = GoveeAccessory.Heater(name: name, manufacturerData: manufacturerData) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(heater.id.rawValue, "ihoment_H7131_A975")
        XCTAssert(heater.isActive)
        XCTAssertEqual(heater.id.model, .h7131)
    }
    
    func testH7135Advertisement() {
        
        /*
          HCI Event        0x0000  D4:AD:FC:84:9F:73  LE - Ext ADV - 1 Report - Normal - Public - D4:AD:FC:84:9F:73  -49 dBm - ihoment_H7135_9F73 - Channel 39
             Parameter Length: 49 (0x31)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: D4:AD:FC:84:9F:73
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -49 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 23
                 Flags: 0x5
                     LE Limited Discoverable Mode
                     BR/EDR Not Supported
                 Local Name: ihoment_H7135_9F73
                 Data: 02 01 05 13 09 69 68 6F 6D 65 6E 74 5F 48 37 31 33 35 5F 39 46 37 33
         */
        
        let advertisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x13, 0x09, 0x69, 0x68, 0x6F, 0x6D, 0x65, 0x6E, 0x74, 0x5F, 0x48, 0x37, 0x31, 0x33, 0x35, 0x5F, 0x39, 0x46, 0x37, 0x33]
        
        XCTAssertEqual(advertisementData.localName, "ihoment_H7135_9F73")
        XCTAssertNil(advertisementData.serviceUUIDs)
        XCTAssertNil(advertisementData.serviceData)
        XCTAssertNil(advertisementData.manufacturerData)
        
        /*
         HCI Event        0x0000  D4:AD:FC:84:9F:73  LE - Ext ADV - 1 Report - Normal - Public - D4:AD:FC:84:9F:73  -49 dBm - Manufacturer Specific Data - Channel 39
             Parameter Length: 40 (0x28)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Scan Response - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: D4:AD:FC:84:9F:73
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -49 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 14
                 Appearance: 000000
                 Data: 03 19 00 00 09 FF 02 88 EC 00 01 01 01 00

         */
        
        let scanResponse: LowEnergyAdvertisingData = [0x03, 0x19, 0x00, 0x00, 0x09, 0xFF, 0x02, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00]
        
        XCTAssertNil(scanResponse.localName)
        XCTAssertNil(scanResponse.serviceUUIDs)
        XCTAssertNil(scanResponse.serviceData)
        XCTAssertEqual(scanResponse.manufacturerData?.companyIdentifier, 0x8802)
        XCTAssertEqual(scanResponse.manufacturerData?.additionalData.count, 6)
        
        guard let name = advertisementData.localName,
              let manufacturerData = scanResponse.manufacturerData,
              let heater = GoveeAccessory.Heater(name: name, manufacturerData: manufacturerData) else {
                XCTFail()
            return
        }
        
        XCTAssertEqual(heater.id.rawValue, "ihoment_H7135_9F73")
        XCTAssert(heater.isActive)
        XCTAssertEqual(heater.id.model, .h7135)
    }
    
    func testManufacturerData() {
        
        // On
        do {
            let scanResponse: LowEnergyAdvertisingData = [0x03, 0x19, 0x00, 0x00, 0x09, 0xFF, 0x02, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00]
            guard let manufacturerData = scanResponse.manufacturerData,
                  let heaterManufacturerData = GoveeAccessory.Heater.ManufacturerData(manufacturerData) else {
                XCTFail()
                return
            }
            
            XCTAssert(heaterManufacturerData.isActive)
        }
        
        // Off
        do {
            let scanResponse: LowEnergyAdvertisingData = [0x03, 0x19, 0x00, 0x00, 0x09, 0xFF, 0x02, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x00, 0x00]
            guard let manufacturerData = scanResponse.manufacturerData,
                  let heaterManufacturerData = GoveeAccessory.Heater.ManufacturerData(manufacturerData) else {
                XCTFail()
                return
            }
            
            XCTAssertFalse(heaterManufacturerData.isActive)
        }
    }
}
