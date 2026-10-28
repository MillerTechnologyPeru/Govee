//
//  KettleTests.swift
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

final class KettleTests: XCTestCase {
    
    func testH7173Advertisement() {
        
        do {
            /*
             HCI Event        0x0000  60:74:F4:57:2A:DB  LE - Ext ADV - 1 Report - Normal - Public - 60:74:F4:57:2A:DB  -52 dBm - GVH71732ADB - Manufacturer Specific Data - Channel 37
                 Parameter Length: 57 (0x39)
                 Num Reports: 0X01
                 Report 0
                     Event Type: Connectable Advertising - Scannable Advertising - Legacy Advertising PDUs Used - Complete -
                     Address Type: Public
                     Peer Address: 60:74:F4:57:2A:DB
                     Primary PHY: 1M
                     Secondary PHY: No Packets
                     Advertising SID: Unavailable
                     Tx Power: Unavailable
                     RSSI: -52 dBm
                     Periodic Advertising Interval: 0.000000ms (0x0)
                     Direct Address Type: Public
                     Direct Address: 00:00:00:00:00:00
                     Data Length: 31
                     Flags: 0x5
                         LE Limited Discoverable Mode
                         BR/EDR Not Supported
                     Local Name: GVH71732ADB
                     Data: 02 01 05 0C 09 47 56 48 37 31 37 33 32 41 44 42 0E FF 03 88 EC 00 01 01 00 00 00 00 00 00 00

             */
            
            // Idle
            let adverisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x0C, 0x09, 0x47, 0x56, 0x48, 0x37, 0x31, 0x37, 0x33, 0x32, 0x41, 0x44, 0x42, 0x0E, 0xFF, 0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            
            XCTAssertEqual(adverisementData.localName, "GVH71732ADB")
            XCTAssertNil(adverisementData.serviceUUIDs)
            XCTAssertNil(adverisementData.serviceData)
            XCTAssertEqual(adverisementData.manufacturerData?.companyIdentifier, 0x8803)
            XCTAssertEqual(adverisementData.manufacturerData?.additionalData.count, 11)
            
            guard let advertisement = GoveeAccessory.Kettle(adverisementData) else {
                XCTFail()
                return
            }
            
            XCTAssertFalse(advertisement.isActive)
            XCTAssertEqual(advertisement.state, .idle)
        }
        
        // While boiling, Coffee
        do {
            let adverisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x0C, 0x09, 0x47, 0x56, 0x48, 0x37, 0x31, 0x37, 0x33, 0x32, 0x41, 0x44, 0x42, 0x0E, 0xFF, 0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
            
            XCTAssertEqual(adverisementData.localName, "GVH71732ADB")
            XCTAssertNil(adverisementData.serviceUUIDs)
            XCTAssertNil(adverisementData.serviceData)
            XCTAssertEqual(adverisementData.manufacturerData?.companyIdentifier, 0x8803)
            XCTAssertEqual(adverisementData.manufacturerData?.additionalData.count, 11)
            
            guard let advertisement = GoveeAccessory.Kettle(adverisementData) else {
                XCTFail()
                return
            }
            
            XCTAssert(advertisement.isActive)
            XCTAssertEqual(advertisement.state, .heating)
        }
        
        // Boiling, DIY
        do {
            let adverisementData: LowEnergyAdvertisingData = [02, 0x01, 0x05, 0x0C, 0x09, 0x47, 0x56, 0x48, 0x37, 0x31, 0x37, 0x33, 0x32, 0x41, 0x44, 0x42, 0x0E, 0xFF, 0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
            
            XCTAssertEqual(adverisementData.localName, "GVH71732ADB")
            XCTAssertNil(adverisementData.serviceUUIDs)
            XCTAssertNil(adverisementData.serviceData)
            XCTAssertEqual(adverisementData.manufacturerData?.companyIdentifier, 0x8803)
            XCTAssertEqual(adverisementData.manufacturerData?.additionalData.count, 11)
            
            guard let advertisement = GoveeAccessory.Kettle(adverisementData) else {
                XCTFail()
                return
            }
            
            XCTAssert(advertisement.isActive)
            XCTAssertEqual(advertisement.state, .heating)
        }
        
        // Keep warm, Coffee (heating)
        do {
            let adverisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x0C, 0x09, 0x47, 0x56, 0x48, 0x37, 0x31, 0x37, 0x33, 0x32, 0x41, 0x44, 0x42, 0x0E, 0xFF, 0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
            
            XCTAssertEqual(adverisementData.localName, "GVH71732ADB")
            XCTAssertNil(adverisementData.serviceUUIDs)
            XCTAssertNil(adverisementData.serviceData)
            XCTAssertEqual(adverisementData.manufacturerData?.companyIdentifier, 0x8803)
            XCTAssertEqual(adverisementData.manufacturerData?.additionalData.count, 11)
            
            guard let advertisement = GoveeAccessory.Kettle(adverisementData) else {
                XCTFail()
                return
            }
            
            XCTAssert(advertisement.isActive)
            XCTAssertEqual(advertisement.state, .heating)
        }
        
        // Keep warm, Coffee (finished heating)
        do {
            let adverisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x0C, 0x09, 0x47, 0x56, 0x48, 0x37, 0x31, 0x37, 0x33, 0x32, 0x41, 0x44, 0x42, 0x0E, 0xFF, 0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00]
            
            XCTAssertEqual(adverisementData.localName, "GVH71732ADB")
            XCTAssertNil(adverisementData.serviceUUIDs)
            XCTAssertNil(adverisementData.serviceData)
            XCTAssertEqual(adverisementData.manufacturerData?.companyIdentifier, 0x8803)
            XCTAssertEqual(adverisementData.manufacturerData?.additionalData.count, 11)
            
            guard let advertisement = GoveeAccessory.Kettle(adverisementData) else {
                XCTFail()
                return
            }
            
            XCTAssert(advertisement.isActive)
            XCTAssertEqual(advertisement.state, .keepingWarm)
        }
        
        
        do {
            let adverisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x0C, 0x09, 0x47, 0x56, 0x48, 0x37, 0x31, 0x37, 0x33, 0x32, 0x41, 0x44, 0x42, 0x0E, 0xFF, 0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00]
            
            XCTAssertEqual(adverisementData.localName, "GVH71732ADB")
            XCTAssertNil(adverisementData.serviceUUIDs)
            XCTAssertNil(adverisementData.serviceData)
            XCTAssertEqual(adverisementData.manufacturerData?.companyIdentifier, 0x8803)
            XCTAssertEqual(adverisementData.manufacturerData?.additionalData.count, 11)
            
            guard let advertisement = GoveeAccessory.Kettle(adverisementData) else {
                XCTFail()
                return
            }
            
            XCTAssert(advertisement.isActive)
            XCTAssertEqual(advertisement.state, .finishedBoiling)
        }
    }
    
    func testH7175Advertisement() {
        
        /*
          HCI Event        0x0000  60:74:F4:8B:B7:19  LE - Ext ADV - 1 Report - Normal - Public - 60:74:F4:8B:B7:19  -67 dBm - ihoment_H7175_B719 - Channel 37
             Parameter Length: 49 (0x31)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:74:F4:8B:B7:19
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -67 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 23
                 Flags: 0x5
                     LE Limited Discoverable Mode
                     BR/EDR Not Supported
                 Local Name: ihoment_H7175_B719
                 Data: 02 01 05 13 09 69 68 6F 6D 65 6E 74 5F 48 37 31 37 35 5F 42 37 31 39
         */
        
        let advertisementData: LowEnergyAdvertisingData = [0x02, 0x01, 0x05, 0x13, 0x09, 0x69, 0x68, 0x6F, 0x6D, 0x65, 0x6E, 0x74, 0x5F, 0x48, 0x37, 0x31, 0x37, 0x35, 0x5F, 0x42, 0x37, 0x31, 0x39]
        
        XCTAssertEqual(advertisementData.localName, "ihoment_H7175_B719")
        
        /*
         HCI Event        0x0000  60:74:F4:8B:B7:19  LE - Ext ADV - 1 Report - Normal - Public - 60:74:F4:8B:B7:19  -67 dBm - Manufacturer Specific Data - Channel 37
             Parameter Length: 45 (0x2D)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Scan Response - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:74:F4:8B:B7:19
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -67 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 19
                 Appearance: 000000
                 Data: 03 19 00 00 0E FF 02 88 EC 00 01 01 00 00 00 65 CB 56 5D
         */
        let scanResponse: LowEnergyAdvertisingData = [0x03, 0x19, 0x00, 0x00, 0x0E, 0xFF, 0x02, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x65, 0xCB, 0x56, 0x5D]
        
        XCTAssertNil(scanResponse.localName)
        XCTAssertNil(scanResponse.serviceUUIDs)
        XCTAssertNil(scanResponse.serviceData)
        XCTAssertEqual(scanResponse.manufacturerData?.companyIdentifier, 0x8802)
        XCTAssertEqual(scanResponse.manufacturerData?.additionalData.count, 11)
        
        guard let name = advertisementData.localName,
              let manufacturerData = scanResponse.manufacturerData,
              let kettle = GoveeAccessory.Kettle(name: name, manufacturerData: manufacturerData) else {
                XCTFail()
            return
        }
        
        XCTAssertEqual(kettle.id.rawValue, "ihoment_H7175_B719")
        XCTAssertFalse(kettle.isActive)
        XCTAssertEqual(kettle.state, .idle)
        XCTAssertEqual(kettle.id.model, .h7175)
    }
    
    func testH7173NewerFirmwareAdvertisement() {
        
        // Captured 2026-10-28 with a CoreBluetooth scan on macOS, heating
        // GVH71732ADB | mfr 43 88 EC 00 02 01 01 00 01 00 00 00 00
        // Same kettle as the captures above, now with company identifier 0x8843
        guard let manufacturerData = GATT.ManufacturerSpecificData<Data>(data: Data([0x43, 0x88, 0xEC, 0x00, 0x02, 0x01, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00])) else {
            XCTFail()
            return
        }
        XCTAssertEqual(manufacturerData.companyIdentifier, 0x8843)
        XCTAssertEqual(manufacturerData.additionalData.count, 11)
        
        guard let kettle = GoveeAccessory.Kettle(name: "GVH71732ADB", manufacturerData: manufacturerData) else {
            XCTFail()
            return
        }
        XCTAssertEqual(kettle.id.model, .h7173)
        XCTAssert(kettle.isActive)
        XCTAssertEqual(kettle.state, .heating)
        XCTAssertEqual(GoveeAccessory(name: "GVH71732ADB", manufacturerData: manufacturerData), .kettle(kettle))
    }
}
