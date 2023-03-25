//
//  NearbyDevicesView.swift
//  
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

import Foundation
import SwiftUI
import Govee

struct NearbyDevicesView: View {
    
    @EnvironmentObject
    var store: Store
    
    @State
    private var scanTask: Task<Void, Never>?
    
    var body: some View {
        list
        .navigationTitle(title)
        .navigationBarItems(trailing: scanButton)
        .onAppear {
            scanTask?.cancel()
            scanTask = Task {
                // start scanning after delay
                try? await store.central.wait(for: .poweredOn)
                if store.isScanning == false {
                    toggleScan()
                }
            }
        }
        .onDisappear {
            scanTask?.cancel()
            scanTask = nil
            if store.isScanning {
                store.stopScanning()
            }
        }
    }
}

private extension NearbyDevicesView {
    
    enum ScanState {
        case bluetoothUnavailable
        case scanning
        case stopScan
    }
    
    var items: [GoveeAdvertisement] {
        store.peripherals
            .lazy
            .sorted(by: { $0.key.description < $1.key.description })
            .map { $0.value }
    }
    
    var state: ScanState {
        if store.state != .poweredOn {
            return .bluetoothUnavailable
        } else if store.isScanning {
            return .scanning
        } else {
            return .stopScan
        }
    }
    
    var scanButton: some View {
        Button(action: {
            toggleScan()
        }, label: {
            switch state {
            case .bluetoothUnavailable:
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
            case .scanning:
                Image(systemName: "stop.fill")
                    .symbolRenderingMode(.monochrome)
            case .stopScan:
                Image(systemName: "arrow.clockwise")
                    .symbolRenderingMode(.monochrome)
            }
        })
    }
    
    var title: LocalizedStringKey {
        "Nearby"
    }
    
    var list: some View {
        List {
            ForEach(items) {
                GoveeAdvertisementRow(advertisement: $0)
            }
        }
    }
    
    func toggleScan() {
        if store.isScanning {
            store.stopScanning()
        } else {
            self.scanTask?.cancel()
            self.scanTask = Task {
                guard await store.central.state == .poweredOn,
                      store.isScanning == false else {
                    return
                }
                do {
                    try await store.scan()
                }
                catch { store.log("⚠️ Unable to scan. \(error.localizedDescription)") }
            }
        }
    }
}
