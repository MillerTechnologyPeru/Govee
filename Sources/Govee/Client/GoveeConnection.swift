//
//  GoveeConnection.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import Bluetooth
import GATT

/// Govee GATT Connection
///
/// Sends ``GoveeRequest`` packets to a connected device and returns its replies, encrypting
/// them when the device requires it. Requests are sent one at a time.
///
/// Create one with ``GATT/CentralManager/connect(to:model:security:timeout:)``.
public actor GoveeConnection<Central: CentralManager> where Central: Sendable, Central.AttributeID: Sendable {

    public typealias Peripheral = Central.Peripheral

    public typealias Characteristic = GATT.Characteristic<Central.Peripheral, Central.AttributeID>

    // MARK: - Properties

    /// Connected peripheral.
    public nonisolated let peripheral: Peripheral

    /// Device model.
    public nonisolated let model: GoveeModel

    /// Packet security used on this connection.
    public nonisolated let security: GoveeSecurity

    /// Packets the device sends that are not replies to a request, such as `EE` events.
    public nonisolated let events: AsyncStream<GoveePacket>

    /// Whether the connection is still open.
    public private(set) var isConnected = true

    private let central: Central

    private let eventsContinuation: AsyncStream<GoveePacket>.Continuation

    private var characteristics = [BluetoothUUID: Characteristic]()

    private var key: GoveeEncryptionKey?

    private var notifications = [AsyncCentralNotifications<Central>]()

    private var tasks = [Task<Void, Never>]()

    private var pending: PendingRequest?

    private var requestCount: UInt64 = 0

    private var queue: Task<Void, Never>?

    // MARK: - Initialization

    internal init(
        central: Central,
        peripheral: Peripheral,
        model: GoveeModel,
        security: GoveeSecurity
    ) {
        self.central = central
        self.peripheral = peripheral
        self.model = model
        self.security = security
        var continuation: AsyncStream<GoveePacket>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventsContinuation = continuation
    }

    // MARK: - Methods

    /// Sends a request and waits for the device's reply.
    @discardableResult
    public func send<Request: GoveeRequest>(
        _ request: Request,
        timeout: TimeInterval = 5
    ) async throws -> GoveePacket {
        let previous = queue
        let task = Task<GoveePacket, Error> {
            _ = await previous?.value
            return try await perform(request, timeout: timeout)
        }
        queue = Task { _ = await task.result }
        return try await task.value
    }

    /// Closes the connection.
    public func disconnect() async {
        guard isConnected else {
            return
        }
        isConnected = false
        notifications.forEach { $0.stop() }
        tasks.forEach { $0.cancel() }
        if let pending {
            self.pending = nil
            pending.continuation.resume(throwing: GoveeConnectionError.disconnected)
        }
        eventsContinuation.finish()
        await central.disconnect(peripheral)
    }
}

// MARK: - Setup

internal extension GoveeConnection {

    func setup(timeout: TimeInterval) async throws {
        // discover
        let services = try await central.discoverServices([.goveeControlService, .goveeThermostat], for: peripheral)
        for service in services {
            let characteristics = try await central.discoverCharacteristics([], for: service)
            for characteristic in characteristics {
                self.characteristics[characteristic.uuid] = characteristic
            }
        }
        guard characteristics[.goveeControlWrite] != nil else {
            throw GoveeConnectionError.characteristicNotFound(.goveeControlWrite)
        }
        // subscribe
        let notify = Set(GoveeChannel.allCases.map { $0.notify })
        for uuid in notify {
            guard let characteristic = characteristics[uuid],
                  characteristic.properties.contains(.notify) else {
                continue
            }
            try await subscribe(characteristic)
        }
        // negotiate session key
        if security == .encrypted {
            key = .communication
            let reply = try await send(GoveePacket.negotiation(.sessionKey), timeout: timeout)
            guard let sessionKey = reply.sessionKey else {
                throw GoveeConnectionError.handshakeFailed
            }
            try await send(GoveePacket.negotiation(.confirm), timeout: timeout)
            key = sessionKey
        }
    }
}

// MARK: - Private

private extension GoveeConnection {

    struct PendingRequest {

        let id: UInt64

        let request: GoveePacket

        let continuation: CheckedContinuation<GoveePacket, Error>
    }

    func subscribe(_ characteristic: Characteristic) async throws {
        let stream = try await central.notify(for: characteristic)
        notifications.append(stream)
        let task = Task { [weak self] in
            do {
                for try await data in stream {
                    await self?.receive(Array(data))
                }
            }
            catch { }
        }
        tasks.append(task)
    }

    func perform<Request: GoveeRequest>(
        _ request: Request,
        timeout: TimeInterval
    ) async throws -> GoveePacket {
        guard isConnected else {
            throw GoveeConnectionError.disconnected
        }
        let channel = request.channel
        guard let characteristic = characteristics[channel.write] else {
            throw GoveeConnectionError.characteristicNotFound(channel.write)
        }
        let packet = request.packet
        let bytes = key.map { packet.encrypted(with: $0) } ?? packet.bytes
        let withResponse = characteristic.properties.contains(.writeWithoutResponse) == false
        requestCount += 1
        let id = requestCount
        let central = self.central
        return try await withCheckedThrowingContinuation { continuation in
            pending = PendingRequest(id: id, request: packet, continuation: continuation)
            Task {
                do {
                    try await central.writeValue(Central.Data(bytes), for: characteristic, withResponse: withResponse)
                }
                catch {
                    self.fail(id, error)
                }
            }
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self.fail(id, GoveeConnectionError.timeout)
            }
        }
    }

    func fail(_ id: UInt64, _ error: Error) {
        guard let pending, pending.id == id else {
            return
        }
        self.pending = nil
        pending.continuation.resume(throwing: error)
    }

    func receive(_ bytes: [UInt8]) {
        let packet: GoveePacket?
        if let key {
            packet = GoveePacket(encrypted: bytes, key: key)
        } else {
            packet = GoveePacket(bytes: bytes)
        }
        guard let packet else {
            return // undecodable, such as thermometer history frames
        }
        if let pending, packet.isReply(to: pending.request) {
            self.pending = nil
            pending.continuation.resume(returning: packet)
        } else {
            eventsContinuation.yield(packet)
        }
    }
}

// MARK: - CentralManager

public extension CentralManager where Self: Sendable, AttributeID: Sendable {

    /// Connects to a Govee device, discovers its characteristics and, if needed, negotiates an encrypted session.
    func connect(
        to peripheral: Peripheral,
        model: GoveeModel,
        security: GoveeSecurity? = nil,
        timeout: TimeInterval = 5
    ) async throws -> GoveeConnection<Self> {
        try await connect(to: peripheral)
        let connection = GoveeConnection(
            central: self,
            peripheral: peripheral,
            model: model,
            security: security ?? model.security
        )
        do {
            try await connection.setup(timeout: timeout)
        }
        catch {
            await connection.disconnect()
            throw error
        }
        return connection
    }
}

// MARK: - Error

/// Govee connection error.
public enum GoveeConnectionError: Error, Equatable, Sendable {

    /// No reply within the timeout.
    case timeout

    /// The connection was closed.
    case disconnected

    /// A required characteristic was not found.
    case characteristicNotFound(BluetoothUUID)

    /// The device did not return a session key.
    case handshakeFailed
}
