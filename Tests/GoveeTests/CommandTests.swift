//
//  CommandTests.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import XCTest
@testable import Govee

final class CommandTests: XCTestCase {

    func testPower() {
        // Source: HA forum H617A thread, hard-coded on and off packets
        XCTAssertEqual(GoveeCommand.power(true).packet.bytes, [0x33, 0x01, 0x01] + [UInt8](repeating: 0x00, count: 16) + [0x33])
        XCTAssertEqual(GoveeCommand.power(false).packet.bytes, [0x33, 0x01, 0x00] + [UInt8](repeating: 0x00, count: 16) + [0x32])
    }

    func testWhite() {
        // Source: chvolkmann/govee_btled, white with warm color FF932C
        let bytes: [UInt8] = [0x33, 0x05, 0x02, 0xFF, 0xFF, 0xFF, 0x01, 0xFF, 0x93, 0x2C] + [UInt8](repeating: 0x00, count: 9) + [0x8A]
        XCTAssertEqual(GoveeCommand.white(red: 0xFF, green: 0x93, blue: 0x2C).packet.bytes, bytes)
    }

    func testColor() {
        // Layout from chvolkmann/govee_btled, checksum computed independently
        // 33 ^ 05 ^ 02 ^ FF ^ 93 ^ 2C = 0x74
        let bytes: [UInt8] = [0x33, 0x05, 0x02, 0xFF, 0x93, 0x2C] + [UInt8](repeating: 0x00, count: 13) + [0x74]
        XCTAssertEqual(GoveeCommand.color(red: 0xFF, green: 0x93, blue: 0x2C).packet.bytes, bytes)
    }

    func testBrightnessBoundaries() {
        // checksums computed independently: 0x33 ^ 0x04 ^ value
        let values: [(UInt8, UInt8)] = [
            (0x00, 0x37),
            (0x01, 0x36),
            (0x7F, 0x48),
            (0x80, 0xB7),
            (0xFF, 0xC8),
        ]
        for (value, checksum) in values {
            let bytes: [UInt8] = [0x33, 0x04, value] + [UInt8](repeating: 0x00, count: 16) + [checksum]
            XCTAssertEqual(GoveeCommand.brightness(value).packet.bytes, bytes)
        }
    }

    func testAllCommandsAre20BytesWithValidChecksum() {
        var commands: [GoveeCommand] = [.power(true), .power(false)]
        for value in UInt8.min ... UInt8.max {
            commands.append(.brightness(value))
            commands.append(.color(red: value, green: ~value, blue: value &* 7))
            commands.append(.white(red: ~value, green: value, blue: value &* 13))
        }
        for command in commands {
            let bytes = command.packet.bytes
            XCTAssertEqual(bytes.count, 20)
            XCTAssertEqual(bytes[0], 0x33)
            XCTAssertEqual(bytes[1], command.opcode.rawValue)
            XCTAssertEqual(bytes[19], bytes.prefix(19).reduce(0, ^))
            XCTAssertEqual(GoveePacket(bytes: bytes), command.packet)
        }
    }
}
