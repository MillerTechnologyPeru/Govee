//
//  AccessoryManagerConnection.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import Bluetooth
import GATT
import DarwinGATT
import Govee

// MARK: - Connection

public extension AccessoryManager {

    /// Whether there is an open connection to the device.
    func isConnected(_ id: GoveeAccessory.ID) -> Bool {
        connections[id] != nil
    }

    /// Returns the open connection to the device, connecting first if needed.
    @discardableResult
    func connect(to id: GoveeAccessory.ID) async throws -> GoveeConnection<NativeCentral> {
        if let connection = connections[id], await connection.isConnected {
            return connection
        }
        guard let peripheral = self[peripheral: id] else {
            throw GoveeAppError.unknown(id)
        }
        // scanning slows down connecting
        if isScanning {
            stopScanning()
            log("Stopped scanning to connect")
        }
        log("Connecting to \(id)")
        let connection = try await central.connect(to: peripheral, model: id.model)
        connections[id] = connection
        log("Connected to \(id) (\(connection.security))")
        // events end when the device closes the connection
        Task { [weak self] in
            for await event in connection.events {
                self?.log("\(id) event \(event)")
            }
            self?.connectionClosed(id, connection)
        }
        return connection
    }

    /// Closes the connection to the device.
    func disconnect(_ id: GoveeAccessory.ID) async {
        guard let connection = connections[id] else {
            return
        }
        connections[id] = nil
        await connection.disconnect()
        log("Disconnected from \(id)")
    }

    /// Sends a request to the device, connecting first if needed.
    @discardableResult
    func send<Request: GoveeRequest>(
        _ request: Request,
        to id: GoveeAccessory.ID
    ) async throws -> GoveePacket {
        let connection = try await connect(to: id)
        do {
            let reply = try await connection.send(request)
            log("\(id) \(request.packet) -> \(reply)")
            return reply
        }
        catch GoveeConnectionError.disconnected {
            connectionClosed(id, connection)
            throw GoveeConnectionError.disconnected
        }
        catch GoveeConnectionError.timeout {
            // the device may have gone away without disconnecting; reconnect next time
            await disconnect(id)
            throw GoveeConnectionError.timeout
        }
    }
}

private extension AccessoryManager {

    /// Forgets a connection the device closed.
    func connectionClosed(_ id: GoveeAccessory.ID, _ connection: GoveeConnection<NativeCentral>) {
        guard connections[id] === connection else {
            return
        }
        connections[id] = nil
        log("\(id) closed the connection")
    }
}

// MARK: - Air Purifier

public extension AccessoryManager {

    struct AirPurifierStatus: Equatable, Sendable {

        public var isOn: Bool

        public var mode: GoveeAccessory.AirPurifier.Mode

        public var isNightLightOn: Bool

        public var nightLightBrightness: UInt8

        public var nightLightColor: (red: UInt8, green: UInt8, blue: UInt8)

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.isOn == rhs.isOn
                && lhs.mode == rhs.mode
                && lhs.isNightLightOn == rhs.isNightLightOn
                && lhs.nightLightBrightness == rhs.nightLightBrightness
                && lhs.nightLightColor == rhs.nightLightColor
        }
    }

    func airPurifierStatus(_ id: GoveeAccessory.ID) async throws -> AirPurifierStatus {
        let power = try await send(GoveeQuery.power, to: id).power ?? false
        let rawMode = try await send(GoveeQuery.airPurifierMode, to: id).airPurifierMode ?? 0
        let speed = try await send(GoveeQuery.airPurifierManualSpeed, to: id).airPurifierManualSpeed ?? 0
        let light = try await send(GoveeQuery.airPurifierNightLight, to: id).airPurifierNightLight
        let color = try await send(GoveeQuery.airPurifierNightLightColor, to: id).airPurifierNightLightColor
        return AirPurifierStatus(
            isOn: power,
            mode: .init(mode: rawMode, value: rawMode == 0x01 ? speed : 0x00),
            isNightLightOn: light?.isOn ?? false,
            nightLightBrightness: light?.brightness ?? 0,
            nightLightColor: color ?? (0xFF, 0xFF, 0xFF)
        )
    }
}

// MARK: - Heater

public extension AccessoryManager {

    struct HeaterStatus: Equatable, Sendable {

        public var isOn: Bool

        /// Reading from a linked Bluetooth thermometer, in degrees Celsius.
        public var temperature: Float?

        public var humidity: Float?
    }

    func heaterStatus(_ id: GoveeAccessory.ID) async throws -> HeaterStatus {
        let reply = try await send(GoveeQuery.power, to: id)
        let reading = reply.heaterThermometerReading
        return HeaterStatus(
            isOn: reply.power ?? false,
            temperature: reading?.temperature,
            humidity: reading?.humidity
        )
    }
}

// MARK: - Kettle

public extension AccessoryManager {

    struct KettleStatus: Equatable, Sendable {

        public var isHeating: Bool

        /// Water temperature in degrees Fahrenheit.
        public var temperature: Float

        public var isKeepWarmOn: Bool

        public var keepWarmMinutes: UInt8
    }

    func kettleStatus(_ id: GoveeAccessory.ID) async throws -> KettleStatus {
        let status = try await send(GoveeQuery.kettleStatus, to: id).kettleStatus
        let keepWarm = try await send(GoveeQuery.kettleKeepWarm, to: id).kettleKeepWarm
        return KettleStatus(
            isHeating: status?.isHeating ?? false,
            temperature: status?.temperature ?? 0,
            isKeepWarmOn: keepWarm?.isOn ?? false,
            keepWarmMinutes: keepWarm?.minutes ?? 60
        )
    }
}

// MARK: - Thermometer

public extension AccessoryManager {

    struct ThermometerStatus: Equatable, Sendable {

        public var reading: GoveeAccessory.Thermometer.Reading?

        public var firmwareVersion: String?
    }

    func thermometerStatus(_ id: GoveeAccessory.ID) async throws -> ThermometerStatus {
        let reading = try await send(GoveeQuery.thermometerReading, to: id).thermometerReading
        let firmware = try await send(GoveeQuery.thermometerFirmwareVersion, to: id).thermometerFirmwareVersion
        return ThermometerStatus(reading: reading, firmwareVersion: firmware)
    }
}
