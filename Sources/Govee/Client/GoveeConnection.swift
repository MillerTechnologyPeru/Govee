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

    /// Frames received during a ``download(_:timeout:)``.
    private var download: Download?

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
        try await enqueue {
            try await self.perform(request, timeout: timeout)
        }
    }

    /// Sends a request, then collects the decrypted frames the device streams on the history characteristic
    /// (`…2013`) until it sends an `EE 01` event.
    ///
    /// - Parameter timeout: Time allowed for the reply, and between frames.
    public func download<Request: GoveeRequest>(
        _ request: Request,
        timeout: TimeInterval = 5
    ) async throws -> [[UInt8]] {
        try await enqueue {
            try await self.performDownload(request, timeout: timeout)
        }
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
        finishDownload(.failure(GoveeConnectionError.disconnected))
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
        let notify = Set(GoveeChannel.allCases.map { $0.notify } + [.goveeHistory])
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
            do {
                let reply = try await send(GoveePacket.negotiation(.sessionKey), timeout: timeout)
                guard let sessionKey = reply.sessionKey else {
                    throw GoveeConnectionError.handshakeFailed
                }
                try await send(GoveePacket.negotiation(.confirm), timeout: timeout)
                key = sessionKey
            }
            catch GoveeConnectionError.timeout {
                throw GoveeConnectionError.handshakeFailed
            }
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

    struct Download {

        let id: UInt64

        var frames = [[UInt8]]()

        /// Frame count from the device's `EE 01` event. Frames and the event arrive on different
        /// characteristics, so the event can be handled before the last frames.
        var expected: Int?

        /// Set once the download is waiting for the device to finish.
        var continuation: CheckedContinuation<[[UInt8]], Error>?

        /// Set if the device finished before the continuation was set.
        var result: Result<[[UInt8]], Error>?
    }

    /// Runs operations one at a time, in order.
    func enqueue<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        let previous = queue
        let task = Task<T, Error> {
            _ = await previous?.value
            return try await operation()
        }
        queue = Task { _ = await task.result }
        return try await task.value
    }

    func performDownload<Request: GoveeRequest>(
        _ request: Request,
        timeout: TimeInterval
    ) async throws -> [[UInt8]] {
        requestCount += 1
        let id = requestCount
        download = Download(id: id)
        do {
            _ = try await perform(request, timeout: timeout)
        }
        catch {
            download = nil
            throw error
        }
        Task { await self.watchDownload(id, timeout: timeout) }
        return try await withCheckedThrowingContinuation { continuation in
            guard var download, download.id == id else {
                continuation.resume(throwing: GoveeConnectionError.disconnected)
                return
            }
            if let result = download.result {
                self.download = nil
                continuation.resume(with: result)
            } else {
                download.continuation = continuation
                self.download = download
            }
        }
    }

    /// Fails the download if no frame arrives within the timeout.
    func watchDownload(_ id: UInt64, timeout: TimeInterval) async {
        var count = -1
        while let download, download.id == id, download.result == nil, download.frames.count != count {
            count = download.frames.count
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        }
        guard let download, download.id == id else {
            return
        }
        if download.expected != nil {
            finishDownload(.success(download.frames)) // finished, but frames went missing
        } else {
            finishDownload(.failure(GoveeConnectionError.timeout))
        }
    }

    func finishDownload(_ result: Result<[[UInt8]], Error>) {
        guard var download, download.result == nil else {
            return
        }
        if let continuation = download.continuation {
            self.download = nil
            continuation.resume(with: result)
        } else {
            download.result = result
            self.download = download
        }
    }

    func subscribe(_ characteristic: Characteristic) async throws {
        let stream = try await central.notify(for: characteristic)
        notifications.append(stream)
        let task = Task { [weak self] in
            do {
                for try await data in stream {
                    await self?.receive(Array(data), from: characteristic.uuid)
                }
            }
            catch { }
            // the stream ends when the device disconnects
            await self?.connectionLost()
        }
        tasks.append(task)
    }

    /// Called when the device closed the connection.
    func connectionLost() {
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
        finishDownload(.failure(GoveeConnectionError.disconnected))
        eventsContinuation.finish()
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

    func receive(_ bytes: [UInt8], from characteristic: BluetoothUUID) {
        // history frames have no checksum
        if characteristic == .goveeHistory {
            guard download != nil else {
                return
            }
            let frame = key.flatMap { $0.decrypt(bytes) } ?? bytes
            download?.frames.append(frame)
            if let download, let expected = download.expected, download.frames.count >= expected {
                finishDownload(.success(download.frames))
            }
            return
        }
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
        } else if var download, download.result == nil, packet.id == .event, packet.payload[0] == 0x01 {
            // EE 01 <frame count, 2 bytes BE>: download finished
            let expected = Int(packet.payload[1]) << 8 | Int(packet.payload[2])
            download.expected = expected
            self.download = download
            if download.frames.count >= expected {
                finishDownload(.success(download.frames))
            }
        } else {
            eventsContinuation.yield(packet)
        }
    }
}

