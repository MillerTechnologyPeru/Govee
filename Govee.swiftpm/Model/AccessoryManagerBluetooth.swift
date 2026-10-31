//
//  AccessoryManagerBluetooth.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

#if canImport(FoundationEmbedded)
import FoundationEmbedded
#else
import Foundation
#endif
import Bluetooth
import GATT
import DarwinGATT
import Govee
#if hasFeature(Embedded)
// MainActor and Task.sleep come from SwiftUI under Embedded Swift.
import SwiftUI
#endif

public extension AccessoryManager {
    
    /// The Bluetooth LE peripheral for the speciifed device identifier..
    subscript (peripheral id: GoveeAccessory.ID) -> NativeCentral.Peripheral? {
        return peripherals.first(where: { $0.value.id == id })?.key
    }
    
    func scan(
        duration: TimeInterval? = nil,
        filterServices: Bool = false
    ) async throws {
        let bluetoothState = await central.state
        guard bluetoothState == .poweredOn else {
            throw GoveeAppError.bluetoothUnavailable
        }
        let filterDuplicates = true //preferences.filterDuplicates
        self.peripherals.removeAll(keepingCapacity: true)
        stopScanning()
        let services: Set<BluetoothUUID> = filterServices ? [.govee] : []
        let scanStream = central.scan(
            with: services,
            filterDuplicates: filterDuplicates
        )
        self.scanStream = scanStream
        let task = Task {
            for try await scanData in scanStream {
                guard await found(scanData) else { continue }
            }
        }
        if let duration = duration {
            precondition(duration > 0.001)
            try await Task.sleep(timeInterval: duration)
            scanStream.stop()
            try await task.value // throw errors
        } else {
            // error not thrown
            Task {
                do { try await task.value }
                catch is CancellationError { }
                catch {
                    self.log("Error scanning: \(error)")
                }
            }
        }
    }
    
    func stopScanning() {
        scanStream?.stop()
        scanStream = nil
    }
}

internal extension AccessoryManager {
    
    func observeBluetoothState() {
        // observe state; the manager is a singleton, so this runs as long as the app
        Task {
            while true {
                let newState = await self.central.state
                let oldValue = self.state
                if newState != oldValue {
                    self.state = newState
                }
                try await Task.sleep(timeInterval: 0.5)
            }
        }
    }
    
    var loadConnections: Set<NativePeripheral> {
        get async {
            let peripherals = await self.central
                .peripherals
                .filter { $0.value }
                .map { $0.key }
            return Set(peripherals)
        }
    }
    
    func found(_ scanData: ScanData<NativeCentral.Peripheral, NativeCentral.Advertisement>) async -> Bool {
        
        // aggregate scan data
        let oldCacheValue = scanResults[scanData.peripheral]
        // cache discovered peripheral in background
        let cache = await Task.detached {
            var cache = oldCacheValue ?? ScanDataCache(scanData: scanData)
            cache += scanData
            #if !targetEnvironment(simulator)
            for serviceUUID in scanData.advertisementData.overflowServiceUUIDs ?? [] {
                cache.overflowServiceUUIDs.insert(serviceUUID)
            }
            #endif
            return cache
        }.value
        scanResults[scanData.peripheral] = cache
        
        guard let advertisement = GoveeAccessory(cache) else {
            return false
        }
        
        if self.peripherals[scanData.peripheral] == nil {
            log("Found \(advertisement.id)")
        }
        self.peripherals[scanData.peripheral] = advertisement
        return true
    }
}
