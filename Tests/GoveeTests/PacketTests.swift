//
//  PacketTests.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import XCTest
@testable import Govee

final class PacketTests: XCTestCase {

    func testPowerOnBytes() {
        // Source: HA forum H617A thread, hard-coded "on" packet
        let bytes: [UInt8] = [0x33, 0x01, 0x01] + [UInt8](repeating: 0x00, count: 16) + [0x33]
        guard let packet = GoveePacket(id: .command, payload: [0x01, 0x01]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(packet.bytes, bytes)
        XCTAssertEqual(packet.bytes.count, GoveePacket.length)
        XCTAssertEqual(packet.checksum, 0x33)
        XCTAssertEqual(GoveePacket(bytes: bytes), packet)
    }

    func testPowerOffBytes() {
        // Source: HA forum H617A thread, hard-coded "off" packet
        let bytes: [UInt8] = [0x33, 0x01, 0x00] + [UInt8](repeating: 0x00, count: 16) + [0x32]
        guard let packet = GoveePacket(id: .command, payload: [0x01, 0x00]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(packet.bytes, bytes)
        XCTAssertEqual(packet.checksum, 0x32)
        XCTAssertEqual(GoveePacket(bytes: bytes), packet)
    }

    func testChecksumIsXOR() {
        // Source: chvolkmann/govee_btled, white with warm color FF932C
        let bytes: [UInt8] = [0x33, 0x05, 0x02, 0xFF, 0xFF, 0xFF, 0x01, 0xFF, 0x93, 0x2C] + [UInt8](repeating: 0x00, count: 9) + [0x8A]
        let sum = UInt8(truncatingIfNeeded: bytes.prefix(19).reduce(0, { $0 + Int($1) }))
        XCTAssertEqual(sum, 0xF6)
        XCTAssertNotEqual(sum, 0x8A)
        guard let packet = GoveePacket(bytes: bytes) else {
            XCTFail()
            return
        }
        XCTAssertEqual(packet.checksum, 0x8A)
        XCTAssertEqual(packet.bytes, bytes)
        // a sum checksum must be rejected
        XCTAssertNil(GoveePacket(bytes: bytes.prefix(19) + [sum]))
    }

    func testParseRejectsWrongLength() {
        let bytes: [UInt8] = [0x33, 0x01, 0x01] + [UInt8](repeating: 0x00, count: 16) + [0x33]
        XCTAssertNotNil(GoveePacket(bytes: bytes))
        XCTAssertNil(GoveePacket(bytes: bytes.prefix(19)))
        XCTAssertNil(GoveePacket(bytes: bytes + [0x00]))
        XCTAssertNil(GoveePacket(bytes: []))
    }

    func testParseRejectsBadChecksum() {
        let bytes: [UInt8] = [0x33, 0x01, 0x01] + [UInt8](repeating: 0x00, count: 16) + [0x32]
        XCTAssertNil(GoveePacket(bytes: bytes))
    }

    func testPayloadTooLong() {
        XCTAssertNotNil(GoveePacket(id: .command, payload: [UInt8](repeating: 0x01, count: 18)))
        XCTAssertNil(GoveePacket(id: .command, payload: [UInt8](repeating: 0x01, count: 19)))
    }

    func testRoundTrip() {
        let values: [(packet: [UInt8], id: GoveePacket.ID)] = [
            // HA forum H617A thread, power on
            ([0x33, 0x01, 0x01] + [UInt8](repeating: 0x00, count: 16) + [0x33], .command),
            // HA forum H617A thread, power off
            ([0x33, 0x01, 0x00] + [UInt8](repeating: 0x00, count: 16) + [0x32], .command),
            // chvolkmann/govee_btled, white with warm color FF932C
            ([0x33, 0x05, 0x02, 0xFF, 0xFF, 0xFF, 0x01, 0xFF, 0x93, 0x2C] + [UInt8](repeating: 0x00, count: 9) + [0x8A], .command),
            // independently computed checksum, brightness 0x80
            ([0x33, 0x04, 0x80] + [UInt8](repeating: 0x00, count: 16) + [0xB7], .command),
            // independently computed checksum, status power on
            ([0xAA, 0x01, 0x01] + [UInt8](repeating: 0x00, count: 16) + [0xAA], .status),
        ]
        for (bytes, id) in values {
            guard let packet = GoveePacket(bytes: bytes) else {
                XCTFail("Unable to parse \(bytes.toHexadecimal())")
                continue
            }
            XCTAssertEqual(packet.id, id)
            XCTAssertEqual(packet.bytes, bytes)
            XCTAssertEqual(packet.data, Data(bytes))
            XCTAssertEqual(packet.description, bytes.toHexadecimal())
            XCTAssertEqual(GoveePacket(id: packet.id, payload: packet.payload), packet)
        }
    }
}
