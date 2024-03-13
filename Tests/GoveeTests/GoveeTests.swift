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
            GoveeAdvertisementName(rawValue: "GVH5072_CF9C", model: .h5072, macSuffix: 0xCF9C),
            GoveeAdvertisementName(rawValue: "GVH5072_7A27", model: .h5072, macSuffix: 0x7A27),
            GoveeAdvertisementName(rawValue: "GVH71732ADB", model: .h7173, macSuffix: 0x2ADB)
        ]
        
        for name in values {
            guard let decoded = GoveeAdvertisementName(rawValue: name.rawValue) else {
                XCTFail("Invalid name \(name)")
                return
            }
            XCTAssertEqual(name.rawValue, decoded.rawValue)
            XCTAssertEqual(name.rawValue, name.description)
            XCTAssertEqual(name.model, decoded.model)
            XCTAssertEqual(name.macSuffix, decoded.macSuffix)
        }
    }
}
