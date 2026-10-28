import Foundation
import XCTest
@testable import Govee
import Bluetooth
import GATT
import BluetoothGAP
import BluetoothHCI
import BluetoothGATT

final class GoveeTests: XCTestCase {
    
    func testAdvertisementName() {
        
        let values: [GoveeAdvertisementName] = [
            GoveeAdvertisementName(rawValue: "GVH5072_CF9C", model: .h5072, addressSuffix: 0xCF9C),
            GoveeAdvertisementName(rawValue: "GVH5072_7A27", model: .h5072, addressSuffix: 0x7A27),
            GoveeAdvertisementName(rawValue: "GVH71732ADB", model: .h7173, addressSuffix: 0x2ADB),
            GoveeAdvertisementName(rawValue: "GVH7180A693", model: .h7180, addressSuffix: 0xA693),
            GoveeAdvertisementName(rawValue: "ihoment_H7131_A975", model: .h7131, addressSuffix: 0xA975),
            GoveeAdvertisementName(rawValue: "ihoment_H7135_9F73", model: .h7135, addressSuffix: 0x9F73),
            GoveeAdvertisementName(rawValue: "ihoment_H7175_B719", model: .h7175, addressSuffix: 0xB719),
        ]
        
        for name in values {
            guard let decoded = GoveeAdvertisementName(rawValue: name.rawValue) else {
                XCTFail("Invalid name \(name)")
                return
            }
            XCTAssertEqual(name.rawValue, decoded.rawValue)
            XCTAssertEqual(name.rawValue, name.description)
            XCTAssertEqual(name.model, decoded.model)
            XCTAssertEqual(name.addressSuffix, decoded.addressSuffix)
        }
    }

    func testUnsupportedModelsReturnNil() {

        // valid names for models without a decoder, with arbitrary manufacturer data
        let names: [(String, GoveeAccessoryType)] = [
            ("GVH7172_1A2B", .iceMaker),
            ("GVH5086_1A2B", .smartPlug),
            ("GVH7161_1A2B", .oilDiffuser),
            ("GVH7162_1A2B", .oilDiffuser),
        ]
        let manufacturerData = GATT.ManufacturerSpecificData(
            companyIdentifier: .govee,
            additionalData: Data([0xEC, 0x00, 0x01, 0x01, 0x01, 0x00])
        )
        for (name, type) in names {
            XCTAssertEqual(GoveeAdvertisementName(rawValue: name)?.model.type, type)
            XCTAssertNil(GoveeAccessory(name: name, manufacturerData: manufacturerData))
        }
    }
}
