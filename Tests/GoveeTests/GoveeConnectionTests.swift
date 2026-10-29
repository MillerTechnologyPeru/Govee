//
//  GoveeConnectionTests.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import XCTest
@testable import Govee
import Bluetooth
import GATT
import BluetoothGAP

/// End-to-end tests of ``GoveeConnection`` against a simulated device.
final class GoveeConnectionTests: XCTestCase {

    func testEncryptedHeater() async throws {
        // Replays the H7135 heater from the 2026-10-28 capture: its E7 01 reply carries the captured session key.
        let session = GoveeEncryptionKey(hex("D0 FD 2A 58 85 B2 E0 0D 3A 67 95 C2 EF 1D 4A 77"))!
        let central = TestCentral { frame in
            if let packet = GoveePacket(encrypted: frame, key: .communication), packet.id == .negotiation {
                if packet.payload[0] == 0x01 {
                    return [hex("DB 74 E3 82 34 CA 4D A4 B4 AD 62 A7 0A 32 BB 5F 22 99 4A F3")]
                }
                return [frame] // E7 02 echo
            }
            guard let packet = GoveePacket(encrypted: frame, key: session) else {
                return []
            }
            if packet == GoveeQuery.power.packet {
                let status = GoveePacket(bytes: hex("AA 01 01 00 00 00 01 03 B3 CF 00 00 00 00 00 00 00 00 00 D4"))!
                return [status.encrypted(with: session)]
            }
            return [frame] // commands are echoed
        }

        let connection = try await central.connect(to: central.peripheral, model: .h7135)
        XCTAssertEqual(connection.security, .encrypted)

        // Low, encrypted exactly as the Govee app sent it
        let reply = try await connection.send(GoveeAccessory.Heater.Command.mode(.heat(level: 1)))
        XCTAssertEqual(reply, GoveeAccessory.Heater.Command.mode(.heat(level: 1)).packet)
        XCTAssertEqual(central.writes.last, hex("2D 11 CC 6E DF 20 62 3C 04 BA B8 65 0B D9 B1 3F 87 53 32 54"))

        let status = try await connection.send(GoveeQuery.power)
        XCTAssertEqual(status.power, true)
        XCTAssertEqual(try XCTUnwrap(status.heaterThermometerReading).temperature, 24.2639, accuracy: 0.0001)

        // E7 01, E7 02, then the two requests
        XCTAssertEqual(central.writes.count, 4)
        XCTAssertEqual(GoveePacket(encrypted: central.writes[0], key: .communication)?.id, .negotiation)

        await connection.disconnect()
        XCTAssertFalse(central.isConnected)
        do {
            try await connection.send(GoveeQuery.power)
            XCTFail()
        } catch GoveeConnectionError.disconnected { }
    }

    func testPlaintextPurifier() async throws {
        let central = TestCentral { frame in
            let packet = GoveePacket(bytes: frame)!
            if packet == GoveeQuery.airPurifierMode.packet {
                return [hex("AA 05 00 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 A8")]
            }
            return [frame]
        }
        let connection = try await central.connect(to: central.peripheral, model: .h712C)
        XCTAssertEqual(connection.security, .plaintext)

        try await connection.send(GoveeAccessory.AirPurifier.Command.mode(.turbo))
        XCTAssertEqual(central.writes.last, hex("3A 05 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 38"))

        let mode = try await connection.send(GoveeQuery.airPurifierMode)
        XCTAssertEqual(mode.airPurifierMode, 0x07)
        XCTAssertEqual(central.writes.count, 2)
        await connection.disconnect()
    }

    func testEventsAndConcurrentRequests() async throws {
        let central = TestCentral { frame in
            // unsolicited event before the reply
            [hex("EE AA 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 44"), frame]
        }
        let connection = try await central.connect(to: central.peripheral, model: .h712C)
        async let first = connection.send(GoveeAccessory.AirPurifier.Command.nightLight(true))
        async let second = connection.send(GoveeAccessory.AirPurifier.Command.nightLightBrightness(10))
        let replies = try await [first, second]
        XCTAssertEqual(replies[0], GoveeAccessory.AirPurifier.Command.nightLight(true).packet)
        XCTAssertEqual(replies[1], GoveeAccessory.AirPurifier.Command.nightLightBrightness(10).packet)

        var iterator = connection.events.makeAsyncIterator()
        let event = await iterator.next()
        XCTAssertEqual(event?.id, .event)
        await connection.disconnect()
    }

    func testTimeout() async throws {
        let central = TestCentral { _ in [] }
        let connection = try await central.connect(to: central.peripheral, model: .h712C)
        do {
            try await connection.send(GoveeQuery.power, timeout: 0.2)
            XCTFail()
        } catch GoveeConnectionError.timeout { }
        await connection.disconnect()
    }

    func testHandshakeTimeout() async throws {
        let central = TestCentral { _ in [] }
        do {
            _ = try await central.connect(to: central.peripheral, model: .h7135, timeout: 0.2)
            XCTFail()
        } catch GoveeConnectionError.timeout { }
        XCTAssertFalse(central.isConnected)
    }

