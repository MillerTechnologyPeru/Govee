import Foundation
import XCTest
@testable import Govee
import Bluetooth
import GATT
import BluetoothGAP
import BluetoothHCI
import BluetoothGATT

final class GoveeTests: XCTestCase {
    
    func testBeaconAdvertisement() {
        
        /*
         Parameter Length: 53 (0x35)
         Num Reports: 0X01
         Report 0
             Event Type: Connectable Advertising - Scannable Advertising - Scan Response - Legacy Advertising PDUs Used - Complete -
             Address Type: Public
             Peer Address: A4:C1:38:2D:7A:27
             Primary PHY: 1M
             Secondary PHY: No Packets
             Advertising SID: Unavailable
             Tx Power: Unavailable
             RSSI: -38 dBm
             Periodic Advertising Interval: 0.000000ms (0x0)
             Direct Address Type: Public
             Direct Address: 00:00:00:00:00:00
             Data Length: 27
             Apple Manufacturing Data
             Length: 26 (0x1A)
             Data: 1A FF 4C 00 02 15 49 4E 54 45 4C 4C 49 5F 52 4F 43 4B 53 5F 48 57 50 72 F2 FF C2
         */
        
        let advertisingData: LowEnergyAdvertisingData = [0x1A, 0xFF, 0x4C, 0x00, 0x02, 0x15, 0x49, 0x4E, 0x54, 0x45, 0x4C, 0x4C, 0x49, 0x5F, 0x52, 0x4F, 0x43, 0x4B, 0x53, 0x5F, 0x48, 0x57, 0x50, 0x72, 0xF2, 0xFF, 0xC2]
        
        guard let manufacturerData = advertisingData.manufacturerData,
              let beacon = AppleBeacon(manufacturerData: manufacturerData) else {
            XCTFail("Unable to parse")
            return
        }
        
        XCTAssertEqual(beacon.uuid, .goveeThermostat)
        print(beacon)
    }
    
    func testThermostatAdvertisement() {
        
        do {
            
            /*
             Mar 15 10:52:55.671  HCI Event        0x0000  A4:C1:38:2D:7A:27
             LE - Ext ADV - 1 Report - Normal - Public - A4:C1:38:2D:7A:27
             -37 dBm - GVH5072_7A27 - Manufacturer Specific Data - Channel 38
             
             Parameter Length: 57 (0x39)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: A4:C1:38:2D:7A:27
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -37 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 31
                 Local Name: GVH5072_7A27
                 16 Bit UUIDs: 0XEC88
                 Flags: 0x5
                     LE Limited Discoverable Mode
                     BR/EDR Not Supported
                 Data: 0D 09 47 56 48 35 30 37 32 5F 37 41 32 37 03 03 88 EC 02 01 05 09 FF 88 EC 00 03 94 90 64 00
             */
            
            let data = Data([0x3E, 0x39, 0x0D, 0x01, 0x13, 0xA6, 0x00, 0x27, 0x7A, 0x2D, 0x38, 0xC1, 0xA4, 0x81, 0x00, 0xFF, 0x7F, 0xDB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1F, 0x0D, 0x09, 0x47, 0x56, 0x48, 0x35, 0x30, 0x37, 0x32, 0x5F, 0x37, 0x41, 0x32, 0x37, 0x03, 0x03, 0x88, 0xEC, 0x02, 0x01, 0x05, 0x09, 0xFF, 0x88, 0xEC, 0x00, 0x03, 0x94, 0x90, 0x64, 0x00])
            
            guard let event = HCILowEnergyMetaEvent(data: data.advanced(by: 2)),
                  event.subevent == .extendedAdvertisingReport,
                  let reportEvent = HCILEExtendedAdvertisingReport(data: event.eventData),
                  let report = reportEvent.reports.first,
                  let adverisementData = LowEnergyAdvertisingData(report.responseData) else {
                XCTFail("Unable to parse")
                return
            }
            
            XCTAssertEqual(report.address.description, "A4:C1:38:2D:7A:27")
            XCTAssertEqual(adverisementData.localName, "GVH5072_7A27")
            XCTAssertEqual(adverisementData.serviceUUIDs, [.bit16(0xEC88)])
            XCTAssertEqual(adverisementData.manufacturerData?.companyIdentifier, .govee)
            
            guard let advertisement = GoveeAdvertisement.Thermometer(adverisementData) else {
                XCTFail("Unable to parse")
                return
            }
            
            XCTAssertEqual(advertisement.name, "GVH5072_7A27")
            XCTAssertEqual(advertisement.manufacturingData.reserved0, 0)
            XCTAssertEqual(advertisement.manufacturingData.reserved1, 0)
            XCTAssertEqual(advertisement.manufacturingData.batteryLevel, 100)
            XCTAssertEqual(advertisement.manufacturingData.encodedTemperature, 234640)
            XCTAssertEqual(advertisement.manufacturingData.temperature, 23.464)
            XCTAssertEqual(advertisement.manufacturingData.humidity, 64.0)
        }
        
        
        do {
            let manufacturerData = GAPManufacturerSpecificData(companyIdentifier: .govee, additionalData: Data([0, 3, 70, 146, 100, 0, 76, 0, 2, 21, 73, 78, 84, 69, 76, 76, 73, 95, 82, 79, 67, 75, 83, 95, 72, 87, 80, 114, 242, 255, 194]))
            
            guard let manufacturerData = GoveeAdvertisement.Thermometer.ManufacturingData(manufacturerData) else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(manufacturerData.batteryLevel, 100)
            XCTAssertEqual(manufacturerData.temperature, 21.4674)
            XCTAssertEqual(manufacturerData.humidity, 67.4)
        }
    }
}
