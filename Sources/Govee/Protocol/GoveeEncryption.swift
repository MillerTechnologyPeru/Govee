//
//  GoveeEncryption.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

/// Govee BLE Encryption Key
///
/// Key for the "v1" frame encryption used by newer Govee devices (for example H7135, H7173, H5072).
/// A frame is encrypted as:
/// - bytes 0 to 15: AES-128-ECB
/// - bytes 16 to 19: XOR with the first 4 bytes of an RC4 keystream, restarted for every frame
///
/// Handshake frames use ``communication``; later frames use the per-connection session key
/// returned by the device in its `E7 01` reply. See `Docs/BLE-Protocol.md`.
public struct GoveeEncryptionKey: Equatable, Hashable, Sendable {

    /// Key length.
    public static var length: Int { 16 }

    /// Key bytes.
    public let rawValue: [UInt8]

    public init?<C: Collection>(_ bytes: C) where C.Element == UInt8 {
        let bytes = [UInt8](bytes)
        guard bytes.count == Self.length else {
            return nil
        }
        self.rawValue = bytes
    }
}

public extension GoveeEncryptionKey {

    /// Communication key built into the Govee app, shared by all devices, used for the handshake.
    static var communication: GoveeEncryptionKey {
        GoveeEncryptionKey(Array("MakingLifeSmarte".utf8))!
    }
}

// MARK: - Frame Encryption

public extension GoveeEncryptionKey {

    /// Encrypts a 20-byte frame.
    func encrypt<C: Collection>(_ frame: C) -> [UInt8]? where C.Element == UInt8 {
        transform(frame, encrypt: true)
    }

    /// Decrypts a 20-byte frame. The result is not validated.
    func decrypt<C: Collection>(_ frame: C) -> [UInt8]? where C.Element == UInt8 {
        transform(frame, encrypt: false)
    }
}

private extension GoveeEncryptionKey {

    func transform<C: Collection>(_ frame: C, encrypt: Bool) -> [UInt8]? where C.Element == UInt8 {
        let frame = [UInt8](frame)
        guard frame.count == GoveePacket.length else {
            return nil
        }
        let aes = AES128(key: rawValue)!
        let head = frame.prefix(AES128.blockSize)
        var output = encrypt ? aes.encrypt(block: head) : aes.decrypt(block: head)
        var rc4 = RC4(key: rawValue)
        let tail = frame.dropFirst(AES128.blockSize)
        output += zip(tail, rc4.keystream(count: tail.count)).map { $0 ^ $1 }
        return output
    }
}

// MARK: - GoveePacket

public extension GoveePacket {

    /// Decrypts and parses an encrypted packet.
    ///
    /// Returns `nil` unless the decrypted frame has a valid checksum.
    init?<C: Collection>(encrypted bytes: C, key: GoveeEncryptionKey) where C.Element == UInt8 {
        guard let decrypted = key.decrypt(bytes) else {
            return nil
        }
        self.init(bytes: decrypted)
    }

    /// Encrypted packet bytes.
    func encrypted(with key: GoveeEncryptionKey) -> [UInt8] {
        key.encrypt(bytes)!
    }
}

// MARK: - Negotiation

public extension GoveePacket {

    /// Session negotiation step.
    enum NegotiationStep: UInt8, CaseIterable, Sendable {

        /// Request a session key.
        case sessionKey     = 0x01

        /// Confirm the session key.
        case confirm        = 0x02
    }

    /// Number of random bytes in a negotiation request.
    static var negotiationRandomLength: Int { 17 }

    /// Negotiation request (`E7 <step>` followed by 17 random bytes), sent encrypted with ``GoveeEncryptionKey/communication``.
    static func negotiation<C: Collection>(_ step: NegotiationStep, random: C) -> GoveePacket? where C.Element == UInt8 {
        let random = [UInt8](random)
        guard random.count == negotiationRandomLength else {
            return nil
        }
        return GoveePacket(id: .negotiation, payload: [step.rawValue] + random)
    }

    /// Negotiation request with random bytes from the system generator.
    static func negotiation(_ step: NegotiationStep) -> GoveePacket {
        var generator = SystemRandomNumberGenerator()
        let random = (0 ..< negotiationRandomLength).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return negotiation(step, random: random)!
    }

    /// Session key from the device's `E7 01` reply.
    ///
    /// Only meaningful on the device's reply; the client's own `E7 01` request carries random bytes in the same position.
    var sessionKey: GoveeEncryptionKey? {
        guard id == .negotiation,
              payload.first == NegotiationStep.sessionKey.rawValue else {
            return nil
        }
        return GoveeEncryptionKey(payload[1 ... GoveeEncryptionKey.length])
    }
}
