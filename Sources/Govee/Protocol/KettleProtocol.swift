//
//  KettleProtocol.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

// H7173 kettle commands and status, decrypted from Govee app captures. See Docs/BLE-Protocol.md.

public extension GoveeAccessory.Kettle {

    /// Kettle preset category.
    enum PresetCategory: UInt8, CaseIterable, Sendable {

        case diy        = 0x01
        case tea        = 0x03
        case coffee     = 0x04
    }

    /// Kettle command.
    enum Command: Equatable, Hashable, Sendable, GoveeRequest {

        /// Start or cancel heating (`33 01`).
        case heating(Bool)

        /// Set a target temperature in degrees Fahrenheit (`3A 05 00 05`).
        case targetTemperature(fahrenheit: Float)

        /// Select the boiling preset, 212 °F (`3A 05 00 02`).
        case boil

        /// Select a stored preset (`3A 05 00 <category> <index>`).
        case preset(PresetCategory, index: UInt8)

        /// Turn keep warm on or off for a number of minutes (`3A 22`).
        case keepWarm(Bool, minutes: UInt8)
    }

    /// Kettle status from an `AA 00` reply.
    struct Status: Equatable, Hashable, Sendable {

        /// Whether the kettle is heating.
        public let isHeating: Bool

        /// Current water temperature in degrees Fahrenheit.
        public let temperature: Float
    }
}

public extension GoveeAccessory.Kettle.Command {

    var packet: GoveePacket {
        switch self {
        case let .heating(isOn):
            return GoveeCommand.power(isOn).packet
        case let .targetTemperature(fahrenheit):
            let value = UInt16(clamping: Int((fahrenheit * 100).rounded()))
            return GoveePacket(id: .applianceCommand, payload: [0x05, 0x00, 0x05, UInt8(value >> 8), UInt8(value & 0xFF)])!
        case .boil:
            return GoveePacket(id: .applianceCommand, payload: [0x05, 0x00, 0x02, 0x00])!
        case let .preset(category, index):
            return GoveePacket(id: .applianceCommand, payload: [0x05, 0x00, category.rawValue, index])!
        case let .keepWarm(isOn, minutes):
            return GoveePacket(id: .applianceCommand, payload: [0x22, isOn ? 0x01 : 0x00, 0x00, minutes])!
        }
    }
}

// MARK: - Queries

public extension GoveeQuery {

    /// `AA 00`, kettle heating state and water temperature.
    static var kettleStatus: GoveeQuery { GoveeQuery([0x00]) }

    /// `AA 22`, kettle keep warm.
    static var kettleKeepWarm: GoveeQuery { GoveeQuery([0x22]) }
}

public extension GoveePacket {

    /// Kettle status from an `AA 00` reply.
    var kettleStatus: GoveeAccessory.Kettle.Status? {
        guard id == .status, payload[0] == 0x00 else {
            return nil
        }
        let temperature = UInt16(payload[4]) << 8 | UInt16(payload[5])
        return .init(isHeating: payload[1] != 0x00, temperature: Float(temperature) / 100)
    }

    /// Keep warm state and minutes from an `AA 22` reply.
    var kettleKeepWarm: (isOn: Bool, minutes: UInt8)? {
        guard id == .status, payload[0] == 0x22 else {
            return nil
        }
        return (payload[1] != 0x00, payload[3])
    }
}
