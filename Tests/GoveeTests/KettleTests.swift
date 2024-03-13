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
    
    func testGVH7173Advertisement() {
        
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
            
            XCTAssertFalse(advertisement.manufacturerData.isActive)
            XCTAssertEqual(advertisement.manufacturerData.state, .idle)
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
            
            XCTAssert(advertisement.manufacturerData.isActive)
            XCTAssertEqual(advertisement.manufacturerData.state, .heating)
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
            
            XCTAssert(advertisement.manufacturerData.isActive)
            XCTAssertEqual(advertisement.manufacturerData.state, .heating)
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
            
            XCTAssert(advertisement.manufacturerData.isActive)
            XCTAssertEqual(advertisement.manufacturerData.state, .heating)
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
            
            XCTAssert(advertisement.manufacturerData.isActive)
            XCTAssertEqual(advertisement.manufacturerData.state, .keepingWarm)
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
            
            XCTAssert(advertisement.manufacturerData.isActive)
            XCTAssertEqual(advertisement.manufacturerData.state, .finishedBoiling)
        }
        
    }
}
