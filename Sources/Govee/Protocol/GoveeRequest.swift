//
//  GoveeRequest.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Bluetooth

/// Govee Request
///
/// A packet sent to a device, and the GATT channel it is sent on. The device answers with a
/// packet that echoes bytes 0 and 1.
public protocol GoveeRequest: Sendable {

    /// Packet to send.
    var packet: GoveePacket { get }

    /// Channel to send the packet on.
    var channel: GoveeChannel { get }
}

public extension GoveeRequest {

    var channel: GoveeChannel { .control }
}

extension GoveePacket: GoveeRequest {

    public var packet: GoveePacket { self }
}

// MARK: - Channel

/// Govee GATT Channel
///
/// A characteristic pair used to send packets and receive replies.
public enum GoveeChannel: CaseIterable, Sendable {

    /// Control service: write `…2b11`, notify `…2b10`. Appliances use it for everything; all devices use it for the encryption handshake.
    case control

    /// `INTELLI_ROCKS_HW` service `…2011`. Thermometer setup and settings.
    case setup

    /// `INTELLI_ROCKS_HW` service `…2012`. Thermometer live readings and history requests.
    case data
}

public extension GoveeChannel {

    var service: BluetoothUUID {
        switch self {
        case .control:
            return .goveeControlService
        case .setup, .data:
            return .goveeThermostat
        }
    }

    /// Characteristic written to.
    var write: BluetoothUUID {
        switch self {
        case .control:
            return .goveeControlWrite
        case .setup:
            return .goveeSetup
        case .data:
            return .goveeData
        }
    }

    /// Characteristic replies arrive on.
    var notify: BluetoothUUID {
        switch self {
        case .control:
            return .goveeControlNotify
        case .setup:
            return .goveeSetup
        case .data:
            return .goveeData
        }
    }
}

// MARK: - Query

/// Govee Status Query (`AA …`)
public struct GoveeQuery: GoveeRequest, Equatable, Hashable {

    /// Bytes after `AA`.
    public let parameters: [UInt8]

    public let channel: GoveeChannel

    public init(_ parameters: [UInt8], channel: GoveeChannel = .control) {
        precondition(parameters.count <= GoveePacket.payloadLength)
        self.parameters = parameters
        self.channel = channel
    }

    public var packet: GoveePacket {
        GoveePacket(id: .status, payload: parameters)!
    }
}

public extension GoveeQuery {

    /// `AA 01`, power state on appliances.
    static var power: GoveeQuery { GoveeQuery([0x01]) }

    /// `AA 06`, firmware version on appliances.
    static var firmwareVersion: GoveeQuery { GoveeQuery([0x06]) }
}

// MARK: - Reply Parsing

public extension GoveePacket {

    /// Whether this packet is a reply to the specified request.
    func isReply(to request: GoveePacket) -> Bool {
        id == request.id && payload.first == request.payload.first
    }

    /// Power state from an `AA 01` reply on appliances.
    var power: Bool? {
        guard id == .status, payload.first == 0x01 else {
            return nil
        }
        return payload[1] != 0x00
    }

    /// ASCII version string from an `AA 06` reply.
    var firmwareVersion: String? {
        guard id == .status, payload.first == 0x06 else {
            return nil
        }
        return String(decoding: payload.dropFirst().prefix { $0 != 0x00 }, as: UTF8.self)
    }
}

// MARK: - Security

/// Govee BLE Security
public enum GoveeSecurity: Equatable, Hashable, Sendable {

    /// Plaintext packets.
    case plaintext

    /// v1 encryption after an `E7` handshake.
    case encrypted
}

extension GoveeSecurity: CustomStringConvertible {

    public var description: String {
        switch self {
        case .plaintext:
            return "plaintext"
        case .encrypted:
            return "encrypted"
        }
    }
}

public extension GoveeModel {

    /// Security observed for this model's GATT connection.
    ///
    /// Only models captured so far are marked encrypted; unknown models default to plaintext.
    var security: GoveeSecurity {
        switch self {
        case .h7135, .h7173, .h5072:
            return .encrypted
        default:
            return .plaintext
        }
    }
}
