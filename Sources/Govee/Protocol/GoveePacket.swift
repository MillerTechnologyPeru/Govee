//
//  GoveePacket.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation

/// Govee BLE Packet
///
/// Fixed 20 byte frame: `[id][payload (18 bytes, zero padded)][checksum]`
/// where the checksum is the XOR of bytes 0 to 18.
public struct GoveePacket: Equatable, Hashable, Sendable {

    /// Packet length.
    public static var length: Int { 20 }

    /// Maximum payload length.
    public static var payloadLength: Int { length - 2 }

    /// Packet identifier.
    public let id: ID

    /// Bytes 1 to 18, zero padded.
    public let payload: [UInt8]

    public init?(id: ID, payload: [UInt8]) {
        guard payload.count <= Self.payloadLength else {
            return nil
        }
        self.id = id
        self.payload = payload + [UInt8](repeating: 0x00, count: Self.payloadLength - payload.count)
    }

    /// Parse packet bytes.
    ///
    /// Returns `nil` unless the data is exactly 20 bytes with a valid checksum.
    public init?<C: Collection>(bytes: C) where C.Element == UInt8 {
        let bytes = [UInt8](bytes)
        guard bytes.count == Self.length,
              bytes[Self.length - 1] == Self.checksum(bytes.prefix(Self.length - 1)) else {
            return nil
        }
        self.id = ID(rawValue: bytes[0])
        self.payload = Array(bytes[1 ..< Self.length - 1])
    }
}

public extension GoveePacket {

    /// XOR of bytes 0 to 18.
    var checksum: UInt8 {
        payload.reduce(id.rawValue, ^)
    }

    /// Serialized packet bytes.
    var bytes: [UInt8] {
        [id.rawValue] + payload + [checksum]
    }

    /// Serialized packet data.
    var data: Data {
        Data(bytes)
    }
}

internal extension GoveePacket {

    static func checksum<C: Collection>(_ bytes: C) -> UInt8 where C.Element == UInt8 {
        bytes.reduce(0x00, ^)
    }
}

// MARK: - CustomStringConvertible

extension GoveePacket: CustomStringConvertible {

    public var description: String {
        bytes.toHexadecimal()
    }
}

// MARK: - Supporting Types

public extension GoveePacket {

    /// Govee Packet Identifier
    struct ID: RawRepresentable, Equatable, Hashable, Sendable {

        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
}

public extension GoveePacket.ID {

    /// Command
    static var command: GoveePacket.ID { GoveePacket.ID(rawValue: 0x33) }

    /// Status / Notification
    static var status: GoveePacket.ID { GoveePacket.ID(rawValue: 0xAA) }

    /// DIY
    static var diy: GoveePacket.ID { GoveePacket.ID(rawValue: 0xA1) }

    /// Multi-packet scene data
    static var multiPacket: GoveePacket.ID { GoveePacket.ID(rawValue: 0xA3) }
}

extension GoveePacket.ID: CustomStringConvertible {

    public var description: String {
        rawValue.toHexadecimal()
    }
}
