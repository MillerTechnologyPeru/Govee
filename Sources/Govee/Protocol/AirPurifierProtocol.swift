//
//  AirPurifierProtocol.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

// H712C purifier commands and status, from Govee app captures. See Docs/BLE-Protocol.md.

public extension GoveeAccessory.AirPurifier {

    /// Air purifier fan mode.
    enum Mode: Equatable, Hashable, Sendable {

        /// Manual fan speed, 1 (low) to 3 (high).
        case manual(speed: UInt8)

        /// Sleep mode.
        case sleep

        /// Turbo mode.
        case turbo

        /// Unrecognized mode and value.
        case unknown(mode: UInt8, value: UInt8)
    }

    /// Air purifier command.
    enum Command: Equatable, Hashable, Sendable, GoveeRequest {

        /// Turn on or off (`33 01`).
        case power(Bool)

        /// Set the fan mode (`3A 05`).
        case mode(Mode)

        /// Turn the night light on or off (`3A 1B 01 01`).
        case nightLight(Bool)

        /// Set the night light brightness in percent (`3A 1B 01 02`).
        case nightLightBrightness(UInt8)

        /// Set the night light color (`3A 1B 05 0D`).
        case nightLightColor(red: UInt8, green: UInt8, blue: UInt8)

        /// Turn the display on (always) or off (`33 16`).
        case display(Bool)
    }
}

public extension GoveeAccessory.AirPurifier.Mode {

    init(mode: UInt8, value: UInt8) {
        switch (mode, value) {
        case (0x01, 1 ... 3):
            self = .manual(speed: value)
        case (0x05, _):
            self = .sleep
        case (0x07, _):
            self = .turbo
        default:
            self = .unknown(mode: mode, value: value)
        }
    }

    /// Mode and value bytes.
    var bytes: (mode: UInt8, value: UInt8) {
        switch self {
        case let .manual(speed):
            return (0x01, speed)
        case .sleep:
            return (0x05, 0x00)
        case .turbo:
            return (0x07, 0x00)
        case let .unknown(mode, value):
            return (mode, value)
        }
    }
}

public extension GoveeAccessory.AirPurifier.Command {

    var packet: GoveePacket {
        switch self {
        case let .power(isOn):
            return GoveeCommand.power(isOn).packet
        case let .mode(mode):
            let bytes = mode.bytes
            return GoveePacket(id: .applianceCommand, payload: [0x05, bytes.mode, bytes.value])!
        case let .nightLight(isOn):
            return GoveePacket(id: .applianceCommand, payload: [0x1B, 0x01, 0x01, isOn ? 0x01 : 0x00])!
        case let .nightLightBrightness(percent):
            return GoveePacket(id: .applianceCommand, payload: [0x1B, 0x01, 0x02, min(percent, 100)])!
        case let .nightLightColor(red, green, blue):
            return GoveePacket(id: .applianceCommand, payload: [0x1B, 0x05, 0x0D, red, green, blue])!
        case let .display(isOn):
            // always on: window 00:00 to 23:59, flag 01
            return GoveePacket(id: .command, payload: [0x16, isOn ? 0x01 : 0x00, 0x00, 0x00, 0x17, 0x3B, 0x01])!
        }
    }
}

// MARK: - Queries

public extension GoveeQuery {

    /// `AA 05 00`, current purifier mode.
    static var airPurifierMode: GoveeQuery { GoveeQuery([0x05, 0x00]) }

    /// `AA 05 01`, purifier manual fan speed.
    static var airPurifierManualSpeed: GoveeQuery { GoveeQuery([0x05, 0x01]) }

    /// `AA 1B 01`, purifier night light state and brightness.
    static var airPurifierNightLight: GoveeQuery { GoveeQuery([0x1B, 0x01]) }

    /// `AA 1B 05`, purifier night light color.
    static var airPurifierNightLightColor: GoveeQuery { GoveeQuery([0x1B, 0x05]) }
}

public extension GoveePacket {

    /// Raw purifier mode from an `AA 05 00` reply (`01` manual, `05` sleep, `07` turbo).
    ///
    /// The reply does not carry the manual speed; combine with ``airPurifierManualSpeed`` using
    /// ``GoveeAccessory/AirPurifier/Mode/init(mode:value:)``.
    var airPurifierMode: UInt8? {
        guard id == .status, payload[0] == 0x05, payload[1] == 0x00 else {
            return nil
        }
        return payload[2]
    }

    /// Manual fan speed (1 to 3) from an `AA 05 01` reply.
    var airPurifierManualSpeed: UInt8? {
        guard id == .status, payload[0] == 0x05, payload[1] == 0x01 else {
            return nil
        }
        return payload[2]
    }

    /// Night light state and brightness in percent from an `AA 1B 01` reply.
    var airPurifierNightLight: (isOn: Bool, brightness: UInt8)? {
        guard id == .status, payload[0] == 0x1B, payload[1] == 0x01 else {
            return nil
        }
        return (payload[2] != 0x00, payload[3])
    }

    /// Night light color from an `AA 1B 05` reply.
    var airPurifierNightLightColor: (red: UInt8, green: UInt8, blue: UInt8)? {
        guard id == .status, payload[0] == 0x1B, payload[1] == 0x05 else {
            return nil
        }
        return (payload[3], payload[4], payload[5])
    }
}
