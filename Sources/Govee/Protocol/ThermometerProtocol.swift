//
//  ThermometerProtocol.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

// H5072 thermometer GATT protocol, decrypted from Govee app captures. See Docs/BLE-Protocol.md.

public extension GoveeAccessory.Thermometer {

    /// Live reading from an `AA 01` reply on the data channel.
    struct Reading: Equatable, Hashable, Sendable {

        /// Temperature in degrees Celsius.
        public let temperature: Float

        /// Relative humidity in percent.
        public let humidity: Float

        /// Battery level in percent.
        public let batteryLevel: UInt8
    }
}

// MARK: - Queries

public extension GoveeQuery {

    /// `AA 01` on the data channel, thermometer live reading.
    static var thermometerReading: GoveeQuery { GoveeQuery([0x01], channel: .data) }

    /// `AA 08` on the setup channel, thermometer battery level.
    static var thermometerBattery: GoveeQuery { GoveeQuery([0x08], channel: .setup) }

    /// `AA 0E` on the setup channel, thermometer firmware version.
    static var thermometerFirmwareVersion: GoveeQuery { GoveeQuery([0x0E], channel: .setup) }
}

public extension GoveePacket {

    /// Thermometer live reading from an `AA 01` reply on the data channel.
    var thermometerReading: GoveeAccessory.Thermometer.Reading? {
        guard id == .status, payload[0] == 0x01 else {
            return nil
        }
        let temperature = Int16(bitPattern: UInt16(payload[1]) << 8 | UInt16(payload[2]))
        let humidity = UInt16(payload[3]) << 8 | UInt16(payload[4])
        return .init(
            temperature: Float(temperature) / 100,
            humidity: Float(humidity) / 100,
            batteryLevel: payload[5]
        )
    }

    /// ASCII version from an `AA 0E` reply on the setup channel.
    var thermometerFirmwareVersion: String? {
        guard id == .status, payload.first == 0x0E else {
            return nil
        }
        return String(decoding: payload.dropFirst().prefix { $0 != 0x00 }, as: UTF8.self)
    }
}
