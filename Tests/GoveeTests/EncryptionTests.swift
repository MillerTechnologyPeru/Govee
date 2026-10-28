//
//  EncryptionTests.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import XCTest
@testable import Govee

final class EncryptionTests: XCTestCase {

    // MARK: - Primitives

    func testAESKnownAnswer() {
        // FIPS-197 Appendix C.1 and Appendix B
        let values: [(key: String, plaintext: String, ciphertext: String)] = [
            ("000102030405060708090a0b0c0d0e0f", "00112233445566778899aabbccddeeff", "69c4e0d86a7b0430d8cdb78070b4c55a"),
            ("2b7e151628aed2a6abf7158809cf4f3c", "3243f6a8885a308d313198a2e0370734", "3925841d02dc09fbdc118597196a0b32"),
        ]
        for (key, plaintext, ciphertext) in values {
            guard let aes = AES128(key: hex(key)) else {
                XCTFail()
                return
            }
            XCTAssertEqual(aes.encrypt(block: hex(plaintext)), hex(ciphertext))
            XCTAssertEqual(aes.decrypt(block: hex(ciphertext)), hex(plaintext))
        }
        XCTAssertNil(AES128(key: [UInt8](repeating: 0, count: 15)))
        XCTAssertNil(AES128(key: [UInt8](repeating: 0, count: 32)))
    }

    func testRC4KnownAnswer() {
        // Keystream test vectors from the original RC4 publications
        let values: [(key: String, keystream: String)] = [
            ("Key", "eb9f7781b734ca72a719"),
            ("Wiki", "6044db6d41b7"),
            ("Secret", "04d46b053ca87b59"),
        ]
        for (key, keystream) in values {
            var rc4 = RC4(key: Array(key.utf8))
            XCTAssertEqual(rc4.keystream(count: keystream.count / 2), hex(keystream), key)
        }
    }

    func testCommunicationKey() {
        // Hardcoded in the Govee app; see Docs/BLE-Protocol.md
        XCTAssertEqual(GoveeEncryptionKey.communication.rawValue, Array("MakingLifeSmarte".utf8))
        XCTAssertNil(GoveeEncryptionKey([UInt8](repeating: 0, count: 15)))
    }

    // MARK: - Captured Sessions

    func testHeaterSession() throws {
        // PacketLogger capture of the Govee app and ihoment_H7135_9F73, 2026-10-28
        let session = try assertHandshake(
            request: (
                "C6 66 95 08 46 4A ED CE B6 AF EE B4 C8 9C 3F C7 72 D4 4A 65",
                "E7 01 E6 BB 24 6D D5 C7 5A 85 D5 8F 19 9B E4 13 1A 3A 0A 3A"
            ),
            reply: (
                "DB 74 E3 82 34 CA 4D A4 B4 AD 62 A7 0A 32 BB 5F 22 99 4A F3",
                "E7 01 D0 FD 2A 58 85 B2 E0 0D 3A 67 95 C2 EF 1D 4A 77 0A AC"
            ),
            sessionKey: "D0 FD 2A 58 85 B2 E0 0D 3A 67 95 C2 EF 1D 4A 77",
            confirm: (
                "BB FB EF 8A EF 02 2C EE 81 CB 07 AE C4 28 9F 98 BC C1 6C 38",
                "E7 02 AA 41 17 35 9B 7F DB 0E DF DC 1D 5B 0D E5 D4 2F 2C 67"
            )
        )

        // Status sent on connect, before the handshake, with the communication key
        assertFrames([
            ("90 46 96 31 31 2D FD E3 CF 3E 2C 24 3E 79 E4 53 68 EE 40 8B", "AA 01 01 00 00 00 01 03 B3 CF 00 00 00 00 00 00 00 00 00 D4"),
        ], key: .communication)

        assertFrames([
            // Status query
            ("0A B8 02 02 E7 93 10 11 C7 A0 90 8D 0E A8 4D FC 87 53 32 C0", "AA 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AB"),
            // Power on
            ("75 40 5D 78 F6 4A B7 78 DF 23 31 51 2E 57 2D 07 87 53 32 58", "33 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 33"),
            // Low
            ("2D 11 CC 6E DF 20 62 3C 04 BA B8 65 0B D9 B1 3F 87 53 32 54", "3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F"),
            // Fan
            ("A8 88 C1 90 38 5D 70 CA DC 8F 50 6A 67 1A 91 B5 87 53 32 5D", "3A 05 09 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 36"),
        ], key: session)

        // The library's own command encrypts to what the app sent
        XCTAssertEqual(
            GoveeCommand.power(true).packet.encrypted(with: session),
            hex("75 40 5D 78 F6 4A B7 78 DF 23 31 51 2E 57 2D 07 87 53 32 58")
        )
    }

