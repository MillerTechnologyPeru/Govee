//
//  HeaterProtocol.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

// H7135 heater commands and status, decrypted from Govee app captures. See Docs/BLE-Protocol.md.

public extension GoveeAccessory.Heater {

    /// Heater mode.
    enum Mode: Equatable, Hashable, Sendable {

        /// Heat at level 1 (low) to 3 (high).
        case heat(level: UInt8)

        /// Fan only, no heat.
        case fan
    }

    /// Heater command.
    ///
    /// Auto mode is not included; its target temperature encoding is not understood yet.
    enum Command: Equatable, Hashable, Sendable, GoveeRequest {

        /// Turn on or off (`33 01`).
        case power(Bool)

        /// Set the mode (`3A 05`).
        case mode(Mode)

        /// Turn the display on or off (`33 16`).
        case display(Bool)

        /// Lock or unlock the controls (`33 1F 02`).
        case lock(Bool)
    }
}

public extension GoveeAccessory.Heater.Command {

    var packet: GoveePacket {
        switch self {
        case let .power(isOn):
            return GoveeCommand.power(isOn).packet
        case let .mode(.heat(level)):
            return GoveePacket(id: .applianceCommand, payload: [0x05, 0x01, min(max(level, 1), 3)])!
        case .mode(.fan):
            return GoveePacket(id: .applianceCommand, payload: [0x05, 0x09, 0x00])!
        case let .display(isOn):
            return GoveePacket(id: .command, payload: [0x16, isOn ? 0x01 : 0x00, 0xFF, 0xFF, 0xFF, 0xFF])!
        case let .lock(isLocked):
            return GoveePacket(id: .command, payload: [0x1F, 0x02, isLocked ? 0x01 : 0x00])!
        }
    }
}

public extension GoveePacket {

    /// Linked Bluetooth thermometer reading from a heater's `AA 01` reply, in the thermometer advertisement encoding.
    var heaterThermometerReading: (temperature: Float, humidity: Float)? {
        guard id == .status, payload[0] == 0x01 else {
            return nil
        }
        let value = (payload[6], payload[7], payload[8])
        guard value != (0x00, 0x00, 0x00) else {
            return nil
        }
        let encoded = GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature(byteValue: value)
        return (encoded.temperature, encoded.humidity)
    }
}