// MARK: - CentralManager

public extension CentralManager where Self: Sendable, AttributeID: Sendable {

    /// Connects to a Govee device, discovers its characteristics and, if needed, negotiates an encrypted session.
    ///
    /// - Parameter connectTimeout: Time allowed to establish the Bluetooth connection.
    /// Thermometers advertise slowly, so this is longer than the reply timeout.
    /// - Parameter timeout: Time allowed for each reply during setup.
    func connect(
        to peripheral: Peripheral,
        model: GoveeModel,
        security: GoveeSecurity? = nil,
        connectTimeout: TimeInterval = 15,
        timeout: TimeInterval = 5
    ) async throws -> GoveeConnection<Self> {
        // CoreBluetooth waits forever for a device that is not advertising
        do {
            try await withTimeout(connectTimeout) {
                try await self.connect(to: peripheral)
            } late: { result in
                if case .success = result {
                    await self.disconnect(peripheral)
                }
            }
        }
        catch GoveeConnectionError.timeout {
            throw GoveeConnectionError.connectionTimeout
        }
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

// MARK: - Timeout

/// Runs the operation, throwing ``GoveeConnectionError/timeout`` if it does not finish in time.
///
/// The operation keeps running after a timeout; `late` receives its result.
internal func withTimeout<T: Sendable>(
    _ timeout: TimeInterval,
    operation: @escaping @Sendable () async throws -> T,
    late: @escaping @Sendable (Result<T, Error>) async -> () = { _ in }
) async throws -> T {
    let result = TimeoutResult<T>()
    return try await withCheckedThrowingContinuation { continuation in
        result.continuation = continuation
        let task = Task {
            let value: Result<T, Error>
            do { value = .success(try await operation()) }
            catch { value = .failure(error) }
            if result.resume(with: value) == false {
                await late(value)
            }
        }
        Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            if result.resume(with: .failure(GoveeConnectionError.timeout)) {
                task.cancel()
            }
        }
    }
}

/// Resumes a continuation once.
private final class TimeoutResult<T: Sendable>: @unchecked Sendable {

    private let lock = NSLock()

    private var _continuation: CheckedContinuation<T, Error>?

    var continuation: CheckedContinuation<T, Error>? {
        get { lock.withLock { _continuation } }
        set { lock.withLock { _continuation = newValue } }
    }

    /// Returns `false` if already resumed.
    func resume(with result: Result<T, Error>) -> Bool {
        let continuation = lock.withLock {
            let continuation = _continuation
            _continuation = nil
            return continuation
        }
        guard let continuation else {
            return false
        }
        continuation.resume(with: result)
        return true
    }
}

// MARK: - Error

/// Govee connection error.
public enum GoveeConnectionError: Error, Equatable, Sendable {

    /// No reply within the timeout.
    case timeout

    /// The Bluetooth connection was not established in time, usually because the device is out of range
    /// or connected to another phone.
    case connectionTimeout

    /// The connection was closed.
    case disconnected

    /// A required characteristic was not found.
    case characteristicNotFound(BluetoothUUID)

    /// The encrypted session could not be set up.
    case handshakeFailed
}

extension GoveeConnectionError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .timeout:
            return "No reply from the device"
        case .connectionTimeout:
            return "Could not connect; the device may be out of range or connected to another phone"
        case .disconnected:
            return "The device disconnected"
        case let .characteristicNotFound(uuid):
            return "Characteristic \(uuid) not found"
        case .handshakeFailed:
            return "Encrypted session setup failed"
        }
    }
}
