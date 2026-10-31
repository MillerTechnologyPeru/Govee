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
import Govee

@main
struct GoveeApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AccessoryManager.shared)
        }
    }
}
