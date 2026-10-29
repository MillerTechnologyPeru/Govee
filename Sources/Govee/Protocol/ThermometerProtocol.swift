//
//  ThermometerProtocol.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation

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

    /// One minute of stored history, from a `…2013` history frame.
    struct HistoryReading: Equatable, Hashable, Sendable {

        /// Minutes before the download.
        public let minutesAgo: UInt16

        /// Temperature in degrees Celsius.
        public let temperature: Float

        /// Relative humidity in percent.
        public let humidity: Float
    }

    /// Thermometer history commands, written to the data channel.
    enum Command: Equatable, Hashable, Sendable, GoveeRequest {

        /// `33 02 00`, sent by the Govee app before each history request. Meaning unknown.
        case prepareHistory

        /// `33 01 <minutes, 2 bytes BE>`, stream the readings of the last `minutes` minutes.
        case history(minutes: UInt16)
    }
}

public extension GoveeAccessory.Thermometer.Command {

    var packet: GoveePacket {
        switch self {
        case .prepareHistory:
            return GoveePacket(id: .command, payload: [0x02, 0x00])!
        case let .history(minutes):
            return GoveePacket(id: .command, payload: [0x01, UInt8(minutes >> 8), UInt8(minutes & 0xFF)])!
        }
    }

    var channel: GoveeChannel { .data }
}

public extension GoveeAccessory.Thermometer.HistoryReading {

    /// Decodes a decrypted history frame: minutes back (2 bytes, big endian), then up to six
    /// 3-byte readings in the advertisement encoding, one minute apart. Unused readings are `FF FF FF`.
    static func decode(frame: [UInt8]) -> [Self] {
        guard frame.count == GoveePacket.length else {
            return []
        }
        let start = UInt16(frame[0]) << 8 | UInt16(frame[1])
        return stride(from: 2, to: frame.count, by: 3).enumerated().compactMap { offset, index in
            let value = (frame[index], frame[index + 1], frame[index + 2])
            guard value != (0xFF, 0xFF, 0xFF), UInt16(offset) <= start else {
                return nil
            }
            let encoded = GoveeAccessory.Thermometer.ManufacturerData.EncodedTemperature(byteValue: value)
            return Self(
                minutesAgo: start - UInt16(offset),
                temperature: encoded.temperature,
                humidity: encoded.humidity
            )
        }
    }
}

// MARK: - Connection

public extension GoveeConnection {

    /// Downloads the thermometer's stored readings for the last `minutes` minutes, oldest first.
    ///
    /// - Parameter timeout: Time allowed for each reply, and between history frames.
    func thermometerHistory(
        minutes: UInt16,
        timeout: TimeInterval = 5
    ) async throws -> [GoveeAccessory.Thermometer.HistoryReading] {
        try await send(GoveeAccessory.Thermometer.Command.prepareHistory, timeout: timeout)
        let frames = try await download(GoveeAccessory.Thermometer.Command.history(minutes: minutes), timeout: timeout)
        return frames.flatMap { GoveeAccessory.Thermometer.HistoryReading.decode(frame: $0) }
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
