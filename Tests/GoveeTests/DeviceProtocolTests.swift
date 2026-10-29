//
//  DeviceProtocolTests.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import XCTest
@testable import Govee

/// Typed device commands and status parsing, checked against packets captured from the Govee app on 2026-10-28.
final class DeviceProtocolTests: XCTestCase {

    func testAirPurifierCommands() {
        typealias Command = GoveeAccessory.AirPurifier.Command
        let values: [(Command, String)] = [
            (.power(false), "33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32"),
            (.mode(.manual(speed: 1)), "3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            (.mode(.manual(speed: 2)), "3A 05 01 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C"),
            (.mode(.manual(speed: 3)), "3A 05 01 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            (.mode(.sleep), "3A 05 05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3A"),
            (.mode(.turbo), "3A 05 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 38"),
            (.nightLight(true), "3A 1B 01 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 20"),
            (.nightLight(false), "3A 1B 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 21"),
            (.nightLightBrightness(100), "3A 1B 01 02 64 00 00 00 00 00 00 00 00 00 00 00 00 00 00 46"),
            (.nightLightBrightness(10), "3A 1B 01 02 0A 00 00 00 00 00 00 00 00 00 00 00 00 00 00 28"),
            (.nightLightColor(red: 0xFF, green: 0x00, blue: 0x00), "3A 1B 05 0D FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 D6"),
            (.nightLightColor(red: 0x00, green: 0x00, blue: 0xFF), "3A 1B 05 0D 00 00 FF 00 00 00 00 00 00 00 00 00 00 00 00 D6"),
            (.display(false), "33 16 00 00 00 17 3B 01 00 00 00 00 00 00 00 00 00 00 00 08"),
            (.display(true), "33 16 01 00 00 17 3B 01 00 00 00 00 00 00 00 00 00 00 00 09"),
        ]
        assertCommands(values)
        XCTAssertEqual(GoveeAccessory.AirPurifier.Mode(mode: 0x07, value: 0x00), .turbo)
        XCTAssertEqual(GoveeAccessory.AirPurifier.Mode(mode: 0x01, value: 0x02), .manual(speed: 2))
        XCTAssertEqual(GoveeAccessory.AirPurifier.Mode(mode: 0x03, value: 0x00), .unknown(mode: 0x03, value: 0x00))
    }

    func testAirPurifierStatus() throws {
        XCTAssertEqual(GoveeQuery.airPurifierMode.packet.bytes, bytes("AA 05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AF"))
        XCTAssertEqual(GoveeQuery.airPurifierManualSpeed.packet.bytes, bytes("AA 05 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AE"))

        XCTAssertEqual(try packet("AA 01 01 00 00 FF FF 06 00 00 00 00 00 00 00 00 00 00 00 AC").power, true)
        XCTAssertEqual(try packet("AA 01 00 00 00 FF FF 06 00 00 00 00 00 00 00 00 00 00 00 AD").power, false)
        XCTAssertEqual(try packet("AA 05 00 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 A8").airPurifierMode, 0x07)
        XCTAssertEqual(try packet("AA 05 01 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AD").airPurifierManualSpeed, 3)
        XCTAssertNil(try packet("AA 05 01 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AD").airPurifierMode)
        let light = try XCTUnwrap(packet("AA 1B 01 01 32 00 00 00 00 00 00 00 00 00 00 00 00 00 00 83").airPurifierNightLight)
        XCTAssertTrue(light.isOn)
        XCTAssertEqual(light.brightness, 50)
        let color = try XCTUnwrap(packet("AA 1B 05 0D FF 8D 0B 00 00 00 00 00 00 00 00 00 00 00 00 C0").airPurifierNightLightColor)
        XCTAssertEqual([color.red, color.green, color.blue], [0xFF, 0x8D, 0x0B])
        XCTAssertEqual(try packet("AA 06 31 2E 30 30 2E 31 36 00 00 00 00 00 00 00 00 00 00 9A").firmwareVersion, "1.00.16")
    }

    func testHeaterCommands() throws {
        typealias Command = GoveeAccessory.Heater.Command
        let values: [(Command, String)] = [
            (.power(true), "33 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 33"),
            (.power(false), "33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32"),
            (.mode(.heat(level: 1)), "3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            (.mode(.heat(level: 2)), "3A 05 01 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C"),
            (.mode(.heat(level: 3)), "3A 05 01 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            (.mode(.fan), "3A 05 09 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 36"),
            (.display(true), "33 16 01 FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00 24"),
            (.display(false), "33 16 00 FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00 25"),
            (.lock(true), "33 1F 02 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2F"),
            (.lock(false), "33 1F 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E"),
        ]
        assertCommands(values)

        let status = try packet("AA 01 01 00 00 00 01 03 B3 CF 00 00 00 00 00 00 00 00 00 D4")
        XCTAssertEqual(status.power, true)
        let reading = try XCTUnwrap(status.heaterThermometerReading)
        XCTAssertEqual(reading.temperature, 24.2639, accuracy: 0.0001)
        XCTAssertEqual(reading.humidity, 63.9, accuracy: 0.01)
    }

    func testKettleCommands() throws {
        typealias Command = GoveeAccessory.Kettle.Command
        let values: [(Command, String)] = [
            (.heating(true), "33 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 33"),
            (.heating(false), "33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32"),
            (.targetTemperature(fahrenheit: 111), "3A 05 00 05 2B 5C 00 00 00 00 00 00 00 00 00 00 00 00 00 4D"),
            (.targetTemperature(fahrenheit: 174), "3A 05 00 05 43 F8 00 00 00 00 00 00 00 00 00 00 00 00 00 81"),
            (.boil, "3A 05 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            (.preset(.tea, index: 1), "3A 05 00 03 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            (.preset(.tea, index: 2), "3A 05 00 03 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3E"),
            (.preset(.coffee, index: 1), "3A 05 00 04 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3A"),
            (.preset(.diy, index: 1), "3A 05 00 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            (.keepWarm(true, minutes: 60), "3A 22 01 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 25"),
            (.keepWarm(false, minutes: 60), "3A 22 00 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 24"),
        ]
        assertCommands(values)

        let idle = try XCTUnwrap(packet("AA 00 00 00 01 36 4C 01 00 00 00 00 00 00 00 00 00 00 00 D0").kettleStatus)
        XCTAssertFalse(idle.isHeating)
        XCTAssertEqual(idle.temperature, 139)
        let heating = try XCTUnwrap(packet("AA 00 01 00 01 37 14 01 01 00 00 00 00 00 00 00 00 00 00 89").kettleStatus)
        XCTAssertTrue(heating.isHeating)
        XCTAssertEqual(heating.temperature, 141)
        let keepWarm = try XCTUnwrap(packet("AA 22 01 00 3C 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 89").kettleKeepWarm)
        XCTAssertTrue(keepWarm.isOn)
        XCTAssertEqual(keepWarm.minutes, 60)
    }

    func testThermometerQueries() throws {
        XCTAssertEqual(GoveeQuery.thermometerReading.channel, .data)
        XCTAssertEqual(GoveeQuery.thermometerReading.packet.bytes, bytes("AA 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AB"))
        XCTAssertEqual(GoveeQuery.thermometerFirmwareVersion.channel, .setup)

        let reading = try XCTUnwrap(packet("AA 01 09 7E 18 ED 25 00 00 00 00 00 00 00 00 00 00 00 00 0C").thermometerReading)
        XCTAssertEqual(reading.temperature, 24.30, accuracy: 0.001)
        XCTAssertEqual(reading.humidity, 63.81, accuracy: 0.001)
        XCTAssertEqual(reading.batteryLevel, 37)
        XCTAssertEqual(try packet("AA 0E 31 2E 30 31 2E 30 34 00 00 00 00 00 00 00 00 00 00 90").thermometerFirmwareVersion, "1.01.04")
    }

    func testChannels() {
        XCTAssertEqual(GoveeChannel.control.write.rawValue.uppercased(), "00010203-0405-0607-0809-0A0B0C0D2B11")
        XCTAssertEqual(GoveeChannel.control.notify.rawValue.uppercased(), "00010203-0405-0607-0809-0A0B0C0D2B10")
        XCTAssertEqual(GoveeChannel.data.write.rawValue.uppercased(), "494E5445-4C4C-495F-524F-434B535F2012")
        XCTAssertEqual(GoveeModel.h7135.security, .encrypted)
        XCTAssertEqual(GoveeModel.h712C.security, .plaintext)
    }
}

// MARK: - Helpers

private extension DeviceProtocolTests {

    struct InvalidPacket: Error { }

    func bytes(_ hex: String) -> [UInt8] {
        hex.split(separator: " ").compactMap { UInt8($0, radix: 16) }
    }

    func packet(_ hex: String) throws -> GoveePacket {
        guard let packet = GoveePacket(bytes: bytes(hex)) else {
            throw InvalidPacket()
        }
        return packet
    }

    func assertCommands<Command: GoveeRequest>(_ values: [(Command, String)], file: StaticString = #filePath, line: UInt = #line) {
        for (command, hex) in values {
            XCTAssertEqual(command.packet.bytes, bytes(hex), "\(command)", file: file, line: line)
            XCTAssertEqual(command.channel, .control, file: file, line: line)
        }
    }
}
