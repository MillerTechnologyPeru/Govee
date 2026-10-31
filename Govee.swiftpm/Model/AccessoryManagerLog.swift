//
//  AccessoryManagerLog.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

#if canImport(FoundationEmbedded)
import FoundationEmbedded
#else
import Foundation
#endif

public extension AccessoryManager {
    
    nonisolated func log(_ message: String) {
        print(message)
    }
}