    func testKettleSession() throws {
        // PacketLogger capture of the Govee app and GVH71732ADB, 2026-10-28
        let session = try assertHandshake(
            request: (
                "AD FD AE 99 A1 49 7D E0 87 8D 10 2B D3 52 99 CF B6 48 BB C1",
                "E7 01 9A 26 BF B8 61 EA F0 06 75 40 D6 24 C5 3F DE A6 FB 9E"
            ),
            reply: (
                "54 96 9E FC D9 4C A9 FA 4D 85 C2 6E A9 32 E9 90 D0 0B BB 69",
                "E7 01 3D 6B 98 C5 F3 20 4D 7B A8 D5 02 30 5D 8A B8 E5 FB 36"
            ),
            sessionKey: "3D 6B 98 C5 F3 20 4D 7B A8 D5 02 30 5D 8A B8 E5",
            confirm: (
                "A7 76 4E 17 FF 52 82 DE F1 48 8E E4 DA 20 84 51 0B 1E 70 22",
                "E7 02 E1 FA 9B 28 B3 23 C0 47 3E 24 9D B2 11 A0 63 F0 30 7D"
            )
        )
        assertFrames([
            // Status: idle, 139 °F
            ("D3 FD 15 0C 43 72 FA 1B 6A 93 57 CB 77 35 FD E2 90 DB 17 25", "AA 00 00 00 01 36 4C 01 00 00 00 00 00 00 00 00 00 00 00 D0"),
            // Target 111 °F
            ("C4 6A 6E DB 81 6B 42 7D A0 5A 42 08 D4 2E 29 36 90 DB 17 B8", "3A 05 00 05 2B 5C 00 00 00 00 00 00 00 00 00 00 00 00 00 4D"),
            // Keep warm on, 60 minutes
            ("2A 61 FD 20 A9 34 5E B9 B8 99 EC 23 29 91 DD 5A 90 DB 17 D0", "3A 22 01 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 25"),
        ], key: session)
    }

    func testThermometerSession() throws {
        // PacketLogger capture of the Govee app and GVH5072_CF9C, 2026-10-28
        let session = try assertHandshake(
            request: (
                "A6 50 D4 A2 67 BB DC 70 FA 3A 07 01 E2 FE 6C 9D B3 16 4A 85",
                "E7 01 52 E5 79 C4 30 E3 16 AD 99 4E A6 53 95 C0 DB F8 0A DA"
            ),
            reply: (
                "58 32 84 80 B6 B1 F3 00 8E E0 CB 66 6E DF 89 7F 65 C3 40 02",
                "E7 01 CA A2 7E 2B 8B AF F4 C5 B1 58 7F 92 3F 88 0D 2D 00 5D"
            ),
            sessionKey: "CA A2 7E 2B 8B AF F4 C5 B1 58 7F 92 3F 88 0D 2D",
            confirm: (
                "76 6F C3 DF A1 65 D3 82 AB 03 B4 D8 B0 6B D9 D4 1B 45 7A 2C",
                "E7 02 49 4A 76 67 26 D6 CB 22 EC 3D 0E 0C 3D 91 73 AB 3A 73"
            )
        )

        // The device's E7 02 reply differs from the request, unlike the appliances
        let confirmReply = "1C 46 0E 7A 43 29 A1 00 6E 41 E6 E7 31 16 C9 5C 84 37 09 5E"
        let confirmed = try XCTUnwrap(GoveePacket(encrypted: hex(confirmReply), key: .communication))
        XCTAssertEqual(confirmed.bytes, hex("E7 02 8C BC 70 6D B8 B5 5E E1 41 D9 9E 63 43 21 EC D9 49 01"))
        XCTAssertNil(confirmed.sessionKey)

        assertFrames([
            // Set clock
            ("79 73 CF 21 6F AE 7D E7 EB FD EF 6D F7 9C 76 4E EB 98 3A 43", "33 10 76 0A C8 01 00 00 00 00 00 00 00 00 00 00 00 00 00 96"),
            // Live reading: 24.30 °C, 63.81 %, battery 37 %
            ("A4 13 51 E5 57 92 E3 F0 4B 4C B6 CB CE A6 6A 21 EB 98 3A D9", "AA 01 09 7E 18 ED 25 00 00 00 00 00 00 00 00 00 00 00 00 0C"),
        ], key: session)

        // History frames use all 20 bytes and have no checksum
        let history = hex("B7 3F C8 E8 87 79 19 C7 47 D1 6D C9 2A 05 C0 44 D4 9B 4F 95")
        let decrypted = hex("01 2B 03 71 57 03 71 57 03 75 3F 03 75 40 03 75 3F 03 75 40")
        XCTAssertEqual(session.decrypt(history), decrypted)
        XCTAssertEqual(session.encrypt(decrypted), history)
        XCTAssertNil(GoveePacket(encrypted: history, key: session))
    }

