//
//  CapturedPacketTests.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import XCTest
@testable import Govee

/// Packets captured from the Govee app with PacketLogger on 2026-10-28.
///
/// H712C purifier traffic is plaintext. H7135 heater and H7173 kettle traffic was
/// decrypted (v1 scheme, see Docs/BLE-Protocol.md); the vectors below are the plaintext frames.
/// Session setup (`33 B2`) and multi-packet tokens are intentionally not included.
final class CapturedPacketTests: XCTestCase {

    // MARK: - H712C Purifier

    func testPurifierCommands() {
        // Govee app -> GVH712CE78A, matched to recorded actions
        let values: [(String, String)] = [
            ("Low", "3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            ("Medium", "3A 05 01 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C"),
            ("High", "3A 05 01 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            ("Sleeping", "3A 05 05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3A"),
            ("Turbo", "3A 05 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 38"),
            ("Night light off", "3A 1B 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 21"),
            ("Night light on", "3A 1B 01 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 20"),
            ("Night light 100%", "3A 1B 01 02 64 00 00 00 00 00 00 00 00 00 00 00 00 00 00 46"),
            ("Night light 10%", "3A 1B 01 02 0A 00 00 00 00 00 00 00 00 00 00 00 00 00 00 28"),
            ("Night light red", "3A 1B 05 0D FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 D6"),
            ("Night light green", "3A 1B 05 0D 00 FF 00 00 00 00 00 00 00 00 00 00 00 00 00 D6"),
            ("Night light blue", "3A 1B 05 0D 00 00 FF 00 00 00 00 00 00 00 00 00 00 00 00 D6"),
            ("Display off", "33 16 00 00 00 17 3B 01 00 00 00 00 00 00 00 00 00 00 00 08"),
            ("Display always on", "33 16 01 00 00 17 3B 01 00 00 00 00 00 00 00 00 00 00 00 09"),
            ("Display in period", "33 16 01 00 00 17 3B 00 00 00 00 00 00 00 00 00 00 00 00 08"),
            ("Timer 1 hour", "33 26 01 00 3C 00 0E 10 00 00 00 00 00 00 00 00 00 00 00 36"),
            ("Power off", "33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32"),
            ("Status query", "AA 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AB"),
        ]
        assertPackets(values)
    }

    func testPurifierModeCommandLayout() throws {
        // 3A 05 <mode> <speed>
        let low = try packet("3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F")
        XCTAssertEqual(low.id, .applianceCommand)
        XCTAssertEqual(Array(low.payload.prefix(3)), [0x05, 0x01, 0x01])
        XCTAssertEqual(GoveePacket(id: .applianceCommand, payload: [0x05, 0x01, 0x01]), low)

        // 3A 1B 05 0D <R> <G> <B>
        let red = try packet("3A 1B 05 0D FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 D6")
        XCTAssertEqual(Array(red.payload[3 ... 5]), [0xFF, 0x00, 0x00])

        // 33 26 01 <minutes, 2 bytes> <seconds, 3 bytes>
        let timer = try packet("33 26 01 00 3C 00 0E 10 00 00 00 00 00 00 00 00 00 00 00 36")
        XCTAssertEqual(bigEndian(timer.payload[2 ... 3]), 60)
        XCTAssertEqual(bigEndian(timer.payload[4 ... 6]), 3600)
    }

    func testPurifierClock() throws {
        // 33 B5 <unix time, 4 bytes> 01 <UTC offset hours>
        let clock = try packet("33 B5 6A E2 6B 0C 01 FC 00 00 00 00 00 00 00 00 00 00 00 94")
        XCTAssertEqual(clock.id, .command)
        XCTAssertEqual(clock.payload[0], 0xB5)
        let date = Date(timeIntervalSince1970: TimeInterval(bigEndian(clock.payload[1 ... 4])))
        XCTAssertEqual(date, ISO8601DateFormatter().date(from: "2026-10-28T21:37:16Z"))
        XCTAssertEqual(Int8(bitPattern: clock.payload[6]), -4)
    }

    func testPurifierStatus() throws {
        // GVH712CE78A -> Govee app
        let values: [(String, String)] = [
            ("Off", "AA 01 00 00 00 FF FF 06 00 00 00 00 00 00 00 00 00 00 00 AD"),
            ("On", "AA 01 01 00 00 FF FF 06 00 00 00 00 00 00 00 00 00 00 00 AC"),
            ("Mode turbo", "AA 05 00 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 A8"),
            ("Firmware", "AA 06 31 2E 30 30 2E 31 36 00 00 00 00 00 00 00 00 00 00 9A"),
            ("Bluetooth address", "AA 07 06 E8 06 90 0C E7 8A 00 00 00 00 00 00 00 00 00 00 B4"),
            ("Night light", "AA 1B 01 01 32 00 00 00 00 00 00 00 00 00 00 00 00 00 00 83"),
            ("Night light color", "AA 1B 05 0D FF 8D 0B 00 00 00 00 00 00 00 00 00 00 00 00 C0"),
            ("Display", "AA 16 01 00 00 17 3B 01 00 00 00 00 00 00 00 00 00 00 00 90"),
            ("Filter", "AA 19 00 FF FF 06 00 41 00 00 00 00 00 00 00 00 00 00 00 F4"),
            ("Event", "EE AA 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 44"),
        ]
        assertPackets(values)

        XCTAssertEqual(try packet(values[0].1).payload[1], 0x00)
        XCTAssertEqual(try packet(values[1].1).payload[1], 0x01)
        XCTAssertEqual(try ascii(packet(values[3].1).payload.dropFirst()), "1.00.16")
        XCTAssertEqual(try packet(values[4].1).payload[2 ... 7].map { $0 }, [0xE8, 0x06, 0x90, 0x0C, 0xE7, 0x8A])
        XCTAssertEqual(try packet(values[5].1).payload[3], 50)
        XCTAssertEqual(try packet(values[9].1).id, .event)
    }

    // MARK: - H7135 Heater

    func testHeaterCommands() {
        // Govee app -> ihoment_H7135_9F73, decrypted, matched to recorded actions
        let values: [(String, String)] = [
            ("Power off", "33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32"),
            ("Power on", "33 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 33"),
            ("Low", "3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            ("Medium", "3A 05 01 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C"),
            ("High", "3A 05 01 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            ("Fan", "3A 05 09 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 36"),
            ("Auto", "3A 05 03 00 80 19 C8 00 00 00 00 00 00 00 00 00 00 00 00 6D"),
            ("Display off", "33 16 00 FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00 25"),
            ("Display on", "33 16 01 FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00 24"),
            ("Lock on", "33 1F 02 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2F"),
            ("Lock off", "33 1F 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2E"),
        ]
        assertPackets(values)

        // Power on is the same command as for lights
        XCTAssertEqual(GoveeCommand.power(true).packet, try packet(values[1].1))
        XCTAssertEqual(GoveeCommand.power(false).packet, try packet(values[0].1))
    }

    func testHeaterStatus() throws {
        // ihoment_H7135_9F73 -> Govee app, decrypted
        let status = try packet("AA 01 01 00 00 00 01 03 B3 CF 00 00 00 00 00 00 00 00 00 D4")
        XCTAssertEqual(status.payload[1], 0x01) // on

        // Linked thermometer reading, same encoding as thermometer advertisements: 24.26 °C, 63.9 %
        let reading = bigEndian(status.payload[6 ... 8])
        XCTAssertEqual(reading, 0x03B3CF)
        XCTAssertEqual(Float(reading) / 10000, 24.2639, accuracy: 0.0001)
        XCTAssertEqual(Float(reading % 1000) / 10, 63.9, accuracy: 0.01)

        let firmware = try packet("AA 06 31 2E 30 30 2E 33 30 00 00 00 00 00 00 00 00 00 00 9E")
        XCTAssertEqual(ascii(firmware.payload.dropFirst()), "1.00.30")
    }

    // MARK: - H7173 Kettle

    func testKettleCommands() {
        // Govee app -> GVH71732ADB, decrypted, matched to a screen recording of the app
        let values: [(String, String)] = [
            ("Target 111 °F", "3A 05 00 05 2B 5C 00 00 00 00 00 00 00 00 00 00 00 00 00 4D"),
            ("Target 174 °F", "3A 05 00 05 43 F8 00 00 00 00 00 00 00 00 00 00 00 00 00 81"),
            ("Boiling", "3A 05 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            ("Green tea", "3A 05 00 03 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3D"),
            ("Black tea", "3A 05 00 03 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3E"),
            ("Oolong tea", "3A 05 00 03 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            ("Coffee1", "3A 05 00 04 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3A"),
            ("Custom1", "3A 05 00 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            ("Keep warm off", "3A 22 00 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 24"),
            ("Keep warm on", "3A 22 01 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 25"),
            ("Start", "33 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 33"),
            ("Cancel", "33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32"),
        ]
        assertPackets(values)

        // Temperatures are °F × 100, big endian
        XCTAssertEqual(try bigEndian(packet(values[0].1).payload[3 ... 4]), 11100)
        XCTAssertEqual(try bigEndian(packet(values[1].1).payload[3 ... 4]), 17400)
        // Keep warm duration in minutes
        XCTAssertEqual(try packet(values[9].1).payload[3], 60)
    }

    func testKettleStatus() throws {
        // GVH71732ADB -> Govee app, decrypted
        let idle = try packet("AA 00 00 00 01 36 4C 01 00 00 00 00 00 00 00 00 00 00 00 D0")
        XCTAssertEqual(idle.payload[1], 0x00)
        XCTAssertEqual(bigEndian(idle.payload[4 ... 5]), 13900) // 139 °F, as shown in the app

        let heating = try packet("AA 00 01 00 01 37 14 01 01 00 00 00 00 00 00 00 00 00 00 89")
        XCTAssertEqual(heating.payload[1], 0x01)
        XCTAssertEqual(bigEndian(heating.payload[4 ... 5]), 14100) // 141 °F

        let mode = try packet("AA 05 00 05 43 F8 00 00 00 00 00 00 00 00 00 00 00 00 00 11")
        XCTAssertEqual(mode.payload[2], 0x05)
        XCTAssertEqual(bigEndian(mode.payload[3 ... 4]), 17400)

        // Tea presets, page 0: Green 180 °F and Black 212 °F, both built in (bit 15 set)
        let tea = try packet("AA 05 03 00 C6 50 01 00 D2 D0 02 00 01 00 00 00 00 00 00 3A")
        let green = bigEndian(tea.payload[3 ... 4])
        let black = bigEndian(tea.payload[7 ... 8])
        XCTAssertEqual(green & 0x7FFF, 18000)
        XCTAssertEqual(black & 0x7FFF, 21200)
        XCTAssertNotEqual(green & 0x8000, 0)
        XCTAssertEqual(tea.payload[5], 0x01)
        XCTAssertEqual(tea.payload[9], 0x02)

        // Tea presets, page 1: Oolong 195 °F, editable; second slot empty
        let tea1 = try packet("AA 05 03 01 4C 2C 03 00 FF FF FF FF 01 00 00 00 00 00 00 CF")
        XCTAssertEqual(bigEndian(tea1.payload[3 ... 4]), 19500)
        XCTAssertEqual(Array(tea1.payload[7 ... 10]), [0xFF, 0xFF, 0xFF, 0xFF])

        // Coffee presets: Coffee1 205 °F
        let coffee = try packet("AA 05 04 00 50 14 01 00 FF FF FF FF 01 00 00 00 00 00 00 EF")
        XCTAssertEqual(bigEndian(coffee.payload[3 ... 4]), 20500)

        // Keep warm on, 60 minutes
        let keepWarm = try packet("AA 22 01 00 3C 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 89")
        XCTAssertEqual(keepWarm.payload[1], 0x01)
        XCTAssertEqual(keepWarm.payload[3], 60)

        let firmware = try packet("AA 06 31 2E 30 30 2E 32 34 00 00 00 00 00 00 00 00 00 00 9B")
        XCTAssertEqual(ascii(firmware.payload.dropFirst()), "1.00.24")
    }
}

// MARK: - Helpers

private extension CapturedPacketTests {

    struct InvalidPacket: Error { let hex: String }

    func packet(_ hex: String) throws -> GoveePacket {
        let bytes = hex.split(separator: " ").compactMap { UInt8($0, radix: 16) }
        guard let packet = GoveePacket(bytes: bytes) else {
            throw InvalidPacket(hex: hex)
        }
        return packet
    }

    /// Asserts each captured frame parses, has a valid checksum and round trips.
    func assertPackets(_ values: [(String, String)], file: StaticString = #filePath, line: UInt = #line) {
        for (name, hex) in values {
            let bytes = hex.split(separator: " ").compactMap { UInt8($0, radix: 16) }
            XCTAssertEqual(bytes.count, GoveePacket.length, name, file: file, line: line)
            guard let packet = GoveePacket(bytes: bytes) else {
                XCTFail("\(name): invalid packet \(hex)", file: file, line: line)
                continue
            }
            XCTAssertEqual(packet.bytes, bytes, name, file: file, line: line)
            XCTAssertEqual(packet.description, hex.replacingOccurrences(of: " ", with: ""), name, file: file, line: line)
            XCTAssertEqual(GoveePacket(id: packet.id, payload: packet.payload), packet, name, file: file, line: line)
        }
    }

    func bigEndian<C: Collection>(_ bytes: C) -> UInt32 where C.Element == UInt8 {
        bytes.reduce(0) { $0 << 8 | UInt32($1) }
    }

    func ascii<C: Collection>(_ bytes: C) -> String where C.Element == UInt8 {
        String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
}
