//
//  AirPurifierTests.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import XCTest
@testable import Govee
import Bluetooth
import GATT

final class AirPurifierTests: XCTestCase {

    func testH712CAdvertisement() {

        // Captured 2026-10-28 with a CoreBluetooth scan on macOS
        // GVH712CE78A | mfr 03 88 EC 00 01 01 00 00 (off)
        // GVH712CE78A | mfr 03 88 EC 00 01 01 01 00 (on)
        let values: [(manufacturerData: Data, isActive: Bool)] = [
            (Data([0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x00, 0x00]), false),
            (Data([0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00]), true),
        ]

        for (data, isActive) in values {
            guard let manufacturerData = GATT.ManufacturerSpecificData<Data>(data: data) else {
                XCTFail()
                return
            }
            XCTAssertEqual(manufacturerData.companyIdentifier, 0x8803)
            XCTAssertEqual(manufacturerData.additionalData.count, 6)

            guard let purifier = GoveeAccessory.AirPurifier(name: "GVH712CE78A", manufacturerData: manufacturerData) else {
                XCTFail()
                return
            }
            XCTAssertEqual(purifier.id.rawValue, "GVH712CE78A")
            XCTAssertEqual(purifier.id.model, .h712C)
            XCTAssertEqual(purifier.id.addressSuffix, 0xE78A)
            XCTAssertEqual(purifier.isActive, isActive)
            XCTAssertEqual(GoveeAccessory(name: "GVH712CE78A", manufacturerData: manufacturerData), .airPurifier(purifier))
            XCTAssertEqual(GoveeAccessory(name: "GVH712CE78A", manufacturerData: manufacturerData)?.type, .airPurifier)
        }
    }

    func testInvalidManufacturerData() {
        let values: [Data] = [
            // truncated
            Data([0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01]),
            // too long
            Data([0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00]),
            // missing 0xEC marker
            Data([0x03, 0x88, 0x00, 0x00, 0x01, 0x01, 0x01, 0x00]),
            // unknown company identifier
            Data([0x4C, 0x00, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00]),
        ]
        for data in values {
            guard let manufacturerData = GATT.ManufacturerSpecificData<Data>(data: data) else {
                XCTFail()
                return
            }
            XCTAssertNil(GoveeAccessory.AirPurifier(name: "GVH712CE78A", manufacturerData: manufacturerData))
        }
    }

    func testWrongModelReturnsNil() {
        let manufacturerData = GATT.ManufacturerSpecificData<Data>(data: Data([0x03, 0x88, 0xEC, 0x00, 0x01, 0x01, 0x01, 0x00]))!
        XCTAssertNil(GoveeAccessory.AirPurifier(name: "GVH7131_A975", manufacturerData: manufacturerData))
    }
}