    // MARK: - Negotiation

    func testNegotiationRequest() throws {
        // Rebuild the app's captured E7 01 request from its random bytes
        let random = hex("E6 BB 24 6D D5 C7 5A 85 D5 8F 19 9B E4 13 1A 3A 0A")
        let request = try XCTUnwrap(GoveePacket.negotiation(.sessionKey, random: random))
        XCTAssertEqual(request.encrypted(with: .communication), hex("C6 66 95 08 46 4A ED CE B6 AF EE B4 C8 9C 3F C7 72 D4 4A 65"))

        XCTAssertNil(GoveePacket.negotiation(.sessionKey, random: [UInt8](repeating: 0, count: 16)))
        let generated = GoveePacket.negotiation(.confirm)
        XCTAssertEqual(generated.id, .negotiation)
        XCTAssertEqual(generated.payload[0], 0x02)
        XCTAssertEqual(GoveePacket(encrypted: generated.encrypted(with: .communication), key: .communication), generated)
    }

    func testInvalidFrames() {
        let key = GoveeEncryptionKey.communication
        XCTAssertNil(key.encrypt([UInt8](repeating: 0, count: 19)))
        XCTAssertNil(key.decrypt([UInt8](repeating: 0, count: 21)))
        // Wrong key: decrypts to garbage that fails the checksum
        let ciphertext = hex("0A B8 02 02 E7 93 10 11 C7 A0 90 8D 0E A8 4D FC 87 53 32 C0")
        XCTAssertNil(GoveePacket(encrypted: ciphertext, key: key))
    }
}

// MARK: - Helpers

private extension EncryptionTests {

    func hex(_ string: String) -> [UInt8] {
        let digits = string.filter { $0.isHexDigit }
        return stride(from: 0, to: digits.count, by: 2).map {
            let start = digits.index(digits.startIndex, offsetBy: $0)
            return UInt8(digits[start ..< digits.index(start, offsetBy: 2)], radix: 16)!
        }
    }

    /// Asserts each ciphertext decrypts to the plaintext packet and the packet encrypts back to the ciphertext.
    func assertFrames(_ values: [(ciphertext: String, plaintext: String)], key: GoveeEncryptionKey, file: StaticString = #filePath, line: UInt = #line) {
        for (ciphertext, plaintext) in values {
            guard let packet = GoveePacket(encrypted: hex(ciphertext), key: key) else {
                XCTFail("Unable to decrypt \(ciphertext)", file: file, line: line)
                continue
            }
            XCTAssertEqual(packet.bytes, hex(plaintext), file: file, line: line)
            XCTAssertEqual(packet.encrypted(with: key), hex(ciphertext), file: file, line: line)
        }
    }

    /// Asserts the captured handshake and returns the session key it negotiated.
    func assertHandshake(
        request: (ciphertext: String, plaintext: String),
        reply: (ciphertext: String, plaintext: String),
        sessionKey: String,
        confirm: (ciphertext: String, plaintext: String),
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> GoveeEncryptionKey {
        assertFrames([request, reply, confirm], key: .communication, file: file, line: line)
        let requestPacket = try XCTUnwrap(GoveePacket(encrypted: hex(request.ciphertext), key: .communication), file: file, line: line)
        XCTAssertEqual(requestPacket.id, .negotiation, file: file, line: line)
        let replyPacket = try XCTUnwrap(GoveePacket(encrypted: hex(reply.ciphertext), key: .communication), file: file, line: line)
        let session = try XCTUnwrap(replyPacket.sessionKey, file: file, line: line)
        XCTAssertEqual(session.rawValue, hex(sessionKey), file: file, line: line)
        return session
    }
}
