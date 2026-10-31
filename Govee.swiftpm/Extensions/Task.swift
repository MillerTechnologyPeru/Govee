//
//  Task.swift
//
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

#if hasFeature(Embedded)
// MainActor and Task.sleep come from SwiftUI under Embedded Swift.
import SwiftUI
#endif

public extension Task where Success == Never, Failure == Never {
    
    static func sleep(timeInterval: Double) async throws {
        try await sleep(nanoseconds: UInt64(timeInterval * Double(1_000_000_000)))
    }
}
