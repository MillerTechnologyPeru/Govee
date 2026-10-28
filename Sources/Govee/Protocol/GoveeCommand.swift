//
//  GoveeCommand.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

/// Govee Command
///
/// Typed commands serialized as `0x33` packets.
/// Layouts follow `chvolkmann/govee_btled` and are unverified on hardware.
public enum GoveeCommand: Equatable, Hashable, Sendable {

    /// Turn on or off.
    case power(Bool)

    /// Set brightness.
    case brightness(UInt8)

    /// Set color in manual mode.
    case color(red: UInt8, green: UInt8, blue: UInt8)

    /// Set white in manual mode, tinted with the specified color.
    case white(red: UInt8, green: UInt8, blue: UInt8)
}

public extension GoveeCommand {

    /// Command identifier (byte 1 of the packet).
    var opcode: Opcode {
        switch self {
        case .power:
            return .power
        case .brightness:
            return .brightness
        case .color, .white:
            return .color
        }
    }

    /// Command parameters (bytes 2 to 18 of the packet).
    var parameters: [UInt8] {
        switch self {
        case let .power(isOn):
            return [isOn ? 0x01 : 0x00]
        case let .brightness(value):
            return [value]
        case let .color(red, green, blue):
            return [ColorMode.manual.rawValue, red, green, blue]
        case let .white(red, green, blue):
            return [ColorMode.manual.rawValue, 0xFF, 0xFF, 0xFF, 0x01, red, green, blue]
        }
    }

    /// Serialized packet.
    var packet: GoveePacket {
        guard let packet = GoveePacket(id: .command, payload: [opcode.rawValue] + parameters) else {
            fatalError("Invalid payload length for \(self)")
        }
        return packet
    }
}

// MARK: - Supporting Types

public extension GoveeCommand {

    /// Govee Command Opcode
    enum Opcode: UInt8, CaseIterable, Sendable {

        case power          = 0x01
        case brightness     = 0x04
        case color          = 0x05
    }

    /// Govee Color Mode
    enum ColorMode: UInt8, CaseIterable, Sendable {

        case manual         = 0x02
    }
}
