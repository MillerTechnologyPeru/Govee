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

    static func bytes(_ string: String) -> [UInt8] {
        hex(string)
    }

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
        } catch GoveeConnectionError.handshakeFailed { }
        XCTAssertFalse(central.isConnected)
    }

    func testThermometerHistory() async throws {
        // Replays the H5072 handshake from the 2026-10-28 capture: its E7 01 reply carries the captured session key.
        let session = GoveeEncryptionKey(hex("CA A2 7E 2B 8B AF F4 C5 B1 58 7F 92 3F 88 0D 2D"))!
        let frames = [
            hex("01 2B 03 71 57 03 71 57 03 75 3F 03 75 40 03 75 3F 03 75 40"),
            hex("00 00 03 B7 B6 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF"),
        ]
        let central = TestCentral(services: [.goveeControlService, .goveeThermostat]) { frame, characteristic in
            if characteristic == .goveeControlWrite {
                let packet = GoveePacket(encrypted: frame, key: .communication)!
                if packet.payload[0] == 0x01 {
                    return [(.goveeControlNotify, hex("58 32 84 80 B6 B1 F3 00 8E E0 CB 66 6E DF 89 7F 65 C3 40 02"))]
                }
                return [(.goveeControlNotify, frame)]
            }
            let packet = GoveePacket(encrypted: frame, key: session)!
            func reply(_ hex: String) -> [UInt8] {
                GoveePacket(bytes: GoveeConnectionTests.bytes(hex))!.encrypted(with: session)
            }
            switch (characteristic, packet.bytes[1]) {
            case (.goveeData, 0x02):
                return [(.goveeData, reply("33 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 31"))]
            case (.goveeData, 0x01):
                // the encrypted first frame is the captured one
                XCTAssertEqual(session.encrypt(frames[0]), hex("B7 3F C8 E8 87 79 19 C7 47 D1 6D C9 2A 05 C0 44 D4 9B 4F 95"))
                return [(.goveeData, reply("33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32"))]
                    + frames.map { (.goveeHistory, session.encrypt($0)!) }
                    + [(.goveeData, reply("EE 01 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ED"))]
            default:
                return []
            }
        }
        let connection = try await central.connect(to: central.peripheral, model: .h5072)
        let history = try await connection.thermometerHistory(minutes: 299)
        XCTAssertEqual(history.count, 7)
        XCTAssertEqual(history.first?.minutesAgo, 299)
        XCTAssertEqual(history.last?.minutesAgo, 0)
        XCTAssertEqual(try XCTUnwrap(history.last).humidity, 63.8, accuracy: 0.01)
        await connection.disconnect()
    }

    func testHistoryTimeout() async throws {
        // The device acknowledges the request but never streams
        let central = TestCentral(services: [.goveeControlService, .goveeThermostat]) { frame, characteristic in
            [(characteristic == .goveeData ? .goveeData : .goveeControlNotify, frame)]
        }
        let connection = try await central.connect(to: central.peripheral, model: .h5072, security: .plaintext)
        do {
            _ = try await connection.download(GoveeAccessory.Thermometer.Command.history(minutes: 1), timeout: 0.2)
            XCTFail()
        } catch GoveeConnectionError.timeout { }
        await connection.disconnect()
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
            _ = try await central.connect(to: central.peripheral, model: .h712C, connectTimeout: 0.2)
            XCTFail()
        } catch GoveeConnectionError.connectionTimeout { }
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

    /// Device behavior: returns notifications, and the characteristic each is sent on, for each written frame.
    let device: @Sendable ([UInt8], BluetoothUUID) -> [(BluetoothUUID, [UInt8])]

    /// Services the device exposes.
    let services: [BluetoothUUID]

    private let lock = NSLock()

    private var _writes = [[UInt8]]()

    private var _isConnected = false

    private var notify = [BluetoothUUID: AsyncIndefiniteStream<Data>.Continuation]()

    /// Whether `connect(to:)` succeeds; otherwise it never returns, like CoreBluetooth.
    let isAdvertising: Bool

    /// A device with only the control service, replying on `…2b10`.
    convenience init(isAdvertising: Bool = true, device: @escaping @Sendable ([UInt8]) -> [[UInt8]]) {
        self.init(isAdvertising: isAdvertising, services: [.goveeControlService]) { frame, _ in
            device(frame).map { (.goveeControlNotify, $0) }
        }
    }

    init(
        isAdvertising: Bool = true,
        services: [BluetoothUUID],
        device: @escaping @Sendable ([UInt8], BluetoothUUID) -> [(BluetoothUUID, [UInt8])]
    ) {
        self.isAdvertising = isAdvertising
        self.services = services
        self.device = device
    }

    /// Simulates the device closing the connection.
    func dropConnection() {
        let notify = lock.withLock {
            _isConnected = false
            let notify = self.notify
            self.notify.removeAll()
            return notify
        }
        notify.values.forEach { $0.finish(throwing: CentralError.disconnected) }
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
            notify.removeAll()
        }
    }

    func disconnectAll() async {
        await disconnect(peripheral)
    }

    func discoverServices(
        _ services: Set<BluetoothUUID>,
        for peripheral: Peripheral
    ) async throws -> [Service<Peripheral, AttributeID>] {
        // A loop, not `enumerated().map`: on Linux (Swift 6.4.1) the closure's thunk crashes
        // with a null pointer dereference.
        var result = [Service<Peripheral, AttributeID>]()
        for index in self.services.indices {
            result.append(Service(id: UInt16(index), uuid: self.services[index], peripheral: peripheral))
        }
        return result
    }

    func discoverCharacteristics(
        _ characteristics: Set<BluetoothUUID>,
        for service: Service<Peripheral, AttributeID>
    ) async throws -> [Characteristic<Peripheral, AttributeID>] {
        switch service.uuid {
        case .goveeControlService:
            return [
                Characteristic(id: 0x1E, uuid: .goveeControlNotify, peripheral: peripheral, properties: [.read, .notify]),
                Characteristic(id: 0x22, uuid: .goveeControlWrite, peripheral: peripheral, properties: [.read, .writeWithoutResponse]),
            ]
        case .goveeThermostat:
            return [
                Characteristic(id: 0x30, uuid: .goveeSetup, peripheral: peripheral, properties: [.read, .writeWithoutResponse, .notify]),
                Characteristic(id: 0x34, uuid: .goveeData, peripheral: peripheral, properties: [.read, .writeWithoutResponse, .notify]),
                Characteristic(id: 0x38, uuid: .goveeHistory, peripheral: peripheral, properties: [.read, .notify]),
            ]
        default:
            return []
        }
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
        for (characteristic, reply) in device(frame, characteristic.uuid) {
            notify[characteristic]?.yield(Data(reply))
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
            self.lock.withLock { self.notify[characteristic.uuid] = continuation }
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