    func testDeviceDisconnect() async throws {
        let central = TestCentral { frame in [frame] }
        let connection = try await central.connect(to: central.peripheral, model: .h712C)
        try await connection.send(GoveeQuery.power)
        // the device closes the connection, as the H712C and H5072 do when idle
        central.dropConnection()
        for await _ in connection.events { }
        let isConnected = await connection.isConnected
        XCTAssertFalse(isConnected)
        do {
            try await connection.send(GoveeQuery.power)
            XCTFail()
        } catch GoveeConnectionError.disconnected { }
    }

    func testConnectTimeout() async throws {
        let central = TestCentral(isAdvertising: false) { frame in [frame] }
        do {
            _ = try await central.connect(to: central.peripheral, model: .h712C, timeout: 0.2)
            XCTFail()
        } catch GoveeConnectionError.timeout { }
        XCTAssertTrue(central.writes.isEmpty)
    }
}

// MARK: - Test Central

/// Simulated central with one Govee device exposing the control service.
private final class TestCentral: CentralManager, @unchecked Sendable {

    typealias Peripheral = GATT.Peripheral

    typealias Advertisement = LowEnergyAdvertisingData

    typealias AttributeID = UInt16

    typealias Data = Foundation.Data

    var log: (@Sendable (String) -> ())?

    let peripheral = Peripheral(id: BluetoothAddress(rawValue: "D4:AD:FC:84:9F:73")!)

    /// Device behavior: returns notifications for each written frame.
    let device: @Sendable ([UInt8]) -> [[UInt8]]

    private let lock = NSLock()

    private var _writes = [[UInt8]]()

    private var _isConnected = false

    private var notify: AsyncIndefiniteStream<Data>.Continuation?

    /// Whether `connect(to:)` succeeds; otherwise it never returns, like CoreBluetooth.
    let isAdvertising: Bool

    init(isAdvertising: Bool = true, device: @escaping @Sendable ([UInt8]) -> [[UInt8]]) {
        self.isAdvertising = isAdvertising
        self.device = device
    }

    /// Simulates the device closing the connection.
    func dropConnection() {
        let notify = lock.withLock {
            _isConnected = false
            let notify = self.notify
            self.notify = nil
            return notify
        }
        notify?.finish(throwing: CentralError.disconnected)
    }

    var writes: [[UInt8]] {
        lock.withLock { _writes }
    }

    var isConnected: Bool {
        lock.withLock { _isConnected }
    }

    var peripherals: [Peripheral: Bool] {
        get async { [peripheral: isConnected] }
    }

    func scan(filterDuplicates: Bool) async throws -> AsyncCentralScan<TestCentral> {
        AsyncCentralScan { _ in }
    }

    func connect(to peripheral: Peripheral) async throws {
        guard isAdvertising else {
            try await Task.sleep(nanoseconds: .max)
            return
        }
        lock.withLock { _isConnected = true }
    }

    func disconnect(_ peripheral: Peripheral) async {
        lock.withLock {
            _isConnected = false
            notify = nil
        }
    }

    func disconnectAll() async {
        await disconnect(peripheral)
    }

    func discoverServices(
        _ services: Set<BluetoothUUID>,
        for peripheral: Peripheral
    ) async throws -> [Service<Peripheral, AttributeID>] {
        [Service(id: 0x1C, uuid: .goveeControlService, peripheral: peripheral)]
    }

    func discoverCharacteristics(
        _ characteristics: Set<BluetoothUUID>,
        for service: Service<Peripheral, AttributeID>
    ) async throws -> [Characteristic<Peripheral, AttributeID>] {
        [
            Characteristic(id: 0x1E, uuid: .goveeControlNotify, peripheral: peripheral, properties: [.read, .notify]),
            Characteristic(id: 0x22, uuid: .goveeControlWrite, peripheral: peripheral, properties: [.read, .writeWithoutResponse]),
        ]
    }

    func readValue(for characteristic: Characteristic<Peripheral, AttributeID>) async throws -> Data {
        Data()
    }

    func writeValue(
        _ data: Data,
        for characteristic: Characteristic<Peripheral, AttributeID>,
        withResponse: Bool
    ) async throws {
        let frame = [UInt8](data)
        let notify = lock.withLock {
            _writes.append(frame)
            return self.notify
        }
        for reply in device(frame) {
            notify?.yield(Data(reply))
        }
    }

    func discoverDescriptors(for characteristic: Characteristic<Peripheral, AttributeID>) async throws -> [Descriptor<Peripheral, AttributeID>] {
        []
    }

    func readValue(for descriptor: Descriptor<Peripheral, AttributeID>) async throws -> Data {
        Data()
    }

    func writeValue(_ data: Data, for descriptor: Descriptor<Peripheral, AttributeID>) async throws { }

    func notify(for characteristic: Characteristic<Peripheral, AttributeID>) async throws -> AsyncCentralNotifications<TestCentral> {
        AsyncCentralNotifications(onTermination: { }) { continuation in
            self.lock.withLock { self.notify = continuation }
        }
    }

    func maximumTransmissionUnit(for peripheral: Peripheral) async throws -> MaximumTransmissionUnit {
        MaximumTransmissionUnit(rawValue: 23)!
    }

    func rssi(for peripheral: Peripheral) async throws -> RSSI {
        RSSI(rawValue: -50)!
    }
}

private func hex(_ string: String) -> [UInt8] {
    string.split(separator: " ").compactMap { UInt8($0, radix: 16) }
}
