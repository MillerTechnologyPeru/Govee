//
//  RC4.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

/// RC4 keystream generator.
///
/// Only used for the last bytes of Govee BLE frames; the state is rebuilt for every frame.
internal struct RC4: Sendable {

    private var state: [UInt8]

    private var i: UInt8 = 0

    private var j: UInt8 = 0

    init<C: Collection>(key: C) where C.Element == UInt8 {
        let key = [UInt8](key)
        precondition(key.isEmpty == false)
        var state = (0 ... 255).map { UInt8($0) }
        var j: UInt8 = 0
        for i in 0 ..< 256 {
            j = j &+ state[i] &+ key[i % key.count]
            state.swapAt(i, Int(j))
        }
        self.state = state
    }

    mutating func next() -> UInt8 {
        i = i &+ 1
        j = j &+ state[Int(i)]
        state.swapAt(Int(i), Int(j))
        return state[Int(state[Int(i)] &+ state[Int(j)])]
    }

    mutating func keystream(count: Int) -> [UInt8] {
        (0 ..< count).map { _ in next() }
    }
}
