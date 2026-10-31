//
//  Store.swift
//
//
//  Created by Alsey Coleman Miller on 3/13/24.
//

#if canImport(FoundationEmbedded)
import FoundationEmbedded
#else
import Foundation
#endif
import SwiftUI
#if canImport(CoreBluetooth)
import CoreBluetooth
#endif
import Bluetooth
import GATT
import DarwinGATT
import Govee

@MainActor
public final class AccessoryManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    public internal(set) var state: DarwinBluetoothState = .unknown
    
    public var isScanning: Bool {
        scanStream != nil
    }
    
    @Published
    public internal(set) var peripherals = [NativeCentral.Peripheral: GoveeAccessory]()
    
    /// All discovered devices.
    @Published
    public internal(set) var scanResults = [NativeCentral.Peripheral: ScanDataCache<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
    
    internal lazy var central = NativeCentral()
    
    @Published
    internal var scanStream: AsyncCentralScan<NativeCentral>?
    
    /// Open GATT connections.
    @Published
    public internal(set) var connections = [GoveeAccessory.ID: GoveeConnection<NativeCentral>]()
    
    // MARK: - Initialization
    
    public static let shared = AccessoryManager()
    
    private init() {
        // The manager is a singleton, so capturing it strongly is fine.
        central.log = { self.log("📲 Central: " + $0) }
        observeBluetoothState()
    }
}
